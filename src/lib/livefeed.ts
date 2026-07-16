import type { Stop } from "./types";

/**
 * In-memory cache of real running snapshots, keyed by "number:runDate" — the
 * web port of ios/Railly/LiveFeed.swift. `sim.ts`'s `delaysForRun` reads
 * `alignedDelays` synchronously while building a run: when a fresh snapshot
 * exists the whole live picture derives from real data, otherwise it falls
 * back to the seeded simulation. There is no live-position feed wired on the
 * web yet (that needs an API key), so this stays empty and every run is a
 * schedule-projected estimate — but the plumbing matches the app exactly, so
 * dropping real delays in later flips the whole picture to live with no other
 * change.
 */

/** A real running snapshot, reduced to what the delay-walk needs. */
export interface LiveSnapshot {
  /** arrival delay in minutes, per station code */
  delayByCode: Record<string, number>;
}

class LiveFeed {
  /** A snapshot older than this (seconds) is ignored — the train has moved on. */
  private readonly ttl = 150;

  private cache = new Map<string, { snap: LiveSnapshot; at: number }>();

  private key(number: string, runDate: string): string {
    return `${number}:${runDate}`;
  }

  store(number: string, runDate: string, snap: LiveSnapshot): void {
    this.cache.set(this.key(number, runDate), { snap, at: Date.now() });
  }

  snapshot(number: string, runDate: string): LiveSnapshot | null {
    const e = this.cache.get(this.key(number, runDate));
    if (!e || (Date.now() - e.at) / 1000 >= this.ttl) return null;
    return e.snap;
  }

  /** True when a run currently has live data driving it (for a "LIVE" badge). */
  isLive(number: string, runDate: string): boolean {
    return this.snapshot(number, runDate) !== null;
  }

  /**
   * Arrival delay (minutes) per stop, aligned to `stops`, carrying the last
   * known delay forward across any stop the feed omitted. `null` when there's
   * no fresh snapshot — the caller then simulates.
   */
  alignedDelays(
    number: string,
    runDate: string,
    stops: Stop[],
  ): number[] | null {
    const snap = this.snapshot(number, runDate);
    if (!snap || stops.length < 2) return null;
    // require a real overlap with this route, else it's the wrong data
    const hits = stops.filter((s) => snap.delayByCode[s.code] !== undefined).length;
    if (hits < Math.max(2, Math.floor(stops.length / 3))) return null;
    const out: number[] = [];
    let carry = 0;
    for (const s of stops) {
      const d = snap.delayByCode[s.code];
      if (d !== undefined) carry = Math.max(0, d);
      out.push(carry);
    }
    return out;
  }
}

export const liveFeed = new LiveFeed();
