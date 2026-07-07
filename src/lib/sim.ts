import { bearingDeg, cumulativeKm, lerp } from "./geo";
import { hashSeed, pickFrom, pickInt, seededRng } from "./rng";
import { addDaysISO, istDateISO, istDateTime, istWeekday, parseHM } from "./time";
import { TRAINS } from "./trains";
import type {
  LiveStatus,
  StatusTone,
  StopTiming,
  Train,
  TrainCategory,
  TrainEvent,
} from "./types";

/**
 * The live network is a pure function of (train, runDate, now): delays are a
 * seeded random walk over the timetable, so every client renders the same
 * "live" positions with no backend — and they evolve minute by minute.
 */

/** minutes before scheduled departure that a run becomes the active one */
const BOARDING_MIN = 45;
/** minutes after estimated arrival a run keeps showing as active */
const LINGER_MIN = 25;
/** how many days back a run can still be in progress (longest journey ~38h) */
const MAX_LOOKBACK_DAYS = 3;

const DELAY_PROFILE: Record<
  TrainCategory,
  { down: number; up: number; incident: number; max: number }
> = {
  "vande-bharat": { down: 3, up: 5, incident: 0.15, max: 45 },
  shatabdi: { down: 3, up: 6, incident: 0.18, max: 60 },
  rajdhani: { down: 4, up: 8, incident: 0.24, max: 90 },
  duronto: { down: 4, up: 9, incident: 0.24, max: 90 },
  tejas: { down: 3, up: 7, incident: 0.18, max: 60 },
  superfast: { down: 4, up: 11, incident: 0.36, max: 150 },
  express: { down: 5, up: 14, incident: 0.45, max: 180 },
};

const TOP_SPEED_KMH: Record<TrainCategory, number> = {
  "vande-bharat": 160,
  shatabdi: 140,
  rajdhani: 130,
  duronto: 130,
  tejas: 130,
  superfast: 110,
  express: 100,
};

const DELAY_REASONS = [
  "Held at the outer signal",
  "Speed restriction over a maintenance block",
  "Awaiting a crossing on the single-line section",
  "Regulated for a late-running priority service",
  "Fog speed restriction in effect",
  "Extended halt for crew change",
  "Signal failure ahead cleared after inspection",
] as const;

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

/** Arrival delay (minutes) at every stop for a given run — deterministic. */
function delaysForRun(train: Train, runDate: string): number[] {
  const rng = seededRng(`${train.number}:${runDate}`);
  const profile = DELAY_PROFILE[train.category];
  const n = train.stops.length;

  // At most one "incident" (big jolt) per run, on a seeded segment.
  const incidentSeg = rng() < profile.incident ? pickInt(rng, 1, n - 1) : -1;

  const delays: number[] = [rng() < 0.18 ? pickInt(rng, 2, 12) : 0];
  for (let i = 1; i < n; i++) {
    const segMin = train.stops[i].arrMin - train.stops[i - 1].depMin;
    let d = delays[i - 1] + (rng() * (profile.up + profile.down) - profile.down);
    if (i === incidentSeg) d += pickInt(rng, 12, 35);
    // Can't arrive earlier than physics allows relative to the previous departure.
    d = clamp(d, Math.max(0, delays[i - 1] - Math.max(0, segMin - 3)), profile.max);
    delays.push(Math.round(d));
  }
  return delays;
}

interface Run {
  runDate: string;
  delays: number[];
  timings: StopTiming[];
  departs: Date; // scheduled origin departure
  departsEst: Date;
  arrivesSched: Date;
  arrivesEst: Date;
}

function buildRun(train: Train, runDate: string): Run {
  const depTimeMin = parseHM(train.departureTime);
  const delays = delaysForRun(train, runDate);
  const timings: StopTiming[] = train.stops.map((s, i) => {
    const arrSched = istDateTime(runDate, depTimeMin + s.arrMin);
    const depSched = istDateTime(runDate, depTimeMin + s.depMin);
    return {
      arrSched,
      arrEst: new Date(arrSched.getTime() + delays[i] * 60_000),
      depSched,
      depEst: new Date(depSched.getTime() + delays[i] * 60_000),
      delayMin: delays[i],
      passed: false,
      current: false,
    };
  });
  const last = timings[timings.length - 1];
  return {
    runDate,
    delays,
    timings,
    departs: timings[0].depSched,
    departsEst: timings[0].depEst,
    arrivesSched: last.arrSched,
    arrivesEst: last.arrEst,
  };
}

