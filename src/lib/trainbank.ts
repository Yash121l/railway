import { useEffect, useState, useSyncExternalStore } from "react";
import seedTrainsJson from "../data/seed-trains.json" with { type: "json" };
import { prettyTrainName } from "./catalog";
import {
  getActiveStatuses,
  getLiveStatus,
  getLiveStatusForRun,
  getScheduledStatus,
  lastCompletedRunDate,
} from "./sim";
import type { Day, LiveStatus, Stop, Train, TrainCategory } from "./types";

/**
 * The web client's data layer, the browser port of ios/Railly/TrainBank.swift
 * and TripStore.swift.
 *
 * - `trainBank` resolves full schedules (route + platforms + times) three
 *   layers deep — bundled seeds → localStorage cache → the /api/rail/train
 *   proxy — with a TTL and stale-wins-on-failure, so a resolved train works
 *   offline forever and an outage shows a stale schedule instead of an error.
 * - `tripStore` persists the user's held trips to localStorage, mirroring
 *   TripStore's records + derivation.
 *
 * The live picture itself (position, ETA, delays) is projected from the real
 * schedule by sim.ts — a labelled estimate, not a live feed.
 */

// MARK: types

/** A resolved train, carrying the erail metadata the sim doesn't need but the UI shows. */
export interface BankTrain extends Train {
  /** erail's ALL-CAPS feed name ("NDLS TEJAS RAJ") */
  rawName: string;
  /** reserved classes, PRS order ("1A", "2A", "3A", "CC", …) */
  classes: string[];
}

/** The subset of the proxy's FullTrain / seed-trains.json we consume. */
interface FullTrainWire {
  number: string;
  name: string;
  displayName?: string;
  category: TrainCategory;
  departureTime: string;
  days: Day[];
  distanceKm: number;
  stops: Stop[];
  classes?: string[];
}

/** One held ticket: a specific train on a specific run date (TripStore.TripRecord). */
export interface TripRecord {
  number: string;
  /** "YYYY-MM-DD" IST */
  runDate: string;
  /** epoch ms the trip was added */
  addedAt: number;
  coach?: string;
  seat?: string;
  pnr?: string;
}

export interface HeldTrip {
  id: string;
  train: BankTrain;
  live: LiveStatus;
  booking?: { coach: string; seat: string; pnr: string };
}

export interface ClassifiedTrips {
  live: HeldTrip[];
  upcoming: HeldTrip[];
  past: HeldTrip[];
}

// MARK: id helpers

export function tripId(number: string, runDate: string): string {
  return `${number}_${runDate}`;
}

export function parseTripId(
  id: string,
): { number: string; runDate: string } | null {
  const m = /^(\d{4,6})_(\d{4}-\d{2}-\d{2})$/.exec(id);
  return m ? { number: m[1], runDate: m[2] } : null;
}

function toTrain(w: FullTrainWire): BankTrain {
  return {
    number: w.number,
    name: w.displayName ?? prettyTrainName(w.name),
    rawName: w.name,
    category: w.category,
    departureTime: w.departureTime,
    days: w.days,
    distanceKm: w.distanceKm,
    stops: w.stops,
    classes: w.classes ?? [],
  };
}

// MARK: TrainBank

const CACHE_PREFIX = "railly.train.";
/** Full schedules change rarely — mirror the proxy's 7-day cache. */
const TRAIN_TTL_MS = 7 * 24 * 60 * 60 * 1000;

interface StoredTrain {
  train: BankTrain;
  at: number;
}

class TrainBank {
  private mem = new Map<string, BankTrain>();
  /** epoch ms a cached train was fetched; absent for bundled seeds (offline floor). */
  private fetchedAt = new Map<string, number>();
  private inflight = new Map<string, Promise<BankTrain>>();
  private readonly seedNumbers: string[];

  constructor() {
    const seeds = (seedTrainsJson as FullTrainWire[]).map(toTrain);
    for (const t of seeds) this.mem.set(t.number, t);
    this.seedNumbers = seeds.map((t) => t.number);
  }

