import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { Icon } from "../lib/Icon";
import { Fade } from "../lib/ui";
import { BEAT, C, EASE_IN, EASE_OUT, SANS, ramp, useLayout } from "../theme";

export const Logo: React.FC = () => {
  const frame = useCurrentFrame();
  const { portrait, u, width, height } = useLayout();
  const dur = BEAT * 8;
  const size = (portrait ? 260 : 230) * u;
  const word = "Railly";
  const wordSize = (portrait ? 190 : 210) * u;

  const land = ramp(frame, 0, 34);
  const flash = ramp(frame, 0, 26, [1, 0]);
  const glow = ramp(frame, 4, 16) * ramp(frame, 16, 70, [1, 0.35]);

  const zoomStart = dur - 40;
  const zoom = ramp(frame, zoomStart, dur, [0, 1], EASE_IN);
  const textOut = ramp(frame, zoomStart - 14, zoomStart + 4, [0, 1], EASE_IN);

  const gap = 44 * u;
  const wordW = wordSize * 2.55;
  const groupW = portrait ? size : size + gap + wordW;
  const iconLeft = portrait ? width / 2 - size / 2 : width / 2 - groupW / 2;
  const iconTop = portrait ? height * 0.36 - size / 2 : height / 2 - size / 2 - 20 * u;

  const toCx = (width / 2 - (iconLeft + size / 2)) * zoom;
  const toCy = (height / 2 - (iconTop + size * (22.5 / 64))) * zoom;
  const scale = (1.25 - 0.25 * land) * (1 + Math.pow(zoom, 1.8) * 60);

  return (
    <AbsoluteFill style={{ background: `radial-gradient(ellipse 80% 70% at 50% 45%, ${C.raise} 0%, ${C.midnight} 45%, ${C.ink} 100%)` }}>
      <AbsoluteFill
        style={{
          background: "radial-gradient(ellipse 50% 40% at 50% 50%, rgba(77,159,255,0.18), rgba(0,0,0,0) 70%)",
          opacity: ramp(frame, 10, 60) * (1 - textOut),
        }}
      />
      <div
        style={{
          position: "absolute",
          left: iconLeft,
          top: iconTop,
          transformOrigin: `50% ${(22.5 / 64) * 100}%`,
          transform: `translate(${toCx}px, ${toCy}px) scale(${scale})`,
          filter: `blur(${(1 - land) * 12}px) drop-shadow(0 ${30 * u}px ${60 * u}px rgba(0,0,0,0.5))`,
          opacity: 0.2 + land * 0.8,
        }}
      >
        <Icon size={size} glow={glow * (1 - zoom)} />
      </div>
      <div
        style={{
          position: "absolute",
          left: portrait ? 0 : iconLeft + size + gap,
          right: portrait ? 0 : undefined,
          top: portrait ? iconTop + size + 60 * u : height / 2 - wordSize * 0.62 - 20 * u,
          display: "flex",
          justifyContent: portrait ? "center" : "flex-start",
          opacity: 1 - textOut,
          transform: `translateX(${-textOut * 30 * u}px)`,
        }}
      >
        {[...word].map((ch, i) => {
          const t = ramp(frame, 12 + i * 3, 42 + i * 3);
          return (
            <span key={i} style={{ display: "inline-block", overflow: "hidden", paddingBottom: wordSize * 0.18, marginBottom: -wordSize * 0.18 }}>
              <span
                style={{
                  display: "inline-block",
                  fontFamily: SANS,
                  fontSize: wordSize,
                  fontWeight: 800,
                  letterSpacing: "-0.045em",
                  color: C.white,
                  transform: `translateY(${(1 - t) * 110}%)`,
                  lineHeight: 1.1,
                }}
              >
                {ch}
              </span>
            </span>
          );
        })}
      </div>
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: portrait ? iconTop + size + 60 * u + wordSize * 1.3 : height / 2 + wordSize * 0.55,
          display: "flex",
          justifyContent: "center",
          opacity: 1 - textOut,
        }}
      >
        <Fade at={58} y={14}>
          <div style={{ fontFamily: SANS, fontSize: (portrait ? 38 : 36) * u, fontWeight: 500, color: "rgba(255,255,255,0.62)", letterSpacing: "-0.01em", textAlign: "center", padding: `0 ${60 * u}px` }}>
            Train tracking for Indian Railways.{portrait ? <br /> : " "}Built for iPhone.
          </div>
        </Fade>
      </div>
      <AbsoluteFill style={{ background: "#fffaf0", opacity: flash }} />
      <AbsoluteFill style={{ background: C.midnight, opacity: ramp(frame, dur - 4, dur, [0, 1], EASE_OUT) }} />
    </AbsoluteFill>
  );
};