/** The run a viewer cares about right now: in progress if any, else the next scheduled one, else the last completed. */
function resolveRun(train: Train, now: Date): Run {
  const today = istDateISO(now);

  // A run still in progress (or lingering just after arrival)?
  for (let offset = 0; offset >= -MAX_LOOKBACK_DAYS; offset--) {
    const runDate = addDaysISO(today, offset);
    if (!train.days.includes(istWeekday(runDate))) continue;
    const run = buildRun(train, runDate);
    const from = run.departs.getTime() - BOARDING_MIN * 60_000;
    const to = run.arrivesEst.getTime() + LINGER_MIN * 60_000;
    if (now.getTime() >= from && now.getTime() <= to) return run;
  }

  // Next scheduled run within a week.
  for (let offset = 0; offset <= 7; offset++) {
    const runDate = addDaysISO(today, offset);
    if (!train.days.includes(istWeekday(runDate))) continue;
    const run = buildRun(train, runDate);
    if (run.departs.getTime() > now.getTime()) return run;
  }

  // Fallback: most recent completed run (every train runs ≥4 days/week, so this terminates).
  for (let offset = -1; offset >= -14; offset--) {
    const runDate = addDaysISO(today, offset);
    if (train.days.includes(istWeekday(runDate))) return buildRun(train, runDate);
  }
  return buildRun(train, today); // unreachable with sane data
}

function statusOf(
  phase: LiveStatus["phase"],
  delayMin: number,
  platform: string | undefined,
): { statusText: string; tone: StatusTone } {
  if (phase === "scheduled")
    return delayMin > 5
      ? { statusText: `Delayed +${delayMin}m`, tone: "sun" }
      : { statusText: "On Time", tone: "go" };
  if (phase === "boarding")
    return delayMin > 5
      ? { statusText: `Boarding · +${delayMin}m`, tone: "sun" }
      : { statusText: platform ? `Boarding · PF ${platform}` : "Boarding", tone: "signal" };
  if (phase === "arrived")
    return delayMin > 5
      ? { statusText: `Arrived +${delayMin}m`, tone: "steel" }
      : { statusText: "Arrived · On Time", tone: "go" };
  if (delayMin > 20) return { statusText: `Delayed +${delayMin}m`, tone: "crit" };
  if (delayMin > 5) return { statusText: `Delayed +${delayMin}m`, tone: "sun" };
  return { statusText: "On Time", tone: "go" };
}

function eventsForRun(train: Train, run: Run, now: Date): TrainEvent[] {
  const rng = seededRng(`${train.number}:${run.runDate}:events`);
  const events: TrainEvent[] = [];
  const stops = train.stops;
  const nowMs = now.getTime();

  if (run.departsEst.getTime() <= nowMs) {
    events.push({
      time: run.departsEst,
      kind: "departed",
      text: `Departed ${stops[0].name}`,
      detail: run.delays[0] > 0 ? `${run.delays[0]}m late` : "On time",
    });
  }

  // Seeded platform change at one upcoming-ish stop, announced ~40 min before arrival.
  const pfStop = rng() < 0.3 ? pickInt(rng, 1, stops.length - 1) : -1;
  if (pfStop > 0) {
    const announceAt = new Date(run.timings[pfStop].arrEst.getTime() - 40 * 60_000);
    if (announceAt.getTime() <= nowMs && announceAt.getTime() >= run.departs.getTime()) {
      const oldPf = stops[pfStop].platform ?? String(pickInt(rng, 1, 6));
      let newPf = String(pickInt(rng, 1, 8));
      if (newPf === oldPf) newPf = String(Number(oldPf) + 1);
      events.push({
        time: announceAt,
        kind: "platform",
        text: `Platform change at ${stops[pfStop].name}`,
        detail: `PF ${oldPf} → PF ${newPf}`,
      });
    }
  }

  for (let i = 1; i < stops.length; i++) {
    const t = run.timings[i];
    const jump = run.delays[i] - run.delays[i - 1];

    // Explain meaningful delay jumps mid-segment, the Flighty signature.
    if (jump >= 8) {
      const mid = new Date(
        (run.timings[i - 1].depEst.getTime() + t.arrEst.getTime()) / 2,
      );
      if (mid.getTime() <= nowMs)
        events.push({
          time: mid,
          kind: "delay",
          text: pickFrom(rng, DELAY_REASONS),
          detail: `+${jump}m near ${stops[i].name}`,
        });
    } else if (jump <= -8 && t.arrEst.getTime() <= nowMs) {
      events.push({
        time: t.arrEst,
        kind: "recovery",
        text: `Made up time approaching ${stops[i].name}`,
        detail: `${jump}m`,
      });
    }

    if (i < stops.length - 1 && t.depEst.getTime() <= nowMs) {
      events.push({
        time: t.depEst,
        kind: "stop",
        text: `Departed ${stops[i].name}`,
        detail: run.delays[i] > 5 ? `+${run.delays[i]}m` : "On time",
      });
    }
  }

  const last = run.timings[run.timings.length - 1];
  if (last.arrEst.getTime() <= nowMs) {
    const d = run.delays[run.delays.length - 1];
    events.push({
      time: last.arrEst,
      kind: "arrived",
      text: `Arrived ${stops[stops.length - 1].name}`,
      detail: d > 5 ? `${d}m late` : "On time",
    });
  }

  return events.sort((a, b) => b.time.getTime() - a.time.getTime()).slice(0, 14);
}

