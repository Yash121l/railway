import type { Stop } from "./types";
import segmentData from "../data/rail-segments.json" with { type: "json" };

/**
 * Real rail-track geometry between halts, bundled from OpenStreetMap by
 * `tools/railshapes/build_segments.py`. The web port of
 * `ios/Railly/RailGeometry.swift` — same library, same fallback order.
 *
 * erail only publishes a train's *halts*, so a straight chord between two
 * far-apart ones cuts across whatever lies between: the Vijayawada→Chennai
 * leg famously drew itself across the Bay of Bengal. Splicing the actual
 * track shape in between keeps the line on the rails.
 *
 * `rail-segments.json` maps a "FROM>TO" station-code pair to an ordered list
 * of `[lat, lng]` points, stored one direction only; the reverse is flipped
 * in. Legs with no bundled segment fall back to a straight chord, so this
 * works with a partial library or none at all — it just draws less honestly,
 * which is why `railDrawCoords` reports exactly which legs were approximated.
 */

/**
 * A "FROM>TO" key mapped to ordered `[lat, lng]` points. JSON gives us
 * `number[][]` rather than tuples, so points are read positionally below.
 */
type SegmentTable = Record<string, number[][]>;

const OSM_SEGMENTS: SegmentTable = segmentData;

/**
 * Real intermediate halts for the few corridors where OSM routing is
 * unreliable (the coastal bbox is huge and Overpass times out), so the
 * visible water-crossings stay on land regardless. OSM segments win; this is
 * only consulted when the library lacks the leg.
 */
const CURATED: SegmentTable = {
  // Vijayawada → Chennai down the Bay of Bengal coast, via Ongole, Kavali,
  // Nellore, Gudur and Sullurupeta — all real halts on the line.
  "BZA>MAS": [
    [16.5187, 80.6193],
    [15.506, 80.049],
    [14.913, 79.994],
    [14.443, 79.986],
    [14.151, 79.853],
    [13.705, 80.024],
    [13.0825, 80.2754],
  ],
};

/** GeoJSON winding: `[lng, lat]`, the opposite of the stored order. */
export type LngLat = [number, number];

/** Stored `[lat, lng]` rows flipped into GeoJSON's `[lng, lat]`, bad rows dropped. */
function toLngLat(points: number[][]): LngLat[] {
  const out: LngLat[] = [];
  for (const p of points) {
    if (p.length >= 2 && Number.isFinite(p[0]) && Number.isFinite(p[1])) {
      out.push([p[1], p[0]]);
    }
  }
  return out;
}

/** The bundled track between two halts, forward or reversed, as `[lng, lat]`. */
function bundledLeg(from: string, to: string): LngLat[] | null {
  for (const table of [OSM_SEGMENTS, CURATED]) {
    const forward = table[`${from}>${to}`];
    if (forward) {
      const leg = toLngLat(forward);
      if (leg.length >= 2) return leg;
    }
    const reverse = table[`${to}>${from}`];
    if (reverse) {
      const leg = toLngLat(reverse).reverse();
      if (leg.length >= 2) return leg;
    }
  }
  return null;
}

export interface RouteGeometry {
  /** The full drawn polyline, `[lng, lat]`, ready for a GeoJSON LineString. */
  coords: LngLat[];
  /** Legs drawn along real OSM (or curated) track shape. */
  tracedLegs: number;
  /** Legs drawn as a straight chord because no track shape is bundled. */
  approximatedLegs: number;
  /** Total legs — one fewer than the halt count. */
  totalLegs: number;
}

/**
 * Polyline for a run: each leg along the real track where we have it, else a
 * straight chord. Consecutive legs share their junction point (dropped once)
 * so the line stays continuous.
 */
export function railDrawCoords(stops: Stop[]): RouteGeometry {
  if (stops.length < 2) {
    return {
      coords: stops.map((s): LngLat => [s.lng, s.lat]),
      tracedLegs: 0,
      approximatedLegs: 0,
      totalLegs: 0,
    };
  }

  const coords: LngLat[] = [];
  let tracedLegs = 0;
  let approximatedLegs = 0;

  for (let i = 1; i < stops.length; i++) {
    const a = stops[i - 1];
    const b = stops[i];
    const traced = bundledLeg(a.code, b.code);
    if (traced) {
      tracedLegs++;
    } else {
      approximatedLegs++;
    }
    const leg: LngLat[] = traced ?? [
      [a.lng, a.lat],
      [b.lng, b.lat],
    ];
    // The junction point is already the previous leg's last coordinate.
    for (const point of coords.length === 0 ? leg : leg.slice(1)) {
      coords.push(point);
    }
  }

  return { coords, tracedLegs, approximatedLegs, totalLegs: stops.length - 1 };
}

/** Bounding box of a polyline as `[west, south, east, north]`. */
export function boundsOf(coords: LngLat[]): [number, number, number, number] | null {
  if (coords.length === 0) return null;
  let west = coords[0][0];
  let east = coords[0][0];
  let south = coords[0][1];
  let north = coords[0][1];
  for (const [lng, lat] of coords) {
    if (lng < west) west = lng;
    if (lng > east) east = lng;
    if (lat < south) south = lat;
    if (lat > north) north = lat;
  }
  return [west, south, east, north];
}
