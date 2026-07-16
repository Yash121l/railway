"use client";

import { useEffect, useMemo, useState } from "react";
import { ChevronDown, Loader2, Plus, Search, Share } from "lucide-react";
import { searchTrains, type CatalogTrain } from "@/lib/catalog";
import { CATEGORY_LABEL } from "@/lib/format";
import {
  classifyTrips,
  liveHeldTrip,
  trainBank,
  tripStore,
  useResolvedTrains,
  useTrips,
  type HeldTrip,
} from "@/lib/trainbank";
import {
  EstimateBadge,
  NetworkMap,
  TrainMark,
  TripRow,
  useNow,
  usePageTitle,
} from "./layout";

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

function SectionHeader({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="mt-6 text-[20px] font-bold tracking-tight text-inkline">{children}</h2>
  );
}

function SearchResults({
  query,
  heldIds,
  onAdd,
  addingNumber,
}: {
  query: string;
  heldIds: Set<string>;
  onAdd: (train: CatalogTrain) => void;
  addingNumber: string | null;
}) {
  const matches = useMemo(() => searchTrains(query, 10), [query]);

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
      <p className="mt-0.5 text-[13px] text-faded">
        Searching all 4,022 trains in the offline catalog
      </p>
      <div className="mt-2">
        {matches.map((t, i) => {
          const held = [...heldIds].some((id) => id.startsWith(`${t.number}_`));
          const busy = addingNumber === t.number;
          return (
            <div
              key={t.number}
              className={`flex items-center gap-3 py-3.5 ${
                i < matches.length - 1 ? "border-b border-hairline" : ""
              }`}
            >
              <TrainMark category={t.category} size={34} />
              <div className="min-w-0 flex-1">
                <div className="flex items-baseline gap-2 text-[14px] text-sub">
                  <span className="tnum">{t.number}</span>
                  <span className="text-faded">{CATEGORY_LABEL[t.category]}</span>
                </div>
                <div className="truncate text-[17px] font-semibold text-inkline">{t.name}</div>
              </div>
              <button
                aria-label={`Add ${t.number}`}
                disabled={busy || held}
                onClick={() => onAdd(t)}
                className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-action text-white disabled:opacity-40"
              >
                {busy ? (
                  <Loader2 size={18} className="animate-spin" />
                ) : held ? (
                  <span className="text-[11px] font-bold">✓</span>
                ) : (
                  <Plus size={18} />
                )}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function Sections({
  now,
  trains,
}: {
  now: Date;
  trains: Record<string, ReturnType<typeof trainBank.cached>>;
}) {
  const records = useTrips();
  const resolved = Object.fromEntries(
    Object.entries(trains).filter(([, v]) => v !== undefined),
  ) as Record<string, NonNullable<ReturnType<typeof trainBank.cached>>>;
  const { live, upcoming, past } = classifyTrips(records, resolved, now);
  const current: HeldTrip[] = [...live, ...upcoming];

  if (current.length === 0 && past.length === 0) {
    return (
      <p className="pt-10 text-center text-[17px] text-faded">
        No trips yet — search above to track any of India&apos;s 4,022 trains.
      </p>
    );
  }

  return (
    <div>
      <div>
        {current.map((trip, i) => (
          <TripRow key={trip.id} trip={trip} now={now} divider={i < current.length - 1} />
        ))}
      </div>
      {past.length > 0 && (
        <>
          <SectionHeader>Past Trips</SectionHeader>
          {past.map((trip, i) => (
            <TripRow key={trip.id} trip={trip} now={now} divider={i < past.length - 1} />
          ))}
        </>
      )}
    </div>
  );
}

export default function AppHome() {
  usePageTitle("My Trips");
  const now = useNow();
  const records = useTrips();
  const [query, setQuery] = useState("");
  const [addingNumber, setAddingNumber] = useState<string | null>(null);

  // First visit: seed the preview from the popular trains' live/next/recent runs.
  useEffect(() => {
    tripStore.seedIfEmpty(new Date());
  }, []);

  const numbers = useMemo(() => records.map((r) => r.number), [records]);
  const { trains } = useResolvedTrains(numbers);

  const heldIds = useMemo(
    () => new Set(records.map((r) => `${r.number}_${r.runDate}`)),
    [records],
  );

  const mapTrips = useMemo(() => {
    if (!now) return [];
    const resolved = Object.fromEntries(
      Object.entries(trains).filter(([, v]) => v !== undefined),
    ) as Record<string, NonNullable<ReturnType<typeof trainBank.cached>>>;
    const { live, upcoming } = classifyTrips(records, resolved, now);
    return [...live, ...upcoming];
  }, [now, trains, records]);

  const addTrain = (t: CatalogTrain) => {
    setAddingNumber(t.number);
    trainBank
      .resolve(t.number)
      .then((train) => {
        const preview = liveHeldTrip(train, new Date());
        tripStore.add(train.number, preview.live.runDate);
        setQuery("");
      })
      .catch(() => {
        // leave the search open; the row simply won't add
      })
      .finally(() => setAddingNumber(null));
  };

  return (
    <div className="relative min-h-dvh bg-black pt-[36vh]">
      <div className="absolute inset-x-0 top-0 h-[44vh]">
        <NetworkMap trips={mapTrips} className="h-full w-full" />
        <div className="pointer-events-none absolute inset-x-0 bottom-0 h-24 bg-gradient-to-b from-transparent to-black/40" />
        <EstimateBadge className="absolute left-4 top-3" />
      </div>

      <div className="relative z-10 min-h-[64vh] rounded-t-[36px] bg-white px-5 pb-32 pt-6 shadow-[0_-16px_50px_rgba(0,0,0,0.45)]">
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
                  navigator.share({ title: "Railly", text: "Track trains like flights", url }).catch(() => {});
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
          <SearchResults
            query={query.trim()}
            heldIds={heldIds}
            onAdd={addTrain}
            addingNumber={addingNumber}
          />
        ) : (
          <Sections now={now} trains={trains} />
        )}
      </div>
    </div>
  );
}