  /** The bundled popular-trains rail, in curated order. */
  seeds(): BankTrain[] {
    return this.seedNumbers.map((n) => this.mem.get(n)!).filter(Boolean);
  }

  /** Cached copy (memory or localStorage) with no network — the offline floor. */
  cached(number: string): BankTrain | undefined {
    const n = number.trim();
    const m = this.mem.get(n);
    if (m) return m;
    const s = this.readStore(n);
    if (s) {
      this.mem.set(n, s.train);
      this.fetchedAt.set(n, s.at);
      return s.train;
    }
    return undefined;
  }

  /**
   * Cached copy if present and fresh, else one deduplicated fetch. A stale
   * copy is returned immediately and refreshed in the background; on a failed
   * fetch a stale copy still beats an error.
   */
  async resolve(
    number: string,
    { forceRefresh = false }: { forceRefresh?: boolean } = {},
  ): Promise<BankTrain> {
    const n = number.trim();
    const existing = this.cached(n);
    const at = this.fetchedAt.get(n);
    // seeds have no fetchedAt but are real schedules — treat them as fresh.
    const fresh = existing !== undefined && (at === undefined || Date.now() - at < TRAIN_TTL_MS);

    if (!forceRefresh && existing && fresh) return existing;

    let task = this.inflight.get(n);
    if (!task) {
      task = this.fetchTrain(n)
        .then((train) => {
          this.mem.set(n, train);
          this.fetchedAt.set(n, Date.now());
          this.writeStore(n, train);
          return train;
        })
        .catch((err) => {
          // a stale schedule beats an error screen
          const stale = this.cached(n);
          if (stale) return stale;
          throw err;
        })
        .finally(() => {
          this.inflight.delete(n);
        });
      this.inflight.set(n, task);
    }

    // stale-while-revalidate: hand back what we have, let the refresh land later.
    if (existing && !forceRefresh) {
      void task.catch(() => {});
      return existing;
    }
    return task;
  }

  private async fetchTrain(n: string): Promise<BankTrain> {
    const res = await fetch(`/api/rail/train/${encodeURIComponent(n)}`);
    if (!res.ok) {
      let message = "Couldn't load this train's schedule.";
      try {
        const body = await res.json();
        if (body?.error) message = body.error;
      } catch {
        // keep the default message
      }
      throw new Error(message);
    }
    const body = (await res.json()) as { train: FullTrainWire };
    return toTrain(body.train);
  }

  private readStore(n: string): StoredTrain | null {
    if (typeof window === "undefined") return null;
    try {
      const raw = window.localStorage.getItem(CACHE_PREFIX + n);
      if (!raw) return null;
      const parsed = JSON.parse(raw) as StoredTrain;
      if (!parsed?.train?.stops || parsed.train.stops.length < 2) return null;
      return parsed;
    } catch {
      return null;
    }
  }

  private writeStore(n: string, train: BankTrain): void {
    if (typeof window === "undefined") return;
    try {
      window.localStorage.setItem(
        CACHE_PREFIX + n,
        JSON.stringify({ train, at: Date.now() } satisfies StoredTrain),
      );
    } catch {
      // quota / private-mode — the memory cache still works this session
    }
  }
}

export const trainBank = new TrainBank();

// MARK: derivation (TripStore.myTrips)

function bookingFor(rec: TripRecord): HeldTrip["booking"] {
  if (rec.coach && rec.seat && rec.pnr) {
    return { coach: rec.coach, seat: rec.seat, pnr: rec.pnr };
  }
  return undefined;
}

/** Wrap a resolved train's current run as a board row (Track / search preview). */
export function liveHeldTrip(train: BankTrain, now: Date): HeldTrip {
  const live = getLiveStatus(train, now);
  return { id: tripId(train.number, live.runDate), train, live };
}

