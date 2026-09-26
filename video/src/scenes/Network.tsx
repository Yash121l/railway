import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { bounds, cities, corridors, pathD } from "../lib/geo";
import { Fade, Words } from "../lib/ui";
import { BEAT, C, EASE_IN, SANS, ramp, useLayout } from "../theme";

const DRAW_START = 8;
const SPREAD = 9;
const SPEED = 7;

const polyAt = (pts: [number, number][], t: number): [number, number] => {
  const lens = pts.slice(1).map((p, i) => Math.hypot(p[0] - pts[i][0], p[1] - pts[i][1]));
  let target = lens.reduce((a, b) => a + b, 0) * t;
  for (let i = 0; i < lens.length; i++) {
    if (target <= lens[i]) {
      const f = lens[i] ? target / lens[i] : 0;
      return [pts[i][0] + (pts[i + 1][0] - pts[i][0]) * f, pts[i][1] + (pts[i + 1][1] - pts[i][1]) * f];
    }
    target -= lens[i];
  }
  return pts[pts.length - 1];
};

export const Network: React.FC = () => {
  const frame = useCurrentFrame();
  const { portrait, u, width, height } = useLayout();
  const dur = BEAT * 10;
  const exitAt = dur - 24;

  const box = portrait
    ? { x: width * 0.14, y: height * 0.31, w: width * 0.76, h: height * 0.64 }
    : { x: width * 0.43, y: height * 0.05, w: width * 0.54, h: height * 0.9 };
  const bw = bounds.maxX - bounds.minX;
  const bh = bounds.maxY - bounds.minY;
  const push = ramp(frame, exitAt, dur, [0, 1], EASE_IN);
  const s = Math.min(box.w / bw, box.h / bh) * (1 + push * 0.9);
  const drift = frame * 0.02 * u;
  const tx = box.x + box.w / 2 - ((bounds.minX + bounds.maxX) / 2) * s - drift;
  const ty = box.y + box.h / 2 - ((bounds.minY + bounds.maxY) / 2) * s;
  const toScreen = (p: [number, number]) => [p[0] * s + tx, p[1] * s + ty];
  const sw = (px: number) => (px * u) / s;
  const progress = (start: number, len: number) => ramp(frame, start, start + Math.max(10, len * SPEED), [0, 1], (x) => x);

  return (
    <AbsoluteFill style={{ background: `radial-gradient(ellipse 90% 80% at 62% 50%, #151a3d 0%, ${C.midnight} 50%, ${C.ink} 100%)`, overflow: "hidden" }}>
      <AbsoluteFill style={{ opacity: 1 - push, filter: `blur(${push * 6}px)` }}>
        <svg width={width} height={height} style={{ position: "absolute", inset: 0 }}>
          <defs>
            <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
              <feGaussianBlur stdDeviation={sw(5)} />
            </filter>
            <pattern id="dots" width={28 * u} height={28 * u} patternUnits="userSpaceOnUse" patternTransform={`translate(${-drift * 0.5} 0)`}>
              <circle cx={2 * u} cy={2 * u} r={1.1 * u} fill="rgba(255,255,255,0.07)" />
            </pattern>
          </defs>
          <rect width={width} height={height} fill="url(#dots)" />
          <g transform={`translate(${tx} ${ty}) scale(${s})`}>
            <g filter="url(#glow)" opacity={0.85}>
              {corridors.map((c) => (
                <path key={c.key} d={pathD(c.pts)} pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - progress(DRAW_START + c.fromDelhi * SPREAD, c.len)} fill="none" stroke={C.arc} strokeWidth={sw(6)} strokeLinecap="round" />
              ))}
            </g>
            {corridors.map((c) => (
              <path key={c.key} d={pathD(c.pts)} pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - progress(DRAW_START + c.fromDelhi * SPREAD, c.len)} fill="none" stroke="#9cc8ff" strokeWidth={sw(2.2)} strokeLinecap="round" strokeLinejoin="round" />
            ))}
            {corridors.map((c) => {
              const p = progress(DRAW_START + c.fromDelhi * SPREAD, c.len);
              if (p <= 0 || p >= 1) return null;
              const tip = polyAt(c.pts, p);
              return <circle key={c.key} cx={tip[0]} cy={tip[1]} r={sw(3.2)} fill="#ffffff" />;
            })}
            {cities.map((c) => {
              const d = Math.hypot(c.p[0] - cities[0].p[0], c.p[1] - cities[0].p[1]);
              const o = ramp(frame, DRAW_START + d * SPREAD + 14, DRAW_START + d * SPREAD + 30);
              return <circle key={c.code} cx={c.p[0]} cy={c.p[1]} r={sw(4.5) * (0.5 + o * 0.5)} fill="#ffffff" opacity={o} />;
            })}
          </g>
        </svg>
        {cities.map((c) => {
          const d = Math.hypot(c.p[0] - cities[0].p[0], c.p[1] - cities[0].p[1]);
          const o = ramp(frame, DRAW_START + d * SPREAD + 18, DRAW_START + d * SPREAD + 34);
          const [x, y] = toScreen(c.p);
          const fs = 20 * u;
          return (
            <div
              key={c.code}
              style={{
                position: "absolute",
                left: c.anchor === "r" ? x + 14 * u : undefined,
                right: c.anchor === "l" ? width - x + 14 * u : undefined,
                top: y - fs * 0.62,
                fontFamily: SANS,
                fontSize: fs,
                fontWeight: 500,
                color: "rgba(255,255,255,0.7)",
                opacity: o,
                whiteSpace: "nowrap",
                textShadow: "0 2px 12px rgba(0,0,0,0.8)",
              }}
            >
              {c.label}
            </div>
          );
        })}
      </AbsoluteFill>
      <div
        style={{
          position: "absolute",
          left: portrait ? 70 * u : width * 0.065,
          right: portrait ? 70 * u : undefined,
          top: portrait ? height * 0.08 : height * 0.3,
          width: portrait ? undefined : width * 0.38,
        }}
      >
        <Words text="Every route, drawn on real track." at={18} exitAt={exitAt - 6} size={(portrait ? 96 : 104) * u} accent={{ real: "#8fc0ff", "track.": "#8fc0ff" }} />
        <Fade at={46} exitAt={exitAt - 8} style={{ marginTop: 30 * u }}>
          <div style={{ fontFamily: SANS, fontSize: 32 * u, color: "rgba(255,255,255,0.62)", fontWeight: 500, lineHeight: 1.35 }}>
            120 corridors traced from OpenStreetMap track, checked against the railway&apos;s own kilometres.
          </div>
        </Fade>
      </div>
      <AbsoluteFill style={{ background: C.midnight, opacity: ramp(frame, 0, 14, [1, 0]) }} />
    </AbsoluteFill>
  );
};
