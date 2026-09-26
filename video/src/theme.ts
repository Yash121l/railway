import { Easing, interpolate, useVideoConfig } from "remotion";
import timeline from "./timeline.json";

export const FPS = timeline.fps;
export const BEAT = (FPS * 60) / timeline.bpm;
export const TOTAL_FRAMES = timeline.totalBeats * BEAT;
export const beats = (n: number) => Math.round(n * BEAT);

export const scene = (id: string) => {
  const s = timeline.scenes.find((x) => x.id === id);
  if (!s) throw new Error(`no scene ${id}`);
  return { from: beats(s.from), duration: beats(s.beats) };
};

export const C = {
  ink: "#05010d",
  midnight: "#0d0021",
  panel: "#12142e",
  raise: "#1b1e40",
  signal: "#007bff",
  arc: "#4d9fff",
  sun: "#f7be00",
  go: "#30d158",
  ontime: "#1e9e4a",
  late: "#d93025",
  linen: "#faf8f7",
  carbon: "#333333",
  steel: "#737373",
  white: "#ffffff",
};

export const SANS = `"SF Pro Display", system-ui, -apple-system, "Helvetica Neue", Arial, sans-serif`;
export const MONO = `"SF Mono", "SFNSMono", Menlo, monospace`;

export const EASE_OUT = Easing.bezier(0.16, 1, 0.3, 1);
export const EASE_IN_OUT = Easing.bezier(0.65, 0, 0.35, 1);
export const EASE_IN = Easing.bezier(0.7, 0, 0.84, 0);

export const ramp = (
  frame: number,
  from: number,
  to: number,
  out: [number, number] = [0, 1],
  easing = EASE_OUT,
) =>
  interpolate(frame, [from, to], out, {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

export const useLayout = () => {
  const { width, height } = useVideoConfig();
  const portrait = height > width;
  // one unit = 1px on the 1080-short-side canvas, so type sizes read the same in both cuts
  const u = Math.min(width, height) / 1080;
  return { width, height, portrait, u };
};
