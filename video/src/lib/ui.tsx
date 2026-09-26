import React from "react";
import { AbsoluteFill, Img, random, staticFile, useCurrentFrame } from "remotion";
import { C, EASE_IN, EASE_OUT, MONO, SANS, ramp } from "../theme";

export const Words: React.FC<{
  text: string;
  at: number;
  exitAt?: number;
  size: number;
  weight?: number;
  color?: string;
  stagger?: number;
  tracking?: number;
  lineHeight?: number;
  align?: "left" | "center";
  maxWidth?: number;
  accent?: Record<string, string>;
}> = ({
  text,
  at,
  exitAt,
  size,
  weight = 700,
  color = C.white,
  stagger = 3,
  tracking = -0.035,
  lineHeight = 1.02,
  align = "left",
  maxWidth,
  accent = {},
}) => {
  const frame = useCurrentFrame();
  const words = text.split(" ");
  return (
    <div
      style={{
        fontFamily: SANS,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: `${tracking}em`,
        lineHeight,
        color,
        textAlign: align,
        maxWidth,
        display: "flex",
        flexWrap: "wrap",
        justifyContent: align === "center" ? "center" : "flex-start",
        columnGap: size * 0.26,
      }}
    >
      {words.map((w, i) => {
        const inT = ramp(frame, at + i * stagger, at + i * stagger + 26);
        const outT = exitAt === undefined ? 0 : ramp(frame, exitAt + i * 1.5, exitAt + i * 1.5 + 14, [0, 1], EASE_IN);
        const y = (1 - inT) * 105 - outT * 105;
        return (
          <span key={i} style={{ display: "inline-block", overflow: "hidden", paddingBottom: size * 0.12, marginBottom: -size * 0.12 }}>
            <span
              style={{
                display: "inline-block",
                transform: `translateY(${y}%) rotate(${(1 - inT) * 4}deg)`,
                transformOrigin: "left bottom",
                color: accent[w] ?? color,
              }}
            >
              {w}
            </span>
          </span>
        );
      })}
    </div>
  );
};

