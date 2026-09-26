import React from "react";
import { AbsoluteFill, random, useCurrentFrame } from "remotion";
import timeline from "../timeline.json";
import { FlapCell } from "../lib/ui";
import { BEAT, C, EASE_IN, SANS, ramp, useLayout } from "../theme";

const wrap = (text: string, cols: number) => {
  const lines: string[] = [];
  let cur = "";
  for (const w of text.split(" ")) {
    const next = cur ? `${cur} ${w}` : w;
    if (next.length > cols) {
      lines.push(cur);
      cur = w;
    } else cur = next;
  }
  lines.push(cur);
  return lines;
};

const layoutWord = (text: string, cols: number, rows: number) => {
  const lines = wrap(text, cols);
  const grid: string[][] = Array.from({ length: rows }, () => Array(cols).fill(" "));
  const top = Math.floor((rows - lines.length) / 2);
  lines.forEach((l, r) => {
    const left = Math.floor((cols - l.length) / 2);
    [...l].forEach((ch, c) => (grid[top + r][left + c] = ch));
  });
  return grid;
};

export const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const { portrait, u, width } = useLayout();
  const cols = portrait ? 11 : 17;
  const rows = portrait ? 5 : 3;
  const pitch = (portrait ? width * 0.92 : width * 0.88) / cols;
  const w = pitch * 0.9;
  const h = w * 1.42;
  const words = timeline.hookWords;
  const per = BEAT * 2;
  const idx = Math.min(words.length - 1, Math.floor(frame / per));
  const at = idx * per;
  const grid = layoutWord(words[idx], cols, rows);
  const prev = idx > 0 ? layoutWord(words[idx - 1], cols, rows) : null;

  const push = ramp(frame, 0, BEAT * 8, [1, 1.12], (x) => x);
  const lightsOff = ramp(frame, BEAT * 8 - 12, BEAT * 8 - 2, [1, 0], EASE_IN);
  const intro = ramp(frame, 0, 16);

  return (
    <AbsoluteFill style={{ background: C.ink, alignItems: "center", justifyContent: "center", opacity: lightsOff }}>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 70% 50% at 50% 38%, rgba(247,190,0,0.10), rgba(0,0,0,0) 70%)" }} />
      <div style={{ transform: `perspective(${2400 * u}px) rotateX(${6 - push * 3}deg) scale(${push})`, opacity: intro }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 22 * u, padding: `0 ${4 * u}px` }}>
          <span style={{ fontFamily: SANS, fontWeight: 700, fontSize: 22 * u, letterSpacing: "0.32em", color: "rgba(247,190,0,0.75)" }}>DEPARTURES</span>
          <span style={{ fontFamily: SANS, fontWeight: 600, fontSize: 22 * u, letterSpacing: "0.12em", color: "rgba(255,255,255,0.45)", fontVariantNumeric: "tabular-nums" }}>
            16:5{Math.min(9, 7 + idx)} IST
          </span>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: `repeat(${cols}, ${w}px)`, gap: `${pitch * 0.14}px ${pitch - w}px` }}>
          {grid.flatMap((row, r) =>
            row.map((ch, c) => {
              const before = prev ? prev[r][c] : " ";
              const still = ch === " " && before === " ";
              const startAt = at + c * 0.5 + r * 1.5;
              const settleAt = still ? startAt : startAt + 6 + random(`s${idx}-${r}-${c}`) * 9;
              return <FlapCell key={`${r}-${c}-${idx}`} target={ch} startAt={startAt} settleAt={settleAt} seed={r * 100 + c + idx * 1000} w={w} h={h} />;
            }),
          )}
        </div>
      </div>
    </AbsoluteFill>
  );
};
