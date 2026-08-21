import { categoryFor, prettyTrainName } from "@/lib/catalog";
import { cumulativeKm } from "@/lib/geo";
import type { Day, Stop, TrainCategory } from "@/lib/types";

/**
 * Server-only client for erail.in — the same unofficial Indian Railways feed
 * the erail website itself runs on. Ported from ios/Railly/RailAPI.swift. Two
 * endpoints: `getTrains.aspx` (train lookup and trains-between-stations;
 * `~`-delimited fields, `^`-delimited rows) and `data.aspx?Action=TRAINROUTE`
 * (full route with real times, platforms and coordinates). Field indices mirror
 * the constants in erail's own JS.
 */

export type RailErrorKind = "throttled" | "badResponse" | "notFound";

export class RailError extends Error {
  readonly kind: RailErrorKind;
  constructor(kind: RailErrorKind, message?: string) {
    super(message ?? defaultMessage(kind));
    this.kind = kind;
    this.name = "RailError";
  }
}

function defaultMessage(kind: RailErrorKind): string {
  switch (kind) {
    case "throttled":
      return "The railway data service is busy. Try again in a minute.";
    case "notFound":
      return "No schedule found.";
    default:
      return "Couldn't read the railway data feed.";
  }
}

/** One row of a getTrains.aspx response. */
export interface TrainSummary {
  number: string;
  /** raw feed name, ALL-CAPS and clipped ("NDLS TEJAS RAJ") */
  name: string;
  /** expanded, title-cased name for display */
  displayName: string;
  category: TrainCategory;
  originCode: string;
  originName: string;
  destCode: string;
  destName: string;
  fromCode: string;
  fromName: string;
  toCode: string;
  toName: string;
  /** "HH:MM" at the from-station / to-station, IST */
  departure: string;
  arrival: string;
  /** "HH:MM" total for the queried leg */
  travelTime: string;
  days: Day[];
  trainId: number;
  typeName: string;
  distanceKm: number;
  classes: string[];
}

/** A full train: lookup metadata composed with its real route. */
export interface FullTrain {
  number: string;
  name: string;
  displayName: string;
  category: TrainCategory;
  typeName: string;
  classes: string[];
  /** origin departure "HH:MM", IST */
  departureTime: string;
  days: Day[];
  distanceKm: number;
  /** erail's internal id, needed for the TRAINROUTE call */
  trainId: number;
  stops: Stop[];
}

export interface FetchOpts {
  /** cache lifetime in seconds; omit for a live (uncached) fetch */
  revalidate?: number;
  tags?: string[];
}

// getTrains.aspx row fields (T_* in erail's JS)
const T = {
  no: 0,
  name: 1,
  stnFirstName: 2,
  stnFirst: 3,
  stnLastName: 4,
  stnLast: 5,
  stnFromName: 6,
  stnFrom: 7,
  stnToName: 8,
  stnTo: 9,
  departure: 10,
  arrival: 11,
  travel: 12,
  runDays: 13,
  classes: 21,
  trainType: 32,
  trainId: 33,
  distance: 39,
} as const;

// TRAINROUTE row fields (TR_* in erail's JS)
const TR = {
  code: 1,
  name: 2,
  /** cumulative track km from the origin */
  distance: 6,
  platform: 8,
  lat: 14,
  lng: 15,
  arrMin: 16,
  depMin: 17,
} as const;

/** erail's class bitmask order, from its language file */
const CLASS_ORDER = [
  "1A", "2A", "3A", "CC", "FC", "SL", "2S",
  "3E", "GN", "EA", "EC", "EV", "VC", "VS",
];

/** run-day bits are Monday-first in the feed */
const MON_FIRST: Day[] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

/** schema canary: IR station codes are 2–5 uppercase letters */
const CODE_RE = /^[A-Z]{2,5}$/;

const UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15";

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** A trimmed string parsed strictly as an integer, or null. */
function strictInt(raw: string): number | null {
  const s = raw.trim();
  if (s === "" || !/^-?\d+$/.test(s)) return null;
  return Number(s);
}

/** Minutes-of-day for an "HH:MM" string, validated to 0…1439, else null. */
function hmToMinutes(hm: string): number | null {
  const parts = hm.split(":");
  if (parts.length !== 2) return null;
  const h = Number(parts[0]);
  const m = Number(parts[1]);
  if (!Number.isInteger(h) || !Number.isInteger(m)) return null;
  const mins = h * 60 + m;
  return mins >= 0 && mins <= 1439 ? mins : null;
}

/**
 * GET with a retry-and-jitter backoff, an erail-style User-Agent, a hard
 * timeout, and throttle-detection. Cached in the data cache when `revalidate`
 * is set; a live (uncached) fetch otherwise.
 */
async function fetchText(url: string, opts: FetchOpts = {}): Promise<string> {
  const init: RequestInit =
    opts.revalidate === undefined
      ? { cache: "no-store" }
      : { next: { revalidate: opts.revalidate, tags: opts.tags } };

  let lastErr: unknown;
  for (let attempt = 0; attempt < 3; attempt++) {
    if (attempt > 0) {
      const backoff = 250 * 2 ** (attempt - 1);
      await sleep(backoff + Math.random() * backoff);
    }
    try {
      const res = await fetch(url, {
        ...init,
        headers: { "User-Agent": UA },
        signal: AbortSignal.timeout(15_000),
      });
      if (!res.ok) {
        lastErr = new RailError("badResponse");
        continue;
      }
      const text = await res.text();
      if (text.includes("Please try again")) {
        lastErr = new RailError("throttled");
        continue;
      }
      return text;
    } catch (e) {
      lastErr = e;
    }
  }
  throw lastErr instanceof RailError ? lastErr : new RailError("badResponse");
}

