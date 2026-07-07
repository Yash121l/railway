import { getLiveStatus, getLiveStatusForRun, lastCompletedRunDate } from "./sim";
import { pickFrom, pickInt, seededRng } from "./rng";
import { TRAINS } from "./trains";
import type { LiveStatus, Train, Trip } from "./types";

/**
 * The demo persona's tickets are derived from whatever the simulated network
 * is doing right now: any train currently running is a trip they're on (or
 * tracking for family), the next few departures are upcoming, and recent
 * completed runs are their history. So the home screen is always alive.
 */

export interface HeldTrip extends Trip {
  train: Train;
  live: LiveStatus;
}

export function tripId(trainNumber: string, runDate: string): string {
  return `${trainNumber}_${runDate}`;
}

export function parseTripId(
  id: string,
): { trainNumber: string; runDate: string } | null {
  const m = /^(\d{5})_(\d{4}-\d{2}-\d{2})$/.exec(id);
  return m ? { trainNumber: m[1], runDate: m[2] } : null;
}

const COACHES = ["A1", "B2", "B4", "C3", "C7", "E1"] as const;
const BERTHS = ["LB", "UB", "SL", "SU", "WS", "MB"] as const;

/** Seeded booking details so a trip always shows the same seat and PNR. */
export function bookingFor(id: string): { coach: string; seat: string; pnr: string } {
  const rng = seededRng(`booking:${id}`);
  const chairCar = id.startsWith("2") || id.startsWith("120"); // VB / Shatabdi rakes
  return {
    coach: chairCar ? `C${pickInt(rng, 1, 8)}` : pickFrom(rng, COACHES),
    seat: chairCar
      ? `${pickInt(rng, 1, 78)}${pickFrom(rng, ["A", "B", "C", "D", "E"] as const)}`
      : `${pickInt(rng, 1, 72)} ${pickFrom(rng, BERTHS)}`,
    pnr: String(2000000000 + Math.floor(rng() * 899999999) * 10 + pickInt(rng, 0, 9)),
  };
}

function toHeldTrip(train: Train, live: LiveStatus): HeldTrip {
  const id = tripId(train.number, live.runDate);
  return { id, trainNumber: train.number, runDate: live.runDate, train, live, ...bookingFor(id) };
}

export interface MyTrips {
  live: HeldTrip[];
  upcoming: HeldTrip[];
  past: HeldTrip[];
}

export function getMyTrips(now: Date): MyTrips {
  const statuses = TRAINS.map((t) => ({ train: t, live: getLiveStatus(t, now) }));

  const live = statuses
    .filter((s) => s.live.phase === "enroute" || s.live.phase === "boarding")
    .sort((a, b) => {
      if (a.live.phase !== b.live.phase) return a.live.phase === "enroute" ? -1 : 1;
      return b.live.progress - a.live.progress;
    })
    .slice(0, 3)
    .map((s) => toHeldTrip(s.train, s.live));

  const liveNumbers = new Set(live.map((t) => t.trainNumber));

  const upcoming = statuses
    .filter((s) => !liveNumbers.has(s.train.number) && s.live.phase === "scheduled")
    .sort((a, b) => a.live.departsAt.getTime() - b.live.departsAt.getTime())
    .slice(0, 3)
    .map((s) => toHeldTrip(s.train, s.live));

  const past = TRAINS.map((train) => {
    const runDate = lastCompletedRunDate(train, now);
    if (!runDate) return null;
    const status = getLiveStatusForRun(train, runDate, now);
    return status.phase === "arrived" ? toHeldTrip(train, status) : null;
  })
    .filter((t): t is HeldTrip => t !== null)
    .sort((a, b) => b.live.arrivesEst.getTime() - a.live.arrivesEst.getTime())
    .slice(0, 4);

  return { live, upcoming, past };
}

/** Resolve one trip by id — used by the trip detail screen. */
export function getTrip(id: string, now: Date): HeldTrip | null {
  const parsed = parseTripId(id);
  if (!parsed) return null;
  const train = TRAINS.find((t) => t.number === parsed.trainNumber);
  if (!train) return null;
  return toHeldTrip(train, getLiveStatusForRun(train, parsed.runDate, now));
}