export const Fade: React.FC<{
  at: number;
  exitAt?: number;
  dur?: number;
  y?: number;
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({ at, exitAt, dur = 22, y = 18, children, style }) => {
  const frame = useCurrentFrame();
  const i = ramp(frame, at, at + dur);
  const o = exitAt === undefined ? 0 : ramp(frame, exitAt, exitAt + 12, [0, 1], EASE_IN);
  return (
    <div style={{ opacity: i * (1 - o), transform: `translateY(${(1 - i) * y - o * y * 0.6}px)`, filter: `blur(${(1 - i) * 8 + o * 6}px)`, ...style }}>
      {children}
    </div>
  );
};

export const Tag: React.FC<{ children: React.ReactNode; u: number; tone?: "dark" | "light" }> = ({ children, u, tone = "dark" }) => (
  <div
    style={{
      display: "inline-flex",
      alignItems: "center",
      gap: 8 * u,
      padding: `${7 * u}px ${14 * u}px`,
      borderRadius: 999,
      border: `${1.5 * u}px solid ${tone === "dark" ? "rgba(255,255,255,0.16)" : "rgba(0,0,0,0.12)"}`,
      background: tone === "dark" ? "rgba(255,255,255,0.06)" : "rgba(0,0,0,0.03)",
      color: tone === "dark" ? "rgba(255,255,255,0.72)" : C.steel,
      fontFamily: SANS,
      fontSize: 17 * u,
      fontWeight: 600,
      letterSpacing: "0.08em",
      textTransform: "uppercase",
      whiteSpace: "nowrap",
    }}
  >
    {children}
  </div>
);

export const Phone: React.FC<{
  src: string;
  next?: { src: string; at: number };
  width: number;
  style?: React.CSSProperties;
  glare?: number;
}> = ({ src, next, width, style, glare = 0.5 }) => {
  const frame = useCurrentFrame();
  const h = width * (2622 / 1206);
  const bezel = width * 0.035;
  const radius = width * 0.155;
  const swap = next ? ramp(frame, next.at, next.at + 26) : 0;
  return (
    <div
      style={{
        width: width + bezel * 2,
        height: h + bezel * 2,
        padding: bezel,
        borderRadius: radius + bezel,
        background: "linear-gradient(145deg, #4a4a52 0%, #1a1a1e 22%, #0b0b0d 60%, #2c2c31 100%)",
        boxShadow: `0 0 0 ${width * 0.004}px rgba(255,255,255,0.18) inset, 0 ${width * 0.1}px ${width * 0.22}px rgba(0,0,0,0.55), 0 ${width * 0.02}px ${width * 0.05}px rgba(0,0,0,0.4)`,
        position: "relative",
        ...style,
      }}
    >
      <div style={{ width, height: h, borderRadius: radius, overflow: "hidden", position: "relative", background: "#000" }}>
        <Img src={staticFile(src)} style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", transform: `translateX(${-swap * 30}%)`, opacity: 1 - swap * 0.6 }} />
        {next && (
          <Img
            src={staticFile(next.src)}
            style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", transform: `translateX(${(1 - swap) * 100}%)`, boxShadow: "-20px 0 40px rgba(0,0,0,0.25)" }}
          />
        )}
        <div style={{ position: "absolute", left: "50%", top: width * 0.028, width: width * 0.3, height: width * 0.085, marginLeft: -width * 0.15, borderRadius: width, background: "#000" }} />
        <div
          style={{
            position: "absolute",
            inset: 0,
            background: `linear-gradient(115deg, rgba(255,255,255,${0.16 * glare}) 0%, rgba(255,255,255,0) 38%, rgba(255,255,255,0) 70%, rgba(255,255,255,${0.06 * glare}) 100%)`,
            pointerEvents: "none",
          }}
        />
      </div>
    </div>
  );
};

export const Grain: React.FC<{ opacity?: number }> = ({ opacity = 0.07 }) => {
  const frame = useCurrentFrame();
  const seed = Math.floor(frame / 2) % 60;
  return (
    <AbsoluteFill style={{ pointerEvents: "none", mixBlendMode: "overlay", opacity }}>
      <svg width="100%" height="100%">
        <filter id={`g${seed}`}>
          <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed={seed} stitchTiles="stitch" />
          <feColorMatrix type="saturate" values="0" />
        </filter>
        <rect width="100%" height="100%" filter={`url(#g${seed})`} />
      </svg>
    </AbsoluteFill>
  );
};

export const Vignette: React.FC<{ strength?: number }> = ({ strength = 0.55 }) => (
  <AbsoluteFill style={{ pointerEvents: "none", background: `radial-gradient(ellipse at 50% 45%, rgba(0,0,0,0) 45%, rgba(0,0,0,${strength}) 100%)` }} />
);

const FLAP_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?'";

export const FlapCell: React.FC<{ target: string; settleAt: number; startAt: number; seed: number; w: number; h: number }> = ({ target, settleAt, startAt, seed, w, h }) => {
  const frame = useCurrentFrame();
  const flipping = frame >= startAt && frame < settleAt;
  const tick = Math.floor(frame / 2);
  const ch = frame < startAt ? " " : flipping ? FLAP_CHARS[Math.floor(random(`${seed}-${tick}`) * FLAP_CHARS.length)] : target;
  const phase = flipping ? (frame % 2) / 2 : 1;
  const settled = frame >= settleAt ? ramp(frame, settleAt, settleAt + 10) : 0;
  const lit = ch.trim() !== "";
  return (
    <div
      style={{
        width: w,
        height: h,
        borderRadius: w * 0.09,
        background: "linear-gradient(180deg, #1c1b22 0%, #141319 49.5%, #0a0a0d 50.5%, #121116 100%)",
        boxShadow: `inset 0 ${h * 0.01}px 0 rgba(255,255,255,0.06), 0 ${h * 0.03}px ${h * 0.06}px rgba(0,0,0,0.6)`,
        position: "relative",
        overflow: "hidden",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <span
        style={{
          fontFamily: SANS,
          fontWeight: 700,
          fontSize: h * 0.72,
          color: lit ? (frame >= settleAt ? C.sun : "#e8e2cf") : "transparent",
          textShadow: frame >= settleAt ? `0 0 ${h * 0.25 * settled}px rgba(247,190,0,${0.55 * settled})` : "none",
          transform: `scaleY(${flipping ? 0.55 + phase * 0.45 : 1})`,
          transformOrigin: "50% 50%",
          lineHeight: 1,
          fontVariantNumeric: "tabular-nums",
        }}
      >
        {ch}
      </span>
      <div style={{ position: "absolute", left: 0, right: 0, top: "50%", height: Math.max(1, h * 0.012), background: "rgba(0,0,0,0.85)" }} />
    </div>
  );
};

export const Mono: React.FC<{ children: React.ReactNode; size: number; color?: string; style?: React.CSSProperties }> = ({ children, size, color = "rgba(255,255,255,0.55)", style }) => (
  <span style={{ fontFamily: MONO, fontSize: size, color, letterSpacing: "0.06em", ...style }}>{children}</span>
);

export const easeOutBack = (t: number) => {
  const c1 = 1.4;
  const c3 = c1 + 1;
  return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2);
};

export const pop = (frame: number, at: number, dur = 18) => easeOutBack(ramp(frame, at, at + dur, [0, 1], (x) => x));

export { EASE_OUT };
