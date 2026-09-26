"use client";

import { useEffect, useRef, useState } from "react";
import { Check, TrainFront } from "lucide-react";
import { getLiveStatus } from "@/lib/sim";
import { fmtDuration, fmtRelative, fmtTime, istDateISO } from "@/lib/time";
import { TRAINS } from "@/lib/trains";
import type { TrainCategory } from "@/lib/types";

/** The app's livery monograms, as on the Live Activity header. */
const LIVERY: Record<TrainCategory, [string, string]> = {
  rajdhani: ["RJ", "#C62828"],
  "vande-bharat": ["VB", "#0D47A1"],
  shatabdi: ["SH", "#546E7A"],
  duronto: ["DR", "#2E7D32"],
  tejas: ["TJ", "#EF6C00"],
  superfast: ["SF", "#6A1B9A"],
  express: ["EX", "#37474F"],
};

// the widget's dark-surface tokens
const ON_TIME = "#32D74B";
const LATE = "#FF453A";
const SUB = "#98989F";

const delayText = (min: number) => (min > 5 ? `${fmtDuration(min)} late` : "On time");

/**
 * A lock screen running the Railly Live Activity, laid out like the widget:
 * livery header with the Estimated label, a route row with times colored by
 * status, the rail with the train on it, then the one line you need next.
 * The Dynamic Island above shows the compact view. It isn't a mock-up: the
 * clock is IST now, and the train comes from whichever service the
 * timetable simulation has on rails at this second.
 */
export function LiveActivityMock() {
  // render nothing time-dependent on the server; hydrate, then tick
  const [now, setNow] = useState<Date | null>(null);
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const raf = requestAnimationFrame(() => setNow(new Date()));
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return () => cancelAnimationFrame(raf);
    }
    const el = rootRef.current;
    if (!el) return () => cancelAnimationFrame(raf);
    let id: ReturnType<typeof setInterval> | null = null;
    // only tick the clock while the card is on screen
    const io = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        setNow(new Date());
        if (id === null) id = setInterval(() => setNow(new Date()), 1000);
      } else if (id !== null) {
        clearInterval(id);
        id = null;
      }
    });
    io.observe(el);
    return () => {
      cancelAnimationFrame(raf);
      if (id !== null) clearInterval(id);
      io.disconnect();
    };
  }, []);

  const statuses = now ? TRAINS.map((t) => getLiveStatus(t, now)) : [];
  const live =
    statuses.find((s) => s.phase === "enroute") ??
    statuses.find((s) => s.phase === "boarding") ??
    statuses[0];

  const clock = now
    ? new Intl.DateTimeFormat("en-IN", {
        hour: "2-digit",
        minute: "2-digit",
        hour12: false,
        timeZone: "Asia/Kolkata",
      }).format(now)
    : "--:--";
  const dateLine = now
    ? new Intl.DateTimeFormat("en-IN", {
        weekday: "long",
        day: "numeric",
        month: "long",
        timeZone: "Asia/Kolkata",
      }).format(now)
    : "";

  return (
    <div
      ref={rootRef}
      className="relative flex h-full min-h-[440px] flex-col overflow-hidden rounded-2xl bg-gradient-to-b from-[#1a1f3a] via-midnight to-ink p-5 ring-1 ring-black/[0.05]"
    >
      {/* Dynamic Island, compact: progress ring on the left, delay on the right */}
      <div className="mx-auto flex h-[30px] w-[190px] items-center justify-between rounded-full bg-black px-1.5">
        {live && now ? <IslandGlyph progress={live.progress} late={live.delayMin > 5} moving={live.phase === "enroute"} /> : <span />}
        {live && now && (
          <span
            className="tnum pr-1.5 text-[12px] font-semibold"
            style={{ color: live.delayMin > 5 ? LATE : ON_TIME }}
          >
            {live.delayMin > 5 ? `+${fmtDuration(live.delayMin)}` : "On time"}
          </span>
        )}
      </div>

      {/* lock-screen clock, real IST */}
      <div className="mt-4 text-center">
        <div className="text-[13px] font-medium text-white/60">{dateLine || " "}</div>
        <div className="tnum mt-0.5 text-[56px] font-bold leading-none tracking-tight text-white">
          {clock}
        </div>
      </div>

      {/* the Live Activity */}
      <div className="mt-auto overflow-hidden rounded-[22px] bg-[#1C1C1E] ring-1 ring-white/[0.1]">
        {live && now ? <ActivityCard live={live} now={now} /> : <div className="h-[150px]" />}
      </div>
      <div className="mt-3 text-center text-[11px] text-white/60">
        Live Activity · running on the timetable simulation right now
      </div>
    </div>
  );
}

