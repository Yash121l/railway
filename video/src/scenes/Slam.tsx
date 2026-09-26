import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import timeline from "../timeline.json";
import { BEAT, C, EASE_OUT, SANS, ramp, useLayout } from "../theme";

const TONES: Record<string, { bg: string; fg: string }> = {
  dark: { bg: C.ink, fg: C.white },
  light: { bg: C.linen, fg: "#0b0b10" },
  sun: { bg: C.sun, fg: "#0b0b10" },
};

const rollNumber = (text: string, t: number) =>
  text.replace(/^[\d,]+/, (m) => {
    const n = Number(m.replace(/,/g, ""));
    return Math.round(n * t).toLocaleString("en-US");
  });

export const Slam: React.FC = () => {
  const frame = useCurrentFrame();
  const { portrait, u } = useLayout();
  const items = timeline.slam;
  const item = [...items].reverse().find((i) => frame >= i.beat * BEAT) ?? items[0];
  const local = frame - item.beat * BEAT;
  const tone = TONES[item.tone];
  const punch = ramp(local, 0, 12, [0, 1], EASE_OUT);
  const t = ramp(local, 0, 22, [0, 1], EASE_OUT);
  const size = (portrait ? 150 : 210) * u;
  const last = item === items[items.length - 1];
  const drift = local * 0.25 * u;

  return (
    <AbsoluteFill style={{ background: tone.bg, alignItems: "center", justifyContent: "center" }}>
      <div
        style={{
          fontFamily: SANS,
          fontWeight: 800,
          fontSize: last ? size * 1.5 : size,
          letterSpacing: "-0.05em",
          lineHeight: 0.95,
          color: tone.fg,
          textAlign: "center",
          padding: `0 ${70 * u}px`,
          transform: `scale(${1.22 - punch * 0.22}) translateY(${-drift}px)`,
          filter: `blur(${(1 - punch) * 14}px)`,
          fontVariantNumeric: "tabular-nums",
        }}
      >
        {rollNumber(item.text, t)}
      </div>
    </AbsoluteFill>
  );
};