/** Full picture for one dated run — the trip detail screen. */
export function heldTripForRun(
  train: BankTrain,
  runDate: string,
  now: Date,
  booking?: HeldTrip["booking"],
): HeldTrip {
  const live = getLiveStatusForRun(train, runDate, now);
  return { id: tripId(train.number, runDate), train, live, booking };
}

/** Classify every held record by the phase of its own run (TripStore.myTrips). */
export function classifyTrips(
  records: TripRecord[],
  trains: Record<string, BankTrain>,
  now: Date,
): ClassifiedTrips {
  const live: HeldTrip[] = [];
  const upcoming: HeldTrip[] = [];
  const past: HeldTrip[] = [];
  for (const rec of records) {
    const train = trains[rec.number];
    if (!train) continue;
    const status = getLiveStatusForRun(train, rec.runDate, now);
    const trip: HeldTrip = {
      id: tripId(rec.number, rec.runDate),
      train,
      live: status,
      booking: bookingFor(rec),
    };
    if (status.phase === "enroute" || status.phase === "boarding") live.push(trip);
    else if (status.phase === "scheduled") upcoming.push(trip);
    else past.push(trip);
  }
  live.sort((a, b) => {
    if (a.live.phase !== b.live.phase) return a.live.phase === "enroute" ? -1 : 1;
    return b.live.progress - a.live.progress;
  });
  upcoming.sort((a, b) => a.live.departsAt.getTime() - b.live.departsAt.getTime());
  past.sort((a, b) => b.live.arrivesEst.getTime() - a.live.arrivesEst.getTime());
  return { live, upcoming, past };
}

// MARK: TripStore

const TRIPS_KEY = "railly.trips";
const EMPTY: TripRecord[] = [];

function isTripRecord(v: unknown): v is TripRecord {
  if (typeof v !== "object" || v === null) return false;
  const r = v as Record<string, unknown>;
  return (
    typeof r.number === "string" &&
    /^\d{4,6}$/.test(r.number) &&
    typeof r.runDate === "string" &&
    /^\d{4}-\d{2}-\d{2}$/.test(r.runDate)
  );
}

class TripStore {
  private records: TripRecord[] = EMPTY;
  private listeners = new Set<() => void>();
  private hydrated = false;

  private hydrate(): void {
    if (this.hydrated || typeof window === "undefined") return;
    this.hydrated = true;
    try {
      const raw = window.localStorage.getItem(TRIPS_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) this.records = parsed.filter(isTripRecord);
      }
    } catch {
      this.records = EMPTY;
    }
  }

  subscribe = (cb: () => void): (() => void) => {
    this.hydrate();
    this.listeners.add(cb);
    return () => {
      this.listeners.delete(cb);
    };
  };

  getSnapshot = (): TripRecord[] => {
    this.hydrate();
    return this.records;
  };

  getServerSnapshot = (): TripRecord[] => EMPTY;

  private commit(next: TripRecord[]): void {
    this.records = next;
    if (typeof window !== "undefined") {
      try {
        window.localStorage.setItem(TRIPS_KEY, JSON.stringify(next));
      } catch {
        // ignore quota errors — the in-memory copy still drives this session
      }
    }
    for (const l of this.listeners) l();
  }

  isHeld(id: string): boolean {
    this.hydrate();
    return this.records.some((r) => tripId(r.number, r.runDate) === id);
  }

  record(id: string): TripRecord | undefined {
    this.hydrate();
    return this.records.find((r) => tripId(r.number, r.runDate) === id);
  }

  add(number: string, runDate: string, booking?: HeldTrip["booking"]): void {
    this.hydrate();
    const id = tripId(number, runDate);
    if (this.records.some((r) => tripId(r.number, r.runDate) === id)) return;
    this.commit([
      ...this.records,
      { number, runDate, addedAt: Date.now(), ...booking },
    ]);
  }

  remove(id: string): void {
    this.hydrate();
    this.commit(this.records.filter((r) => tripId(r.number, r.runDate) !== id));
  }

  /**
   * First-visit preview seed: whatever the popular trains are doing now, their
   * next departures, and recent completed runs — honest schedule projections,
   * persisted and fully removable. Runs once; an emptied list never reseeds.
   */
  seedIfEmpty(now: Date): void {
    if (typeof window === "undefined") return;
    if (window.localStorage.getItem(TRIPS_KEY) !== null) return;
    const seen = new Set<string>();
    const recs: TripRecord[] = [];
    const push = (number: string, runDate: string) => {
      const id = tripId(number, runDate);
      if (seen.has(id)) return;
      seen.add(id);
      recs.push({ number, runDate, addedAt: now.getTime() });
    };
    for (const train of trainBank.seeds()) {
      for (const s of getActiveStatuses(train, now)) {
        if (s.phase === "enroute" || s.phase === "boarding") push(train.number, s.runDate);
      }
      const next = getScheduledStatus(train, now);
      if (next) push(train.number, next.runDate);
      const last = lastCompletedRunDate(train, now);
      if (last) push(train.number, last);
    }
    this.commit(recs);
  }
}

