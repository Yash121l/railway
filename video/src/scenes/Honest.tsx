import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { Phone, Words } from "../lib/ui";
import { BEAT, C, EASE_IN, ramp, useLayout } from "../theme";

export const Honest: React.FC = () => {
  const frame = useCurrentFrame();
  const { portrait, u, width, height } = useLayout();
  const dur = BEAT * 6;
  const pw = (portrait ? 420 : 380) * u;
  const enter = ramp(frame, 6, 60);
  const out = ramp(frame, dur - 16, dur, [0, 1], EASE_IN);

  return (
    <AbsoluteFill style={{ background: `radial-gradient(ellipse 70% 70% at 50% 50%, #141735 0%, ${C.ink} 100%)`, overflow: "hidden", opacity: 1 - out }}>
      <div
        style={{
          position: "absolute",
          left: portrait ? width / 2 - pw / 2 : width * 0.62,
          top: portrait ? height * 0.4 : height / 2 - (pw * 2.174) / 2,
          opacity: enter,
          transform: `perspective(${2600 * u}px) translateY(${(1 - enter) * 80 * u}px) rotateY(${portrait ? 0 : -10}deg) scale(${0.96 + frame * 0.0003})`,
        }}
      >
        <Phone src="screens/estimates.png" width={pw} glare={0.35} />
      </div>
      <div style={{ position: "absolute", left: portrait ? 70 * u : width * 0.065, right: portrait ? 70 * u : undefined, top: portrait ? height * 0.08 : height * 0.3, width: portrait ? undefined : width * 0.5 }}>
        <Words text="Nothing made up." at={6} size={(portrait ? 104 : 116) * u} />
        <div style={{ height: 24 * u }} />
        <Words text="If it's an estimate, it says so." at={50} size={(portrait ? 64 : 64) * u} weight={600} color="rgba(255,255,255,0.6)" accent={{ says: C.sun, "so.": C.sun }} />
      </div>
    </AbsoluteFill>
  );
};