function parseSummary(fields: string[]): TrainSummary | null {
  if (fields.length <= T.distance) return null;
  const number = fields[T.no];
  if (!number || !/^\d+$/.test(number)) return null;

  const originCode = fields[T.stnFirst];
  const destCode = fields[T.stnLast];
  // schema canary: origin/destination look like IR station codes
  if (!CODE_RE.test(originCode) || !CODE_RE.test(destCode)) return null;

  const departure = fields[T.departure].replace(/\./g, ":");
  const arrival = fields[T.arrival].replace(/\./g, ":");
  // schema canary: the departure field is a valid minute-of-day
  if (hmToMinutes(departure) === null) return null;

  const dayBits = fields[T.runDays];
  const days = MON_FIRST.filter((_, i) => dayBits[i] === "1");

  const classBits = fields[T.classes];
  const classes = CLASS_ORDER.filter((_, i) => classBits[i] === "1");

  const rawName = fields[T.name];
  return {
    number,
    name: rawName,
    displayName: prettyTrainName(rawName),
    category: categoryFor(rawName, fields[T.trainType]),
    originCode,
    originName: fields[T.stnFirstName],
    destCode,
    destName: fields[T.stnLastName],
    fromCode: fields[T.stnFrom],
    fromName: fields[T.stnFromName],
    toCode: fields[T.stnTo],
    toName: fields[T.stnToName],
    departure,
    arrival,
    travelTime: fields[T.travel].replace(/\./g, ":"),
    days,
    trainId: strictInt(fields[T.trainId]) ?? 0,
    typeName: fields[T.trainType],
    distanceKm: Number(fields[T.distance]) || 0,
    classes,
  };
}

function summaries(response: string): TrainSummary[] {
  return response
    .split("^")
    .map((row) => parseSummary(row.split("~")))
    .filter((s): s is TrainSummary => s !== null);
}

/** Exact-number lookup: full metadata incl. the internal route id. */
export async function trainInfo(
  num: string,
  opts: FetchOpts = {},
): Promise<TrainSummary> {
  const text = await fetchText(
    `https://erail.in/rail/getTrains.aspx?TrainNo=${encodeURIComponent(num)}&DataSource=0&Language=0&Cache=true`,
    opts,
  );
  const found = summaries(text).find((s) => s.number === num);
  if (!found) throw new RailError("notFound", `No schedule found for train ${num}.`);
  return found;
}

/** Every train running between two station codes. */
export async function trainsBetween(
  from: string,
  to: string,
  opts: FetchOpts = {},
): Promise<TrainSummary[]> {
  const text = await fetchText(
    `https://erail.in/rail/getTrains.aspx?Station_From=${encodeURIComponent(from)}&Station_To=${encodeURIComponent(to)}&DataSource=0&Language=0&Cache=true`,
    opts,
  );
  const rows = summaries(text);
  if (rows.length === 0) {
    throw new RailError("notFound", `No trains found between ${from} and ${to}.`);
  }
  return rows;
}

/**
 * Full route: real halt times (as minute offsets from origin departure),
 * platforms, and station coordinates.
 */
export async function route(
  trainId: number,
  opts: FetchOpts = {},
): Promise<Stop[]> {
  const text = await fetchText(
    `https://erail.in/data.aspx?Action=TRAINROUTE&Password=2012&Data1=${trainId}&Data2=0&Cache=true`,
    opts,
  );
  const stops: Stop[] = [];
  for (const row of text.split("^")) {
    const f = row.split("~");
    if (f.length <= TR.depMin) continue;
    const latRaw = f[TR.lat].trim();
    const lngRaw = f[TR.lng].trim();
    const lat = latRaw === "" ? NaN : Number(latRaw);
    const lng = lngRaw === "" ? NaN : Number(lngRaw);
    const arrMin = strictInt(f[TR.arrMin]);
    if (!Number.isFinite(lat) || !Number.isFinite(lng) || arrMin === null) continue;
    const code = f[TR.code].trim();
    // schema canary: station codes look like IR codes
    if (!CODE_RE.test(code)) continue;
    const pf = f[TR.platform].trim();
    const km = strictInt(f[TR.distance]);
    stops.push({
      name: f[TR.name].trim(),
      code,
      lat,
      lng,
      arrMin,
      depMin: strictInt(f[TR.depMin]) ?? arrMin,
      platform: pf === "" || pf === "0" ? undefined : pf,
      distanceKm: km !== null && km >= 0 ? km : undefined,
    });
  }
  if (stops.length < 2) throw new RailError("badResponse");
  // schema canary: minute offsets from origin are monotonically non-decreasing
  for (let i = 1; i < stops.length; i++) {
    if (stops[i].arrMin < stops[i - 1].arrMin) throw new RailError("badResponse");
  }
  return stops;
}

/** Lookup + route composed into the full-train shape. */
export async function fullTrain(
  num: string,
  opts: FetchOpts = {},
): Promise<FullTrain> {
  const info = await trainInfo(num, opts);
  const stops = await route(info.trainId, opts);
  // Prefer real track km: the lookup's own total, else the last halt's
  // cumulative reading, and only then straight-chord distance.
  const cum = cumulativeKm(stops);
  const lastKm = stops[stops.length - 1]?.distanceKm ?? 0;
  return {
    number: info.number,
    name: info.name,
    displayName: info.displayName,
    category: info.category,
    typeName: info.typeName,
    classes: info.classes,
    departureTime: info.departure,
    days: info.days,
    distanceKm:
      info.distanceKm > 0 ? info.distanceKm : lastKm > 0 ? lastKm : (cum[cum.length - 1] ?? 0),
    trainId: info.trainId,
    stops,
  };
}
