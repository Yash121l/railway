import segments from "../../../src/data/rail-segments.json";
import seedTrains from "../../../src/data/seed-trains.json";

type LatLng = [number, number];
const SEGMENTS = segments as unknown as Record<string, LatLng[]>;

const LAT0 = 22;
const K = Math.cos((LAT0 * Math.PI) / 180);
// equirectangular with the x axis shrunk to India's mid latitude; 1 unit = 1 degree of latitude
const project = ([lat, lng]: LatLng): [number, number] => [(lng - 78) * K, -(lat - LAT0)];

const DELHI = project([28.6425, 77.2207]);

const dist = (a: [number, number], b: [number, number]) => Math.hypot(a[0] - b[0], a[1] - b[1]);

const lengthOf = (pts: [number, number][]) => pts.slice(1).reduce((s, p, i) => s + dist(p, pts[i]), 0);

export type Corridor = { key: string; pts: [number, number][]; len: number; fromDelhi: number };

export const corridors: Corridor[] = Object.entries(SEGMENTS).map(([key, raw]) => {
  let pts = raw.map(project);
  // draw every corridor outward from Delhi so the network grows from the capital
  if (dist(pts[pts.length - 1], DELHI) < dist(pts[0], DELHI)) pts = pts.reverse();
  return { key, pts, len: lengthOf(pts), fromDelhi: dist(pts[0], DELHI) };
});

const allPts = corridors.flatMap((c) => c.pts);
export const bounds = {
  minX: Math.min(...allPts.map((p) => p[0])),
  maxX: Math.max(...allPts.map((p) => p[0])),
  minY: Math.min(...allPts.map((p) => p[1])),
  maxY: Math.max(...allPts.map((p) => p[1])),
};

type Stop = { code: string; name: string; lat: number; lng: number };
const stopByCode = new Map<string, Stop>();
for (const t of seedTrains as { stops: Stop[] }[]) for (const s of t.stops) if (s.lat) stopByCode.set(s.code, s);

export const CITIES: { code: string; label: string; anchor: "l" | "r" }[] = [
  { code: "NDLS", label: "New Delhi", anchor: "r" },
  { code: "MMCT", label: "Mumbai", anchor: "l" },
  { code: "HWH", label: "Kolkata", anchor: "r" },
  { code: "MAS", label: "Chennai", anchor: "r" },
  { code: "SBC", label: "Bengaluru", anchor: "l" },
  { code: "ADI", label: "Ahmedabad", anchor: "l" },
  { code: "BPL", label: "Bhopal", anchor: "l" },
  { code: "NGP", label: "Nagpur", anchor: "r" },
  { code: "BKN", label: "Bikaner", anchor: "l" },
  { code: "BSB", label: "Varanasi", anchor: "r" },
  { code: "VSKP", label: "Visakhapatnam", anchor: "r" },
];

export const cities = CITIES.flatMap((c) => {
  const s = stopByCode.get(c.code);
  return s ? [{ ...c, p: project([s.lat, s.lng]) }] : [];
});

const RAJDHANI = ["MMCT", "BVI", "ST", "BRC", "RTM", "NAD", "KOTA", "NDLS"];
export const route: [number, number][] = RAJDHANI.slice(1).flatMap((to, i) => {
  const key = `${RAJDHANI[i]}>${to}`;
  const raw = SEGMENTS[key];
  if (!raw) throw new Error(`missing corridor ${key}`);
  const pts = raw.map(project);
  return i === 0 ? pts : pts.slice(1);
});

const cum = route.reduce<number[]>((acc, p, i) => {
  acc.push(i === 0 ? 0 : acc[i - 1] + dist(p, route[i - 1]));
  return acc;
}, []);
export const routeLen = cum[cum.length - 1];

export const pointAt = (t: number): { p: [number, number]; angle: number } => {
  const target = Math.max(0, Math.min(1, t)) * routeLen;
  let i = cum.findIndex((c) => c >= target);
  if (i <= 0) i = 1;
  const seg = cum[i] - cum[i - 1] || 1;
  const f = (target - cum[i - 1]) / seg;
  const a = route[i - 1];
  const b = route[i];
  return { p: [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f], angle: Math.atan2(b[1] - a[1], b[0] - a[0]) };
};

export const pathD = (pts: [number, number][]) => pts.map((p, i) => `${i ? "L" : "M"}${p[0].toFixed(4)} ${p[1].toFixed(4)}`).join("");

export const slicePath = (t0: number, t1: number) => {
  const a = t0 * routeLen;
  const b = t1 * routeLen;
  const pts: [number, number][] = [pointAt(t0).p];
  route.forEach((p, i) => {
    if (cum[i] > a && cum[i] < b) pts.push(p);
  });
  pts.push(pointAt(t1).p);
  return pathD(pts);
};
