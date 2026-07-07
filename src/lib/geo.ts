import type { Stop } from "./types";

const EARTH_RADIUS_KM = 6371;

const toRad = (deg: number) => (deg * Math.PI) / 180;
const toDeg = (rad: number) => (rad * 180) / Math.PI;

export function haversineKm(
  aLat: number,
  aLng: number,
  bLat: number,
  bLng: number,
): number {
  const dLat = toRad(bLat - aLat);
  const dLng = toRad(bLng - aLng);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(h));
}

/** Initial bearing from A to B, degrees clockwise from north */
export function bearingDeg(
  aLat: number,
  aLng: number,
  bLat: number,
  bLng: number,
): number {
  const φ1 = toRad(aLat);
  const φ2 = toRad(bLat);
  const Δλ = toRad(bLng - aLng);
  const y = Math.sin(Δλ) * Math.cos(φ2);
  const x =
    Math.cos(φ1) * Math.sin(φ2) - Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ);
  return (toDeg(Math.atan2(y, x)) + 360) % 360;
}

export function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

/** Cumulative km along the stop polyline; [0] = 0, [n-1] = total */
export function cumulativeKm(stops: Stop[]): number[] {
  const out = [0];
  for (let i = 1; i < stops.length; i++) {
    out.push(
      out[i - 1] +
        haversineKm(stops[i - 1].lat, stops[i - 1].lng, stops[i].lat, stops[i].lng),
    );
  }
  return out;
}
