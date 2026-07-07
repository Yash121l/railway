"use client";

import { useState } from "react";
import { ChevronDown, Search, Share } from "lucide-react";
import { getMyTrips, liveTripFor, type HeldTrip } from "@/lib/trips";
import { TRAINS } from "@/lib/trains";
import { NetworkMap } from "./NetworkMap";
import { TripRow } from "./TripRow";
import { useNow } from "./useNow";

function Skeleton() {
  return (
    <div className="space-y-5 pt-5">
      {[0, 1, 2].map((i) => (
        <div key={i} className="flex gap-3">
          <div className="h-14 w-[72px] animate-pulse rounded-2xl bg-fill" />
          <div className="flex-1 space-y-2">
            <div className="h-4 w-1/3 animate-pulse rounded bg-fill" />
            <div className="h-6 w-2/3 animate-pulse rounded bg-fill" />
            <div className="h-4 w-full animate-pulse rounded bg-fill" />
          </div>
        </div>
      ))}
    </div>
  );
}

function SearchResults({ query, now }: { query: string; now: Date }) {
  const q = query.trim().toLowerCase();
  const matches = TRAINS.filter(
    (t) =>
      t.number.includes(q) ||
      t.name.toLowerCase().includes(q) ||
      t.stops.some(
        (s) => s.name.toLowerCase().includes(q) || s.code.toLowerCase() === q,
      ),
  ).slice(0, 6);

  if (matches.length === 0) {
    return (
      <p className="pt-10 text-center text-[17px] text-faded">
        No trains match &ldquo;{query}&rdquo;
      </p>
    );
  }
  return (
    <div>
      <SectionHeader>Trains</SectionHeader>
      {matches.map((train, i) => (
        <TripRow
          key={train.number}
          trip={liveTripFor(train, now)}
          now={now}
          divider={i < matches.length - 1}
        />
      ))}
    </div>
  );
}

function SectionHeader({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="mt-6 text-[20px] font-bold tracking-tight text-inkline">
      {children}
    </h2>
  );
}

function Sections({ now }: { now: Date }) {
  const { live, upcoming, past } = getMyTrips(now);
  const current: HeldTrip[] = [...live, ...upcoming];

  return (
    <div>
      <div>
        {current.map((trip, i) => (
          <TripRow
            key={trip.id}
            trip={trip}
            now={now}
            divider={i < current.length - 1}
          />
        ))}
      </div>

      {past.length > 0 && (
        <>
          <SectionHeader>Past Trips</SectionHeader>
          {past.map((trip, i) => (
            <TripRow
              key={trip.id}
              trip={trip}
              now={now}
              divider={i < past.length - 1}
            />
          ))}
        </>
      )}
    </div>
  );
}

export function MyTrips() {
  const now = useNow();
  const [query, setQuery] = useState("");

  return (
    <div className="relative min-h-dvh bg-black pt-[38vh]">
      {/* maplibre forces position:relative on its own container, so the
          absolute positioning lives on this wrapper; padding (not a sheet
          margin) keeps the offset from collapsing through the root */}
      <div className="absolute inset-x-0 top-0 h-[46vh]">
        <NetworkMap className="h-full w-full" />
      </div>

      {/* the sheet */}
      <div className="relative z-10 min-h-[62vh] rounded-t-[36px] bg-white px-5 pb-32 pt-6 shadow-[0_-16px_50px_rgba(0,0,0,0.45)]">
        <header className="flex items-center justify-between">
          <h1 className="flex items-center gap-1.5 text-[32px] font-extrabold tracking-tight text-inkline">
            My Trips
            <ChevronDown size={20} strokeWidth={3} className="mt-1 text-inkline" />
          </h1>
          <div className="flex items-center gap-2.5">
            <button
              aria-label="Share Railly"
              onClick={() => {
                const url = window.location.origin;
                if (navigator.share) {
                  navigator
                    .share({ title: "Railly", text: "Track trains like flights", url })
                    .catch(() => {});
                } else {
                  navigator.clipboard?.writeText(url);
                }
              }}
              className="flex h-11 w-11 items-center justify-center rounded-full bg-fill text-inkline"
            >
              <Share size={18} />
            </button>
            <span className="flex h-11 w-11 items-center justify-center rounded-full bg-fill text-[15px] font-bold text-sub">
              Y
            </span>
          </div>
        </header>

        <div className="mt-4 flex h-14 items-center gap-2.5 rounded-2xl bg-fill px-4">
          <Search size={20} className="shrink-0 text-faded" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search to add trains"
            className="h-full w-full bg-transparent text-[17px] text-inkline outline-none placeholder:text-faded"
          />
        </div>

        {!now ? (
          <Skeleton />
        ) : query.trim() ? (
          <SearchResults query={query} now={now} />
        ) : (
          <Sections now={now} />
        )}
      </div>
    </div>
  );
}
