import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { Icon } from "../lib/Icon";
import { bounds, corridors, pathD } from "../lib/geo";
import { Fade, Words, pop } from "../lib/ui";
import { BEAT, C, EASE_IN, SANS, ramp, useLayout } from "../theme";

export const End: React.FC = () => {
  const frame = useCurrentFrame();
  const { portrait, u, width, height } = useLayout();
  const dur = BEAT * 12;

  const iconP = pop(frame, 0, 26);
  const glow = ramp(frame, 0, 8) * ramp(frame, 8, 80, [1, 0.3]);
  const size = (portrait ? 220 : 190) * u;
  const wordSize = (portrait ? 170 : 170) * u;
  const fadeOut = ramp(frame, dur - 40, dur - 4, [0, 1], EASE_IN);

  const bw = bounds.maxX - bounds.minX;
  const bh = bounds.maxY - bounds.minY;
  const ms = (Math.max(width, height) * 0.95) / Math.max(bw, bh);
  const mx = width / 2 - ((bounds.minX + bounds.maxX) / 2) * ms;
  const my = height / 2 - ((bounds.minY + bounds.maxY) / 2) * ms;

  return (
    <AbsoluteFill style={{ background: `radial-gradient(ellipse 70% 60% at 50% 45%, ${C.raise} 0%, ${C.midnight} 45%, ${C.ink} 100%)`, overflow: "hidden" }}>
      <svg width={width} height={height} style={{ position: "absolute", inset: 0, opacity: ramp(frame, 0, 60) * 0.22 }}>
        <g transform={`translate(${mx} ${my}) scale(${ms * (1 + frame * 0.00025)})`}>
          {corridors.map((c) => (
            <path key={c.key} d={pathD(c.pts)} fill="none" stroke={C.arc} strokeWidth={1.4 / ms} />
          ))}
        </g>
      </svg>

      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", flexDirection: "column" }}>
        <div style={{ display: "flex", flexDirection: portrait ? "column" : "row", alignItems: "center", gap: (portrait ? 40 : 40) * u }}>
          <div style={{ transform: `scale(${Math.max(0, iconP)})`, filter: `drop-shadow(0 ${24 * u}px ${50 * u}px rgba(0,0,0,0.5))` }}>
            <Icon size={size} glow={glow} />
          </div>
          <div style={{ display: "flex" }}>
            {[..."Railly"].map((ch, i) => {
              const t = ramp(frame, 10 + i * 3, 38 + i * 3);
              return (
                <span key={i} style={{ display: "inline-block", overflow: "hidden", paddingBottom: wordSize * 0.18, marginBottom: -wordSize * 0.18 }}>
                  <span style={{ display: "inline-block", fontFamily: SANS, fontSize: wordSize, fontWeight: 800, letterSpacing: "-0.045em", color: C.white, transform: `translateY(${(1 - t) * 110}%)`, lineHeight: 1.1 }}>
                    {ch}
                  </span>
                </span>
              );
            })}
          </div>
        </div>
        <div style={{ marginTop: 44 * u, padding: `0 ${70 * u}px` }}>
          <Words text="Get the truth when you take the train." at={44} size={(portrait ? 62 : 58) * u} weight={600} align="center" color="rgba(255,255,255,0.85)" stagger={3} maxWidth={portrait ? 620 * u : undefined} />
        </div>
        <Fade at={100} style={{ marginTop: 56 * u, display: "flex", flexDirection: "column", alignItems: "center", gap: 22 * u }}>
          <div
            style={{
              padding: `${18 * u}px ${40 * u}px`,
              borderRadius: 999,
              background: C.sun,
              color: "#0b0b10",
              fontFamily: SANS,
              fontSize: 34 * u,
              fontWeight: 700,
              letterSpacing: "-0.01em",
              boxShadow: `0 0 ${50 * u}px rgba(247,190,0,0.35)`,
            }}
          >
            Coming soon to iPhone
          </div>
          <div style={{ fontFamily: SANS, fontSize: 32 * u, fontWeight: 600, color: "rgba(255,255,255,0.7)", letterSpacing: "0.02em" }}>railly.app</div>
        </Fade>
      </AbsoluteFill>
      <AbsoluteFill style={{ background: "#000", opacity: fadeOut }} />
    </AbsoluteFill>
  );
};
