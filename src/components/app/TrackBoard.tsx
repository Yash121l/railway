"use client";

import { getLiveStatus } from "@/lib/sim";
import { TRAINS } from "@/lib/trains";
import { liveTripFor } from "@/lib/trips";
import type { LiveStatus } from "@/lib/types";
import { TripRow } from "./TripRow";
import { useNow } from "./useNow";

const PHASE_RANK: Record<LiveStatus["phase"], number> = {
  enroute: 0,
  boarding: 1,
  scheduled: 2,
  arrived: 3,
};

export function TrackBoard() {
  const now = useNow();

  return (
    <div className="min-h-dvh bg-white px-5 pb-32 pt-12">
      <header className="flex items-baseline justify-between">
        <h1 className="text-[32px] font-extrabold tracking-tight text-inkline">
          Track
        </h1>
        {now && <RunningCount now={now} />}
      </header>
      <p className="mt-1 text-[15px] text-sub">
        Every train Railly is watching right now.
      </p>

      {!now ? (
        <div className="mt-6 space-y-4">
          {[0, 1, 2, 3].map((i) => (
            <div key={i} className="h-24 animate-pulse rounded-2xl bg-fill" />
          ))}
        </div>
      ) : (
        <Board now={now} />
      )}
    </div>
  );
}

function RunningCount({ now }: { now: Date }) {
  const running = TRAINS.filter(
    (t) => getLiveStatus(t, now).phase === "enroute",
  ).length;
  return (
    <span className="flex items-center gap-1.5 text-[14px] font-bold text-ontime">
      <span className="h-2 w-2 animate-pulse-dot rounded-full bg-ontime" />
      {running} running
    </span>
  );
}

function Board({ now }: { now: Date }) {
  const trips = TRAINS.map((t) => liveTripFor(t, now)).sort((a, b) => {
    const rank = PHASE_RANK[a.live.phase] - PHASE_RANK[b.live.phase];
    if (rank !== 0) return rank;
    return a.live.departsAt.getTime() - b.live.departsAt.getTime();
  });

  return (
    <div className="mt-2">
      {trips.map((trip, i) => (
        <TripRow
          key={trip.id}
          trip={trip}
          now={now}
          divider={i < trips.length - 1}
        />
      ))}
    </div>
  );
}
