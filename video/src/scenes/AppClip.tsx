import React from "react";
import { AbsoluteFill, OffthreadVideo, staticFile, useCurrentFrame } from "remotion";
import timeline from "../timeline.json";
import { Fade, FlapKicker, Tag, Words } from "../lib/ui";
import { C, EASE_IN_OUT, FPS, SANS, ramp, scene, useLayout } from "../theme";

type Clip = { src: string; start: number; rate: number; tapAt?: number; tapX?: number; tapY?: number };
const CLIPS = timeline.clips as Record<string, Clip>;
const ASPECT = 2868 / 1320;

type Line = { text: string; accent?: Record<string, string>; sub?: string; at: number };

export type AppClipSpec = {
  id: string;
  /** chapter title on flap tiles; `continues` keeps it still when the previous scene had the same one */
  chapter: { text: string; continues?: boolean };
  lines: Line[];
  tone?: "dark" | "violet";
  /** gentle camera moves on the phone: [frame, scale, originY 0..1] */
  push?: [number, number, number][];
};

const VideoPhone: React.FC<{ clip: Clip; width: number }> = ({ clip, width }) => {
  const frame = useCurrentFrame();
  const h = width * ASPECT;
  const bezel = width * 0.035;
  const radius = width * 0.155;
  const tapFrame = clip.tapAt !== undefined ? Math.round((clip.tapAt / clip.rate) * FPS) : null;
  const tap = tapFrame === null ? 0 : ramp(frame, tapFrame - 4, tapFrame + 22, [0, 1], (x) => x);
  return (
    <div
      style={{
        width: width + bezel * 2,
        height: h + bezel * 2,
        padding: bezel,
        borderRadius: radius + bezel,
        background: "linear-gradient(145deg, #4a4a52 0%, #1a1a1e 22%, #0b0b0d 60%, #2c2c31 100%)",
        boxShadow: `0 0 0 ${width * 0.004}px rgba(255,255,255,0.18) inset, 0 ${width * 0.1}px ${width * 0.22}px rgba(0,0,0,0.55)`,
        position: "relative",
      }}
    >
      <div style={{ width, height: h, borderRadius: radius, overflow: "hidden", position: "relative", background: "#000" }}>
        <OffthreadVideo
          src={staticFile(clip.src)}
          trimBefore={Math.round(clip.start * FPS)}
          playbackRate={clip.rate}
          muted
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
        <div style={{ position: "absolute", left: "50%", top: width * 0.028, width: width * 0.3, height: width * 0.085, marginLeft: -width * 0.15, borderRadius: width, background: "#000" }} />
        {tapFrame !== null && tap > 0 && tap < 1 && (
          <div
            style={{
              position: "absolute",
              left: `${(clip.tapX ?? 0.5) * 100}%`,
              top: `${(clip.tapY ?? 0.5) * 100}%`,
              width: width * 0.16,
              height: width * 0.16,
              marginLeft: -width * 0.08,
              marginTop: -width * 0.08,
              borderRadius: "50%",
              background: "rgba(255,255,255,0.55)",
              border: `${width * 0.006}px solid rgba(255,255,255,0.9)`,
              transform: `scale(${0.4 + tap * 0.9})`,
              opacity: tap < 0.25 ? tap * 4 : 1 - (tap - 0.25) / 0.75,
              boxShadow: "0 0 30px rgba(0,0,0,0.25)",
            }}
          />
        )}
      </div>
    </div>
  );
};

export const makeAppClip = (spec: AppClipSpec): React.FC => {
  const Scene: React.FC = () => {
    const frame = useCurrentFrame();
    const { portrait, u, width, height } = useLayout();
    const { duration } = scene(spec.id);
    const clip = CLIPS[spec.id];
    const pw = portrait ? Math.min(560 * u, (height * 0.6) / ASPECT) : Math.min(430 * u, (height * 0.86) / ASPECT);
    const enter = ramp(frame, 0, 26);
    const exit = ramp(frame, duration - 10, duration, [0, 1], EASE_IN_OUT);
    const push = spec.push ?? [];
    let scale = 1;
    let origin = 0.5;
    for (let i = 0; i < push.length; i++) {
      const [at, s, o] = push[i];
      const prev = i === 0 ? [0, 1, 0.5] : push[i - 1];
      const t = ramp(frame, at, at + 36, [0, 1], EASE_IN_OUT);
      if (frame >= at) {
        scale = prev[1] + (s - prev[1]) * t;
        origin = prev[2] + (o - prev[2]) * t;
      }
    }
    const bg =
      spec.tone === "violet"
        ? `radial-gradient(ellipse 80% 80% at 65% 50%, #2a1f6e 0%, ${C.midnight} 55%, ${C.ink} 100%)`
        : `radial-gradient(ellipse 80% 90% at 68% 55%, #1a1f4a 0%, ${C.midnight} 50%, ${C.ink} 100%)`;
    const float = Math.sin(frame / 40) * 6 * u;
    const headSize = (portrait ? 92 : 100) * u;

    return (
      <AbsoluteFill style={{ background: bg, overflow: "hidden" }}>
        <div
          style={{
            position: "absolute",
            left: portrait ? width / 2 - pw / 2 : width * 0.6,
            top: portrait ? height * 0.34 : height / 2 - (pw * ASPECT) / 2 - 10 * u,
            transform: `perspective(${2600 * u}px) translateY(${(1 - enter) * 80 * u + float}px) rotateY(${portrait ? 0 : -6 + enter * 2}deg) scale(${(0.94 + enter * 0.06) * scale})`,
            transformOrigin: `50% ${origin * 100}%`,
            opacity: enter * (1 - exit * 0.4),
          }}
        >
          <VideoPhone clip={clip} width={pw} />
          <div style={{ position: "absolute", left: 0, right: 0, bottom: -48 * u, display: "flex", justifyContent: "center", opacity: scale > 1.05 ? 0 : 0.8 }}>
            <Tag u={u}>Demo data · positions estimated</Tag>
          </div>
        </div>
        {spec.lines.map((line, i) => {
          const next = spec.lines[i + 1];
          return (
            <div
              key={i}
              style={{
                position: "absolute",
                left: portrait ? 70 * u : width * 0.065,
                right: portrait ? 70 * u : undefined,
                top: portrait ? height * 0.07 : height * 0.3,
                width: portrait ? undefined : width * 0.46,
              }}
            >
              {i === 0 && <FlapKicker text={spec.chapter.text} at={2} u={u} flip={!spec.chapter.continues} />}
              {i > 0 && <div style={{ height: 68 * u }} />}
              <Words text={line.text} at={line.at} exitAt={next ? next.at - 16 : duration - 14} size={headSize} accent={line.accent} />
              {line.sub && (
                <Fade at={line.at + 26} exitAt={next ? next.at - 18 : duration - 16} style={{ marginTop: 28 * u }}>
                  <div style={{ fontFamily: SANS, fontSize: 32 * u, color: "rgba(255,255,255,0.62)", fontWeight: 500, lineHeight: 1.35 }}>{line.sub}</div>
                </Fade>
              )}
            </div>
          );
        })}
      </AbsoluteFill>
    );
  };
  Scene.displayName = `AppClip(${spec.id})`;
  return Scene;
};
