"use client";

import { useEffect, useState } from "react";
import { TrainFront } from "lucide-react";
import { getLiveStatus } from "@/lib/sim";
import { fmtTime } from "@/lib/time";
import { TRAINS } from "@/lib/trains";

/**
 * A lock screen running the Railly Live Activity — and it isn't a mock-up:
 * the clock is IST now, and the train, its progress bar, times and speed
 * come from whichever service the simulation actually has on rails at this
 * second. Leave the page open and the little train crawls to Delhi.
 */
export function LiveActivityMock() {
  // render nothing time-dependent on the server; hydrate, then tick
  const [now, setNow] = useState<Date | null>(null);

  useEffect(() => {
    const raf = requestAnimationFrame(() => setNow(new Date()));
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return () => cancelAnimationFrame(raf);
    }
    const id = setInterval(() => setNow(new Date()), 1000);
    return () => {
      cancelAnimationFrame(raf);
      clearInterval(id);
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

  const late = (live?.delayMin ?? 0) > 5;
  const next = live ? live.train.stops[live.nextStopIdx] : undefined;

  return (
    <div className="relative flex h-full min-h-[420px] flex-col overflow-hidden rounded-2xl bg-gradient-to-b from-[#1a1f3a] via-midnight to-ink p-6 ring-1 ring-black/[0.05]">
      {/* lock-screen clock — real IST */}
      <div className="text-center">
        <div className="text-[13px] font-medium text-white/60">{dateLine || " "}</div>
        <div className="tnum mt-0.5 text-[56px] font-bold leading-none tracking-tight text-white">
          {clock}
        </div>
      </div>

      {/* the Live Activity */}
      <div className="mt-auto rounded-[22px] bg-black/55 p-4 ring-1 ring-white/[0.12] backdrop-blur-xl">
        {live ? (
          <>
            <div className="flex items-center gap-2.5">
              <span className="flex h-8 w-8 items-center justify-center rounded-full bg-white/[0.12]">
                <TrainFront size={15} className="text-white" />
              </span>
              <div className="min-w-0 flex-1">
                <div className="truncate text-[14px] font-semibold text-white">
                  {live.train.number} · {live.train.name}
                </div>
                <div className="text-[11px] text-white/55">
                  {live.phase === "enroute"
                    ? `${live.speedKmh} km/h · next ${next?.name ?? "—"}`
                    : live.statusText}
                </div>
              </div>
              <span
                className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-bold ${
                  late ? "bg-latered/25 text-[#ff8d7f]" : "bg-ontime/25 text-[#5fd68b]"
                }`}
              >
                {late ? `+${live.delayMin}m` : "On Time"}
              </span>
            </div>

            <div className="mt-4 flex items-center gap-3">
              <div className="text-left">
                <div className="text-[15px] font-bold text-white">
                  {live.train.stops[0].code}
                </div>
                <div className="tnum text-[12px] text-white/55">
                  {fmtTime(live.stopTimings[0].depEst)}
                </div>
              </div>
              <div className="relative h-[3px] flex-1 rounded-full bg-white/[0.14]">
                <div
                  className="absolute inset-y-0 left-0 rounded-full bg-arc"
                  style={{ width: `${Math.max(3, live.progress * 100)}%` }}
                />
                <span
                  className="absolute top-1/2 h-2.5 w-2.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white shadow-[0_0_8px_rgba(77,159,255,0.9)]"
                  style={{ left: `${Math.max(3, live.progress * 100)}%` }}
                />
              </div>
              <div className="text-right">
                <div className="text-[15px] font-bold text-white">
                  {live.train.stops[live.train.stops.length - 1].code}
                </div>
                <div
                  className={`tnum text-[12px] font-semibold ${
                    late ? "text-[#ff8d7f]" : "text-[#5fd68b]"
                  }`}
                >
                  {fmtTime(live.stopTimings[live.stopTimings.length - 1].arrEst)}
                </div>
              </div>
            </div>
          </>
        ) : (
          <div className="h-[92px]" />
        )}
      </div>
      <div className="mt-3 text-center text-[11px] text-white/40">
        Live Activity · this is the real simulation, right now
      </div>
    </div>
  );
}