type Live = ReturnType<typeof getLiveStatus>;

function IslandGlyph({ progress, late, moving }: { progress: number; late: boolean; moving: boolean }) {
  const tint = late ? LATE : ON_TIME;
  const r = 9;
  const c = 2 * Math.PI * r;
  const p = Math.min(1, Math.max(0.02, progress));
  return (
    <span className="relative flex h-[22px] w-[22px] items-center justify-center">
      {moving ? (
        <svg viewBox="0 0 22 22" className="absolute inset-0 -rotate-90" aria-hidden>
          <circle cx="11" cy="11" r={r} fill="none" stroke={tint} strokeOpacity="0.3" strokeWidth="2.5" />
          <circle
            cx="11"
            cy="11"
            r={r}
            fill="none"
            stroke={tint}
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeDasharray={`${c * p} ${c}`}
          />
        </svg>
      ) : (
        <span className="absolute inset-0 rounded-full" style={{ background: tint }} />
      )}
      <TrainFront size={10} strokeWidth={2.6} className={moving ? "relative text-white" : "relative text-[#1C1C1E]"} />
    </span>
  );
}

function ActivityCard({ live, now }: { live: Live; now: Date }) {
  const { train } = live;
  const first = train.stops[0];
  const last = train.stops[train.stops.length - 1];
  const dep = live.stopTimings[0];
  const arr = live.stopTimings[live.stopTimings.length - 1];
  const departDelay = dep.delayMin;
  const arriveDelay = arr.delayMin;
  const tint = arriveDelay > 5 ? LATE : ON_TIME;
  const departTint = departDelay > 5 ? LATE : ON_TIME;
  const [mono, livery] = LIVERY[train.category];
  const dayOffset = Math.round(
    (Date.parse(istDateISO(arr.arrEst)) - Date.parse(istDateISO(dep.depEst))) / 86_400_000,
  );
  const next = train.stops[live.nextStopIdx];
  const nextAt = live.stopTimings[live.nextStopIdx]?.arrEst;
  const enroute = live.phase === "enroute";
  const progress = Math.min(1, Math.max(0, live.progress));

  let headline: React.ReactNode;
  let subline: React.ReactNode = null;
  let trailing: React.ReactNode = null;
  if (live.phase === "arrived") {
    headline = (
      <span className="flex items-center gap-1.5" style={{ color: tint }}>
        <Check size={15} strokeWidth={3} />
        <span className="text-white">Arrived at {last.name}</span>
      </span>
    );
    trailing = (
      <span className="text-[13px] font-semibold" style={{ color: tint }}>
        {delayText(arriveDelay)}
      </span>
    );
  } else if (enroute) {
    headline = (
      <>
        Arriving <span style={{ color: tint }}>{fmtRelative(arr.arrEst, now)}</span>
      </>
    );
    subline = next && nextAt && (
      <>
        Next <span className="text-white">{next.name}</span> {fmtRelative(nextAt, now)}
      </>
    );
    trailing = (
      <span className="tnum text-[12px] font-semibold" style={{ color: SUB }}>
        {live.speedKmh} km/h
      </span>
    );
  } else {
    headline = (
      <>
        Departs <span style={{ color: departTint }}>{fmtRelative(dep.depEst, now)}</span>
      </>
    );
    subline = live.statusText;
    if (first.platform) {
      trailing = (
        <span className="rounded-md bg-[#FFCC00] px-2 py-0.5 text-[13px] font-extrabold text-[#1A1400]">
          ↗ PF {first.platform}
        </span>
      );
    }
  }

  return (
    <>
      <div
        className="px-4 pb-2.5 pt-3"
        style={{ background: `linear-gradient(to bottom, ${tint}00, ${tint}3d)` }}
      >
        {/* header: livery, number, the honesty label, the app */}
        <div className="flex items-center gap-2">
          <span
            className="flex h-5 w-5 items-center justify-center rounded-full text-[9px] font-extrabold text-white"
            style={{ background: livery }}
          >
            {mono}
          </span>
          <span className="tnum text-[14px] font-semibold" style={{ color: SUB }}>
            {train.number}
          </span>
          <span
            className="rounded-full bg-white/10 px-1.5 py-px text-[10px] font-semibold"
            style={{ color: SUB }}
          >
            Estimated
          </span>
          <span className="ml-auto text-[12px] font-semibold tracking-[1.2px]" style={{ color: SUB }}>
            RAILLY
          </span>
        </div>

        {/* route row */}
        <div className="mt-2 flex items-start gap-1.5">
          <div className="min-w-0">
            <div className="flex items-baseline gap-1.5 whitespace-nowrap">
              <span className="text-[20px] font-extrabold text-white">{first.code}</span>
              <span className="tnum text-[20px] font-medium" style={{ color: departTint }}>
                {fmtTime(dep.depEst)}
              </span>
            </div>
            <div className="text-[13px] font-medium" style={{ color: departTint }}>
              {delayText(departDelay)}
            </div>
          </div>
          <div className="flex h-7 flex-1 items-center justify-center gap-1 text-white/35">
            <span className="h-[3px] w-[3px] rounded-full bg-current" />
            <span className="h-[3px] w-[3px] rounded-full bg-current" />
            <TrainFront size={13} style={{ color: SUB }} />
            <span className="h-[3px] w-[3px] rounded-full bg-current" />
            <span className="h-[3px] w-[3px] rounded-full bg-current" />
          </div>
          <div className="min-w-0 text-right">
            <div className="flex items-baseline justify-end gap-1.5 whitespace-nowrap">
              <span className="tnum text-[20px] font-medium" style={{ color: tint }}>
                {fmtTime(arr.arrEst)}
                {dayOffset > 0 && (
                  <sup className="ml-px text-[10px] font-bold">+{dayOffset}</sup>
                )}
              </span>
              <span className="text-[20px] font-extrabold text-white">{last.code}</span>
            </div>
            <div className="text-[13px] font-medium" style={{ color: tint }}>
              {delayText(arriveDelay)}
            </div>
          </div>
        </div>
      </div>

      {/* seam: the rail itself while moving, a hairline otherwise */}
      {enroute ? (
        <div className="relative mx-4 h-3">
          <div className="absolute inset-x-0 top-1/2 h-[3px] -translate-y-1/2 rounded-full bg-white/[0.16]" />
          <div
            className="absolute left-0 top-1/2 h-[3px] -translate-y-1/2 rounded-full"
            style={{ width: `${Math.max(2, progress * 100)}%`, background: tint }}
          />
          <span
            className="absolute top-1/2 flex h-3 w-3 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full"
            style={{ left: `${Math.min(97, Math.max(3, progress * 100))}%`, background: tint }}
          >
            <TrainFront size={7} strokeWidth={3} className="text-[#1C1C1E]" />
          </span>
        </div>
      ) : (
        <div className="h-px bg-white/[0.12]" />
      )}

      {/* the one line you need next */}
      <div className="flex items-center gap-2 px-4 pb-3 pt-2.5">
        <div className="min-w-0 flex-1">
          <div className="tnum truncate text-[16px] font-bold text-white">{headline}</div>
          {subline && (
            <div className="tnum truncate text-[12px] font-medium" style={{ color: SUB }}>
              {subline}
            </div>
          )}
        </div>
        {trailing}
      </div>
    </>
  );
}
