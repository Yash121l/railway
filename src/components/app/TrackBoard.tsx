"use client";

import Link from "next/link";
import { ChevronRight } from "lucide-react";
import { cityFor } from "@/lib/format";
import { getLiveStatus } from "@/lib/sim";
import { fmtTime } from "@/lib/time";
import { TRAINS } from "@/lib/trains";
import { tripId } from "@/lib/trips";
import type { LiveStatus } from "@/lib/types";
import { StatusPill } from "./StatusPill";
import { TrainMark } from "./TrainMark";
import { useNow } from "./useNow";

/** One line per train — the whole network as a departure board. */
function BoardRow({ live }: { live: LiveStatus }) {
  const { train } = live;
  const origin = train.stops[0];
  const dest = train.stops[train.stops.length - 1];
  const running = live.phase === "enroute";

  return (
    <Link
      href={`/app/trip/${tripId(train.number, live.runDate)}`}
      className="block rounded-2xl bg-cabin px-4 py-3.5 ring-1 ring-white/[0.06] transition-transform active:scale-[0.985]"
    >
      <div className="flex items-center gap-3">
        <TrainMark category={train.category} size={30} />
        <div className="min-w-0 flex-1">
          <div className="flex items-baseline gap-2">
            <span className="tnum text-[14px] font-bold">{train.number}</span>
            <span className="truncate text-[13px] text-white/55">
              {cityFor(origin.code, origin.name)} → {cityFor(dest.code, dest.name)}
            </span>
          </div>
          <div className="mt-0.5 text-[12px] text-white/40">
            {running
              ? live.atStation
                ? `At ${train.stops[live.prevStopIdx].name}`
                : `${live.speedKmh} km/h · next ${train.stops[live.nextStopIdx]?.name}`
              : live.phase === "arrived"
                ? `Arrived ${fmtTime(live.arrivesEst)}`
                : `Departs ${fmtTime(live.departsAt)}`}
          </div>
        </div>
        <StatusPill tone={live.tone} text={live.statusText} />
        <ChevronRight size={16} className="shrink-0 text-white/30" />
      </div>
      {running && (
        <div className="mt-3 h-[3px] w-full rounded-full bg-white/10">
          <div
            className="h-full rounded-full bg-flame"
            style={{ width: `${live.progress * 100}%` }}
          />
        </div>
      )}
    </Link>
  );
}

export function TrackBoard() {
  const now = useNow();

  return (
    <div className="px-4 pt-14">
      <header className="flex items-baseline justify-between">
        <h1 className="text-[34px] font-bold tracking-tight">Track</h1>
        {now && <NetworkSummary now={now} />}
      </header>
      <p className="mt-1 text-[13px] text-white/45">
        Every train Railly is watching right now.
      </p>

      {!now ? (
        <div className="mt-6 space-y-3">
          {[0, 1, 2, 3].map((i) => (
            <div key={i} className="h-20 animate-pulse rounded-2xl bg-cabin" />
          ))}
        </div>
      ) : (
        <Board now={now} />
      )}
    </div>
  );
}

function NetworkSummary({ now }: { now: Date }) {
  const running = TRAINS.filter(
    (t) => getLiveStatus(t, now).phase === "enroute",
  ).length;
  return (
    <span className="flex items-center gap-1.5 text-[12px] font-semibold text-go">
      <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-go" />
      {running} running
    </span>
  );
}

function Board({ now }: { now: Date }) {
  const statuses = TRAINS.map((t) => getLiveStatus(t, now)).sort((a, b) => {
    const rank = (s: LiveStatus) =>
      s.phase === "enroute" ? 0 : s.phase === "boarding" ? 1 : s.phase === "scheduled" ? 2 : 3;
    if (rank(a) !== rank(b)) return rank(a) - rank(b);
    return a.departsAt.getTime() - b.departsAt.getTime();
  });

  return (
    <div className="mt-6 space-y-3">
      {statuses.map((live) => (
        <BoardRow key={live.train.number} live={live} />
      ))}
    </div>
  );
}