/** Full live picture for the run a viewer cares about right now. */
export function getLiveStatus(train: Train, now: Date): LiveStatus {
  return statusForRun(train, resolveRun(train, now), now);
}

/** Live picture for one specific dated run (trips reference these). */
export function getLiveStatusForRun(
  train: Train,
  runDate: string,
  now: Date,
): LiveStatus {
  return statusForRun(train, buildRun(train, runDate), now);
}

function statusForRun(train: Train, run: Run, now: Date): LiveStatus {
  const stops = train.stops;
  const n = stops.length;
  const nowMs = now.getTime();
  const cum = cumulativeKm(stops);
  const totalKm = cum[n - 1];

  let phase: LiveStatus["phase"];
  if (nowMs < run.departs.getTime() - BOARDING_MIN * 60_000) phase = "scheduled";
  else if (nowMs < run.departsEst.getTime()) phase = "boarding";
  else if (nowMs < run.arrivesEst.getTime()) phase = "enroute";
  else phase = "arrived";

  let prevStopIdx = 0;
  let nextStopIdx = Math.min(1, n - 1);
  let atStation = true;
  let frac = 0;
  let delayMin = run.delays[0];
  let speedKmh = 0;

  if (phase === "arrived") {
    prevStopIdx = n - 1;
    nextStopIdx = n - 1;
    delayMin = run.delays[n - 1];
  } else if (phase === "enroute") {
    for (let i = 0; i < n - 1; i++) {
      if (nowMs < run.timings[i + 1].arrEst.getTime()) {
        if (nowMs < run.timings[i].depEst.getTime()) {
          // standing at station i
          prevStopIdx = i;
          nextStopIdx = i + 1;
          atStation = true;
          delayMin = run.delays[i];
        } else {
          prevStopIdx = i;
          nextStopIdx = i + 1;
          atStation = false;
          const depMs = run.timings[i].depEst.getTime();
          const arrMs = run.timings[i + 1].arrEst.getTime();
          frac = clamp((nowMs - depMs) / Math.max(1, arrMs - depMs), 0, 1);
          delayMin = Math.round(lerp(run.delays[i], run.delays[i + 1], frac));

          const segKm = cum[i + 1] - cum[i];
          const segH = (arrMs - depMs) / 3_600_000;
          const base = segKm / Math.max(0.05, segH);
          // Gentle deterministic wobble so the speedo feels alive.
          const wobblePhase = hashSeed(train.number) % 360;
          const wobble = 1 + 0.12 * Math.sin(nowMs / 120_000 + wobblePhase);
          speedKmh = Math.round(
            clamp(base * wobble, 28, TOP_SPEED_KMH[train.category]),
          );
        }
        break;
      }
    }
  }

  const a = stops[prevStopIdx];
  const b = stops[nextStopIdx];
  const position = atStation || prevStopIdx === nextStopIdx
    ? { lat: a.lat, lng: a.lng }
    : { lat: lerp(a.lat, b.lat, frac), lng: lerp(a.lng, b.lng, frac) };
  const bearing =
    prevStopIdx === nextStopIdx
      ? 0
      : bearingDeg(a.lat, a.lng, b.lat, b.lng);

  const progressKm =
    phase === "arrived"
      ? totalKm
      : phase === "enroute"
        ? cum[prevStopIdx] + frac * (cum[nextStopIdx] - cum[prevStopIdx])
        : 0;

  const timings: StopTiming[] = run.timings.map((t) => ({
    ...t,
    passed: phase === "arrived" || (phase === "enroute" && t.depEst.getTime() <= nowMs),
    current: false,
  }));
  if (phase === "enroute" && atStation) timings[prevStopIdx].current = true;
  if (phase === "boarding") timings[0].current = true;

  const { statusText, tone } = statusOf(
    phase,
    delayMin,
    stops[0].platform,
  );

  return {
    train,
    runDate: run.runDate,
    phase,
    delayMin,
    statusText,
    tone,
    position,
    bearing,
    speedKmh,
    prevStopIdx,
    nextStopIdx,
    atStation,
    stopTimings: timings,
    progressKm,
    totalKm,
    progress: totalKm === 0 ? 0 : clamp(progressKm / totalKm, 0, 1),
    departsAt: run.departs,
    arrivesSched: run.arrivesSched,
    arrivesEst: run.arrivesEst,
    events:
      phase === "scheduled"
        ? []
        : eventsForRun(train, run, now),
  };
}

export function trainByNumber(num: string): Train | undefined {
  return TRAINS.find((t) => t.number === num);
}

/** Most recent run that has fully arrived — for past-trips lists. */
export function lastCompletedRunDate(train: Train, now: Date): string | null {
  const today = istDateISO(now);
  for (let offset = 0; offset >= -14; offset--) {
    const runDate = addDaysISO(today, offset);
    if (!train.days.includes(istWeekday(runDate))) continue;
    const run = buildRun(train, runDate);
    if (run.arrivesEst.getTime() < now.getTime()) return runDate;
  }
  return null;
}