export const tripStore = new TripStore();

// MARK: React hooks

/** The user's held trip records, reactive across every /app screen. */
export function useTrips(): TripRecord[] {
  return useSyncExternalStore(
    tripStore.subscribe,
    tripStore.getSnapshot,
    tripStore.getServerSnapshot,
  );
}

/**
 * Resolve full schedules for a set of train numbers, re-rendering as each
 * lands. Cached/seed trains appear synchronously (via the render-time
 * initializer); the rest stream in from the proxy through the async callback.
 */
export function useResolvedTrains(numbers: string[]): {
  trains: Record<string, BankTrain>;
} {
  const key = Array.from(new Set(numbers)).sort().join(",");

  // Seed synchronously during render (not in an effect) so held trains paint
  // on the first frame with no cascading re-render.
  const [trains, setTrains] = useState<Record<string, BankTrain>>(() => {
    const init: Record<string, BankTrain> = {};
    for (const n of numbers) {
      const c = trainBank.cached(n);
      if (c) init[n] = c;
    }
    return init;
  });

  useEffect(() => {
    let cancelled = false;
    const list = key ? key.split(",") : [];
    for (const n of list) {
      trainBank
        .resolve(n)
        .then((t) => {
          if (!cancelled) setTrains((prev) => (prev[n] === t ? prev : { ...prev, [n]: t }));
        })
        .catch(() => {
          // keep whatever seed/cache we already have; skip on hard failure
        });
    }
    return () => {
      cancelled = true;
    };
  }, [key]);

  return { trains };
}

/** Resolve a single train (the trip detail screen). */
export function useResolvedTrain(number: string | null): {
  train: BankTrain | null;
  loading: boolean;
  error: string | null;
} {
  // The entry carries the number it belongs to, so a stale entry from a
  // previous number reads as "loading" during render instead of needing a
  // synchronous reset inside the effect.
  const [entry, setEntry] = useState<{
    number: string | null;
    train: BankTrain | null;
    error: string | null;
  }>(() => ({
    number,
    train: number ? trainBank.cached(number) ?? null : null,
    error: null,
  }));

  useEffect(() => {
    let cancelled = false;
    if (!number) return;
    trainBank
      .resolve(number)
      .then((t) => {
        if (!cancelled) setEntry({ number, train: t, error: null });
      })
      .catch((e: unknown) => {
        if (!cancelled && !trainBank.cached(number)) {
          setEntry({
            number,
            train: null,
            error: e instanceof Error ? e.message : "Couldn't load this train.",
          });
        }
      });
    return () => {
      cancelled = true;
    };
  }, [number]);

  if (entry.number === number) {
    return {
      train: entry.train,
      loading: entry.train === null && entry.error === null && number !== null,
      error: entry.error,
    };
  }
  // number changed this render; fall back to any cached copy until the effect lands
  const cached = number ? trainBank.cached(number) ?? null : null;
  return { train: cached, loading: cached === null && number !== null, error: null };
}
