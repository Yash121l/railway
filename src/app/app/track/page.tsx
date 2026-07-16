"use client";

import { useMemo } from "react";
import {
  liveHeldTrip,
  trainBank,
  useResolvedTrains,
  useTrips,
  type HeldTrip,
} from "@/lib/trainbank";
import type { LiveStatus } from "@/lib/types";
import { TripRow, useNow, usePageTitle } from "../layout";

const PHASE_RANK: Record<LiveStatus["phase"], number> = {
  enroute: 0,
  boarding: 1,
  scheduled: 2,
  arrived: 3,
};

export default function TrackPage() {
  usePageTitle("Track");
  const now = useNow();
  const records = useTrips();

  const watchNumbers = useMemo(() => {
    const seeds = trainBank.seeds().map((t) => t.number);
    return Array.from(new Set([...seeds, ...records.map((r) => r.number)]));
  }, [records]);

  const { trains } = useResolvedTrains(watchNumbers);

  const board: HeldTrip[] = useMemo(() => {
    if (!now) return [];
    const rows = Object.values(trains)
      .filter((t): t is NonNullable<typeof t> => t !== undefined)
      .map((train) => liveHeldTrip(train, now));
    return rows.sort((a, b) => {
      const rank = PHASE_RANK[a.live.phase] - PHASE_RANK[b.live.phase];
      if (rank !== 0) return rank;
      return a.live.departsAt.getTime() - b.live.departsAt.getTime();
    });
  }, [now, trains]);

  const running = board.filter((t) => t.live.phase === "enroute").length;

  return (
    <div className="min-h-dvh bg-white px-5 pb-32 pt-8">
      <header className="flex items-baseline justify-between">
        <h1 className="text-[32px] font-extrabold tracking-tight text-inkline">Track</h1>
        {now && (
          <span className="flex items-center gap-1.5 text-[14px] font-bold text-ontime">
            <span className="h-2 w-2 animate-pulse-dot rounded-full bg-ontime" />
            {running} running
          </span>
        )}
      </header>
      <p className="mt-1 text-[15px] text-sub">
        Every train Railly is watching right now — positions estimated from schedule.
      </p>

      {!now || board.length === 0 ? (
        <div className="mt-6 space-y-4">
          {[0, 1, 2, 3].map((i) => (
            <div key={i} className="h-24 animate-pulse rounded-2xl bg-fill" />
          ))}
        </div>
      ) : (
        <div className="mt-2">
          {board.map((trip, i) => (
            <TripRow key={trip.id} trip={trip} now={now} divider={i < board.length - 1} />
          ))}
        </div>
      )}
    </div>
  );
}
