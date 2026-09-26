import React from "react";
import { AbsoluteFill, random, useCurrentFrame } from "remotion";
import { BEAT, C, EASE_IN, ramp, useLayout } from "../theme";

const CAM_H = 1.6;
const LAMP_H = 1.05;
const GAUGE = 1.676;

export const Headlights: React.FC = () => {
  const frame = useCurrentFrame();
  const { width, height, portrait } = useLayout();
  const dur = BEAT * 4;
  const cx = width / 2;
  const vy = height * (portrait ? 0.42 : 0.4);
  const f = (height - vy) / CAM_H;

  const t = frame / dur;
  const d = 70 * Math.pow(1 - t, 2.4) + 0.9;
  const approach = 1 - d / 71;

  const shake = Math.pow(approach, 3) * 6;
  const sx = (random(`x${frame}`) - 0.5) * shake;
  const sy = (random(`y${frame}`) - 0.5) * shake;

  const railX = (side: number, z: number) => cx + (side * GAUGE * 0.5 * f) / z;
  const groundY = (z: number) => vy + (CAM_H * f) / z;

  const travel = frame * 0.9;
  const sleepers = Array.from({ length: 90 }, (_, i) => 1.5 + (((i * 0.65 - travel) % 58.5) + 58.5) % 58.5);

  const lampSep = (1.1 * f) / d;
  const lampY = vy + ((CAM_H - LAMP_H) * f) / d;
  const r = Math.max(2, (0.16 * f) / d);
  const lit = 0.06 + approach * 0.55;
  const bloom = ramp(frame, dur - 26, dur, [0, 1], EASE_IN);
  const fadeIn = ramp(frame, 0, 10);

  return (
    <AbsoluteFill style={{ background: C.ink, opacity: fadeIn }}>
      <AbsoluteFill style={{ transform: `translate(${sx}px, ${sy}px)` }}>
        <svg width={width} height={height} style={{ position: "absolute", inset: 0 }}>
          <defs>
            <linearGradient id="rail" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="#ffd98a" stopOpacity={0} />
              <stop offset="0.5" stopColor="#ffd98a" stopOpacity={lit * 0.9} />
              <stop offset="1" stopColor="#ffffff" stopOpacity={lit * 0.5} />
            </linearGradient>
          </defs>
          {sleepers.map((z, i) => {
            const y = groundY(z);
            const x0 = railX(-1.5, z);
            const x1 = railX(1.5, z);
            const a = Math.min(1, 6 / z) * Math.min(1, (z - 1.5) / 2.5) * lit * 0.7;
            return <line key={i} x1={x0} x2={x1} y1={y} y2={y} stroke="#8a6f45" strokeOpacity={a} strokeWidth={Math.max(0.8, (CAM_H * f * 0.14) / (z * z))} />;
          })}
          {[-1, 1].map((side) => (
            <line key={side} x1={cx} y1={vy} x2={railX(side, 1.1)} y2={groundY(1.1)} stroke="url(#rail)" strokeWidth={3} />
          ))}
        </svg>
        <div
          style={{
            position: "absolute",
            left: cx - lampSep * 2.2,
            top: lampY,
            width: lampSep * 4.4,
            height: Math.max(20, (height - lampY) * 1.2),
            background: "radial-gradient(ellipse 50% 60% at 50% 0%, rgba(255,214,140,0.35) 0%, rgba(255,190,90,0.08) 45%, rgba(0,0,0,0) 75%)",
            opacity: approach,
          }}
        />
        {[-1, 1].map((side) => {
          const x = cx + (side * lampSep) / 2;
          return (
            <React.Fragment key={side}>
              <div
                style={{
                  position: "absolute",
                  left: x - r * 9,
                  top: lampY - r * 9,
                  width: r * 18,
                  height: r * 18,
                  borderRadius: "50%",
                  background: "radial-gradient(circle, rgba(247,190,0,0.55) 0%, rgba(247,150,0,0.18) 30%, rgba(0,0,0,0) 70%)",
                }}
              />
              <div
                style={{
                  position: "absolute",
                  left: x - r,
                  top: lampY - r,
                  width: r * 2,
                  height: r * 2,
                  borderRadius: "50%",
                  background: "radial-gradient(circle, #ffffff 0%, #fff4c9 45%, #f7be00 100%)",
                  boxShadow: `0 0 ${r * 2}px ${r * 0.6}px rgba(255,220,120,0.9)`,
                }}
              />
            </React.Fragment>
          );
        })}
        <div
          style={{
            position: "absolute",
            left: cx - width * 0.7,
            top: lampY - r * 0.6,
            width: width * 1.4,
            height: r * 1.2,
            background: "radial-gradient(ellipse at center, rgba(255,236,190,0.75) 0%, rgba(120,170,255,0.25) 30%, rgba(0,0,0,0) 70%)",
            opacity: 0.3 + approach * 0.7,
            filter: `blur(${r * 0.3}px)`,
          }}
        />
      </AbsoluteFill>
      <AbsoluteFill style={{ background: "#fffaf0", opacity: bloom }} />
    </AbsoluteFill>
  );
};
