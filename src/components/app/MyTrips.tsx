"use client";

import { Plus } from "lucide-react";
import { getMyTrips, type HeldTrip } from "@/lib/trips";
import { fmtDay } from "@/lib/time";
import { TripCard } from "./TripCard";
import { useNow } from "./useNow";

function SectionHeader({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="mb-2.5 mt-7 flex items-center gap-2 text-[11px] font-bold uppercase tracking-[1px] text-white/40">
      {children}
    </h2>
  );
}

function LiveDot() {
  return (
    <span className="relative flex h-2 w-2">
      <span className="absolute inline-flex h-full w-full animate-pulse-dot rounded-full bg-go" />
      <span className="relative inline-flex h-2 w-2 rounded-full bg-go" />
    </span>
  );
}

function Skeleton() {
  return (
    <div className="space-y-3 pt-7">
      {[0, 1, 2].map((i) => (
        <div key={i} className="h-36 animate-pulse rounded-2xl bg-cabin" />
      ))}
    </div>
  );
}

export function MyTrips() {
  const now = useNow();

  return (
    <div className="px-4 pt-14">
      <header className="flex items-center justify-between">
        <span className="flex h-9 w-9 items-center justify-center rounded-full bg-cabin2 text-sm font-bold text-white/80 ring-1 ring-white/10">
          Y
        </span>
        <h1 className="text-[34px] font-bold tracking-tight">My Trips</h1>
        <button
          aria-label="Add trip"
          className="flex h-9 w-9 items-center justify-center rounded-full bg-cabin2 text-white/80 ring-1 ring-white/10"
        >
          <Plus size={20} />
        </button>
      </header>

      {!now ? <Trips now={null} /> : <Trips now={now} />}
    </div>
  );
}

function Trips({ now }: { now: Date | null }) {
  if (!now) return <Skeleton />;

  const { live, upcoming, past } = getMyTrips(now);

  // Group upcoming journeys under Flighty-style date headers.
  const byDay = new Map<string, HeldTrip[]>();
  for (const trip of upcoming) {
    const key = fmtDay(trip.live.departsAt);
    byDay.set(key, [...(byDay.get(key) ?? []), trip]);
  }

  return (
    <div>
      {live.length > 0 && (
        <section>
          <SectionHeader>
            <LiveDot />
            Live now
          </SectionHeader>
          <div className="space-y-3">
            {live.map((trip) => (
              <TripCard key={trip.id} trip={trip} now={now} />
            ))}
          </div>
        </section>
      )}

      {[...byDay.entries()].map(([day, trips]) => (
        <section key={day}>
          <SectionHeader>{day}</SectionHeader>
          <div className="space-y-3">
            {trips.map((trip) => (
              <TripCard key={trip.id} trip={trip} now={now} />
            ))}
          </div>
        </section>
      ))}

      {past.length > 0 && (
        <section>
          <SectionHeader>Past trips</SectionHeader>
          <div className="space-y-3">
            {past.map((trip) => (
              <TripCard key={trip.id} trip={trip} now={now} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
