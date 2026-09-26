import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { Fade, FlapKicker, Tag, Words, easeOutBack } from "../lib/ui";
import { C, EASE_IN_OUT, SANS, ramp, useLayout } from "../theme";

const LATE = "#ff453a";
const SUB = "#9a9a9e";

const TrainGlyph: React.FC<{ size: number; color: string }> = ({ size, color }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2.2} strokeLinecap="round" strokeLinejoin="round">
    <rect x="5" y="3" width="14" height="14" rx="3.5" />
    <path d="M5 11h14M9 21l-2-3M15 21l2-3" />
    <circle cx="9" cy="14" r="0.6" fill={color} />
    <circle cx="15" cy="14" r="0.6" fill={color} />
  </svg>
);

const End: React.FC<{ code: string; time: string; tint: string; s: number; align: "left" | "right" }> = ({ code, time, tint, s, align }) => (
  <div style={{ textAlign: align, fontFamily: SANS }}>
    <div style={{ fontSize: 22 * s, fontWeight: 800, color: "#fff", lineHeight: 1.05 }}>{code}</div>
    <div style={{ fontSize: 14 * s, fontWeight: 600, color: tint, fontVariantNumeric: "tabular-nums" }}>{time}</div>
  </div>
);

export const Live: React.FC = () => {
  const frame = useCurrentFrame();
  const { portrait, u, width, height } = useLayout();
  const pw = (portrait ? 700 : 600) * u;
  const s = pw / 402;
  const ph = pw * 2.174;

  const enter = ramp(frame, 0, 40);
  const compact = ramp(frame, 14, 30);
  const expandT = ramp(frame, 40, 60, [0, 1], (x) => x);
  const collapseT = ramp(frame, 112, 130, [0, 1], EASE_IN_OUT);
  const ex = Math.max(0, easeOutBack(expandT) * (1 - collapseT));
  const card = ramp(frame, 108, 132);

  const iw = interpolate(ex, [0, 1], [126 + compact * 84, 380]) * s;
  const ih = interpolate(ex, [0, 1], [37, 164]) * s;
  const ir = interpolate(ex, [0, 1], [18.5, 46]) * s;
  const progress = interpolate(frame, [60, 240], [0.38, 0.41]);

  return (
    <AbsoluteFill style={{ background: `radial-gradient(ellipse 80% 80% at 60% 30%, #22184a 0%, ${C.midnight} 50%, ${C.ink} 100%)`, overflow: "hidden" }}>
      <div
        style={{
          position: "absolute",
          left: portrait ? width / 2 - pw / 2 : width * 0.56,
          top: portrait ? height * 0.34 : height * 0.1,
          width: pw,
          height: ph,
          borderRadius: 62 * s,
          padding: 12 * s,
          background: "linear-gradient(145deg, #4a4a52 0%, #1a1a1e 22%, #0b0b0d 60%, #2c2c31 100%)",
          boxShadow: `0 0 0 ${2 * u}px rgba(255,255,255,0.14) inset, 0 ${60 * u}px ${120 * u}px rgba(0,0,0,0.6)`,
          transform: `perspective(${3000 * u}px) translateY(${(1 - enter) * 500 * u}px) rotateX(${10 - enter * 6}deg) rotateY(${portrait ? 0 : -10}deg)`,
          transformOrigin: "50% 0%",
        }}
      >
        <div
          style={{
            position: "relative",
            width: "100%",
            height: "100%",
            borderRadius: 52 * s,
            overflow: "hidden",
            background: "radial-gradient(ellipse 120% 80% at 30% 20%, #3b2d8f 0%, #1a1450 40%, #07051a 100%)",
          }}
        >
          <div style={{ position: "absolute", left: 0, right: 0, top: 70 * s, textAlign: "center", fontFamily: SANS, color: "rgba(255,255,255,0.9)" }}>
            <div style={{ fontSize: 20 * s, fontWeight: 600 }}>Monday 13 July</div>
            <div style={{ fontSize: 104 * s, fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1, marginTop: 2 * s }}>1:21</div>
          </div>

          <div
            style={{
              position: "absolute",
              left: 12 * s,
              right: 12 * s,
              top: 250 * s,
              padding: `${16 * s}px ${18 * s}px`,
              borderRadius: 26 * s,
              background: "rgba(10,10,14,0.72)",
              backdropFilter: "blur(20px)",
              opacity: card,
              transform: `translateY(${(1 - card) * 40 * s}px) scale(${0.96 + card * 0.04})`,
              fontFamily: SANS,
            }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: 8 * s }}>
              <span style={{ width: 22 * s, height: 22 * s, borderRadius: 99, background: "#c62828", color: "#fff", fontSize: 9 * s, fontWeight: 700, display: "inline-flex", alignItems: "center", justifyContent: "center" }}>RJ</span>
              <span style={{ fontSize: 14 * s, fontWeight: 600, color: SUB }}>12951</span>
              <span style={{ fontSize: 10 * s, fontWeight: 700, color: SUB, padding: `${2 * s}px ${7 * s}px`, borderRadius: 99, background: "rgba(255,255,255,0.1)" }}>Estimated</span>
              <span style={{ flex: 1 }} />
              <span style={{ fontSize: 11 * s, fontWeight: 700, letterSpacing: "0.14em", color: SUB }}>RAILLY</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: 8 * s }}>
              <End code="MMCT" time="17:00" tint={C.go} s={s} align="left" />
              <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 * s }}>
                <TrainGlyph size={15 * s} color={SUB} />
                <div style={{ display: "flex", gap: 3 * s }}>
                  {Array.from({ length: 7 }, (_, i) => (
                    <span key={i} style={{ width: 3 * s, height: 3 * s, borderRadius: 9, background: "rgba(154,154,158,0.5)" }} />
                  ))}
                </div>
              </div>
              <End code="NDLS" time="09:00" tint={LATE} s={s} align="right" />
            </div>
            <div style={{ marginTop: 10 * s, height: 5 * s, borderRadius: 9, background: "rgba(255,255,255,0.12)", overflow: "hidden" }}>
              <div style={{ width: `${progress * 100}%`, height: "100%", background: LATE, borderRadius: 9 }} />
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 9 * s, fontSize: 14 * s, fontWeight: 600 }}>
              <span style={{ color: "#fff" }}>
                Arriving in <span style={{ color: LATE }}>7h 39m</span>
              </span>
              <span style={{ color: LATE }}>28m late</span>
            </div>
          </div>

          <div
            style={{
              position: "absolute",
              left: "50%",
              top: 11 * s,
              width: iw,
              height: ih,
              marginLeft: -iw / 2,
              borderRadius: ir,
              background: "#000",
              boxShadow: ex > 0.05 ? `0 ${10 * s}px ${30 * s}px rgba(0,0,0,0.5)` : "none",
              overflow: "hidden",
              fontFamily: SANS,
            }}
          >
            <div style={{ position: "absolute", left: 14 * s, top: 0, height: 37 * s, display: "flex", alignItems: "center", opacity: compact * (1 - ex * 3) }}>
              <TrainGlyph size={18 * s} color={LATE} />
            </div>
            <div style={{ position: "absolute", right: 14 * s, top: 0, height: 37 * s, display: "flex", alignItems: "center", opacity: compact * (1 - ex * 3), fontSize: 14 * s, fontWeight: 700, color: LATE }}>28m</div>
            <div style={{ position: "absolute", inset: 0, padding: `${20 * s}px ${24 * s}px`, opacity: ramp(ex, 0.55, 1), display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <End code="MMCT" time="17:00" tint={C.go} s={s} align="left" />
                <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2 * s, marginTop: 4 * s }}>
                  <TrainGlyph size={16 * s} color={SUB} />
                  <span style={{ fontSize: 11 * s, color: SUB }}>12951</span>
                </div>
                <End code="NDLS" time="09:00" tint={LATE} s={s} align="right" />
              </div>
              <div>
                <div style={{ height: 5 * s, borderRadius: 9, background: "rgba(255,255,255,0.14)", overflow: "hidden" }}>
                  <div style={{ width: `${progress * 100}%`, height: "100%", background: LATE }} />
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", marginTop: 10 * s, fontSize: 15 * s, fontWeight: 600 }}>
                  <span style={{ color: SUB }}>
                    NEXT RTM <span style={{ color: "#fff" }}>in 26 min</span>
                  </span>
                  <span style={{ color: SUB }}>57 km/h</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div style={{ position: "absolute", left: portrait ? 70 * u : width * 0.065, right: portrait ? 70 * u : undefined, top: portrait ? height * 0.07 : height * 0.26, width: portrait ? undefined : width * 0.44 }}>
        <FlapKicker text="OVERNIGHT" at={2} u={u} />
        <Words text="Your trip, on the lock screen." at={8} size={(portrait ? 96 : 104) * u} accent={{ "lock": "#b9a8ff", "screen.": "#b9a8ff" }} />
        <Fade at={30} style={{ marginTop: 30 * u }}>
          <div style={{ fontFamily: SANS, fontSize: 32 * u, color: "rgba(255,255,255,0.62)", fontWeight: 500, lineHeight: 1.35 }}>
            Live Activity and Dynamic Island, the whole way there.
          </div>
        </Fade>
        <Fade at={50} style={{ marginTop: 26 * u }}>
          <Tag u={u}>Demo data · positions estimated</Tag>
        </Fade>
      </div>
    </AbsoluteFill>
  );
};
