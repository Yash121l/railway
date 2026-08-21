import { CATEGORY_LABEL } from "./format";
import { cumulativeKm } from "./geo";
import { boundsOf, railDrawCoords, type LngLat, type RouteGeometry } from "./railshapes";
import type { FullTrain } from "./rail/erail";
import { parseHM } from "./time";
import type { Day, TrainCategory } from "./types";

/**
 * The serializable view model behind /raillens — everything the client map
 * needs, computed once on the server so the browser never parses a schedule
 * feed or the station catalog.
 */

export interface LensStop {
  code: string;
  name: string;
  lat: number;
  lng: number;
  /** "HH:MM" IST arrival at this halt */
  arrival: string;
  /** "HH:MM" IST departure from this halt */
  departure: string;
  /** 1-based day of the run this halt falls on */
  day: number;
  /** scheduled halt length in minutes */
  haltMin: number;
  /** cumulative kilometres from the origin */
  km: number;
  platform?: string;
  isOrigin: boolean;
  isDestination: boolean;
}

export interface LensRoute {
  number: string;
  /** display name, expanded from the feed's clipped ALL-CAPS ("SUR LTT SPECIAL") */
  name: string;
  category: TrainCategory;
  categoryLabel: string;
  classes: string[];
  days: Day[];
  runsDaily: boolean;
  stops: LensStop[];
  origin: LensStop;
  destination: LensStop;
  distanceKm: number;
  /** origin departure → destination arrival, in minutes */
  durationMin: number;
  /**
   * False when the feed omitted per-halt distances and the kilometre column
   * is straight-chord maths instead of real track distance.
   */
  kmIsExact: boolean;
  geometry: RouteGeometry;
  bounds: [number, number, number, number] | null;
}

const MINUTES_PER_DAY = 1440;

/** "HH:MM" for a minute-of-day, wrapping past midnight. */
function clock(minuteOfDay: number): string {
  const m = ((minuteOfDay % MINUTES_PER_DAY) + MINUTES_PER_DAY) % MINUTES_PER_DAY;
  const h = Math.floor(m / 60);
  return `${String(h).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}

export function buildLensRoute(train: FullTrain): LensRoute {
  const startMin = parseHM(train.departureTime);
  const chordKm = cumulativeKm(train.stops);
  const kmIsExact = train.stops.every((s) => s.distanceKm !== undefined);
  const last = train.stops.length - 1;

  const stops: LensStop[] = train.stops.map((s, i) => ({
    code: s.code,
    name: s.name,
    lat: s.lat,
    lng: s.lng,
    arrival: clock(startMin + s.arrMin),
    departure: clock(startMin + s.depMin),
    day: Math.floor((startMin + s.arrMin) / MINUTES_PER_DAY) + 1,
    haltMin: Math.max(0, s.depMin - s.arrMin),
    km: s.distanceKm ?? Math.round(chordKm[i] ?? 0),
    platform: s.platform,
    isOrigin: i === 0,
    isDestination: i === last,
  }));

  const geometry = railDrawCoords(train.stops);

  return {
    number: train.number,
    name: train.displayName,
    category: train.category,
    categoryLabel: CATEGORY_LABEL[train.category],
    classes: train.classes,
    days: train.days,
    runsDaily: train.days.length === 7,
    stops,
    origin: stops[0],
    destination: stops[last],
    distanceKm: Math.round(train.distanceKm),
    durationMin: train.stops[last].arrMin,
    kmIsExact,
    geometry,
    bounds: boundsOf(geometry.coords),
  };
}

/** A GeoJSON LineString feature for the drawn route. */
export function routeLineFeature(coords: LngLat[]) {
  return {
    type: "Feature" as const,
    properties: {},
    geometry: { type: "LineString" as const, coordinates: coords },
  };
}

/** A GeoJSON point per halt, carrying what the map labels need. */
export function haltPointFeatures(stops: LensStop[]) {
  return stops.map((s, i) => ({
    type: "Feature" as const,
    id: i,
    properties: {
      code: s.code,
      name: s.name,
      label: s.name.toUpperCase(),
      km: s.km,
      arrival: s.arrival,
      departure: s.departure,
      /** origin and destination get the bigger marker and always-on label */
      terminus: s.isOrigin || s.isDestination ? 1 : 0,
      index: i,
    },
    geometry: { type: "Point" as const, coordinates: [s.lng, s.lat] as LngLat },
  }));
}
