"use client";

import Link from "next/link";
import { useMemo } from "react";
import { cityFor, CATEGORY_LABEL } from "@/lib/format";
import { fmtDay, fmtDuration } from "@/lib/time";
import {
  classifyTrips,
  trainBank,
  useResolvedTrains,
  useTrips,
  type HeldTrip,
} from "@/lib/trainbank";
import type { TrainCategory } from "@/lib/types";
import { TrainMark, useNow, usePageTitle } from "../layout";

const EARTH_CIRCUMFERENCE_KM = 40_075;

function fmtInt(n: number): string {
  return Math.round(n).toLocaleString("en-IN");
}

function useLogbook(past: HeldTrip[]) {
  return useMemo(() => {
    const totalKm = past.reduce((sum, t) => sum + t.live.totalKm, 0);
    const railMin = past.reduce(
      (sum, t) => sum + t.train.stops[t.train.stops.length - 1].arrMin,
      0,
    );
    const stationCodes = new Set<string>();
    for (const t of past) for (const s of t.train.stops) stationCodes.add(s.code);
    const trainNumbers = new Set(past.map((t) => t.train.number));
    const overnight = past.filter(
      (t) =>
        t.live.arrivesEst.getUTCDate() !== t.live.departsAt.getUTCDate() ||
        t.live.arrivesEst.getTime() - t.live.departsAt.getTime() > 20 * 3_600_000,
    ).length;

    const late = past.filter((t) => t.live.delayMin > 5);
    const lostMin = past.reduce((sum, t) => sum + Math.max(0, t.live.delayMin), 0);
    const avgLate =
      late.length > 0
        ? Math.round(late.reduce((s, t) => s + t.live.delayMin, 0) / late.length)
        : 0;
    const worst = past.reduce<HeldTrip | null>(
      (w, t) => (w === null || t.live.delayMin > w.live.delayMin ? t : w),
      null,
    );

    const byCategory = new Map<TrainCategory, number>();
    for (const t of past) {
      byCategory.set(t.train.category, (byCategory.get(t.train.category) ?? 0) + 1);
    }
    let mostCat: TrainCategory | null = null;
    let mostCount = 0;
    for (const [cat, count] of byCategory) {
      if (count > mostCount) {
        mostCat = cat;
        mostCount = count;
      }
    }

    return {
      trips: past.length,
      totalKm,
      railMin,
      stations: stationCodes.size,
      trains: trainNumbers.size,
      overnight,
      lostMin,
      avgLate,
      worst,
      mostCat,
      mostCount,
    };
  }, [past]);
}

function PassportCard({ log }: { log: ReturnType<typeof useLogbook> }) {
  return (
    <div className="rounded-[24px] bg-gradient-to-br from-[#2a1052] to-[#1b2e7a] p-6">
      <div className="text-[19px] font-semibold tracking-[0.06em] text-white">
        RAILLY PASSPORT
      </div>
      <div className="mt-1 text-[12px] font-semibold uppercase tracking-[0.12em] text-[#8b7bc4]">
        Tallied from your tracked trips
      </div>

      <div className="mt-6">
        <div className="text-[13px] font-bold uppercase tracking-[0.1em] text-[#a79bd6]">
          Distance
        </div>
        <div className="tnum mt-1 text-[42px] font-extrabold leading-none text-white">
          {fmtInt(log.totalKm)}{" "}
          <span className="text-[26px] font-semibold text-[#a79bd6]">km</span>
        </div>
        <div className="mt-1 text-[15px] text-[#a79bd6]">
          {(log.totalKm / EARTH_CIRCUMFERENCE_KM).toFixed(2)}× around the world
        </div>
      </div>

      <div className="mt-6 grid grid-cols-2 gap-x-4 gap-y-5">
        <PassStat
          label="Trips"
          value={String(log.trips)}
          sub={log.overnight > 0 ? `${log.overnight} overnight` : undefined}
        />
        <PassStat label="Rail time" value={fmtDuration(log.railMin)} />
        <PassStat label="Stations" value={String(log.stations)} />
        <PassStat label="Trains" value={String(log.trains)} />
      </div>
    </div>
  );
}

function PassStat({ label, value, sub }: { label: string; value: string; sub?: string }) {
  return (
    <div>
      <div className="text-[13px] font-bold uppercase tracking-[0.1em] text-[#a79bd6]">
        {label}
      </div>
      <div className="tnum mt-0.5 text-[28px] font-bold leading-none text-white">{value}</div>
      {sub && <div className="mt-0.5 text-[14px] text-[#a79bd6]">{sub}</div>}
    </div>
  );
}

function DelayCard({ log }: { log: ReturnType<typeof useLogbook> }) {
  const worst = log.worst;
  const worstText = worst && worst.live.delayMin > 0 ? `${worst.live.delayMin}MIN` : "0MIN";
  return (
    <div className="rounded-[24px] bg-gradient-to-b from-[#140302] via-[#5a0e0e] to-[#7a1e14] p-6">
      <div className="flex gap-1.5">
        {worstText.split("").map((ch, i) => (
          <span
            key={i}
            className="split-flap h-[68px] w-[48px] text-[38px] font-bold"
            style={{ color: /[A-Z]/.test(ch) ? "rgba(255,235,220,0.3)" : "#fdf3e7" }}
          >
            {ch}
          </span>
        ))}
      </div>
      <div className="mt-5 text-[26px] font-bold text-white">Lost to Delays</div>
      <p className="mt-1 text-[15px] text-[#c98f85]">
        {log.avgLate > 0
          ? `Late trips averaged ${log.avgLate}m · ${fmtDuration(log.lostMin)} lost across tracked trips`
          : "No delays on your tracked trips yet."}
      </p>

      {worst && (
        <>
          <div className="led-board tnum mt-5 flex items-center justify-between rounded-md px-4 py-3 text-[16px] font-bold">
            <span>+{worst.live.delayMin}M</span>
            <span>{worst.train.number}</span>
            <span>
              {worst.train.stops[0].code}-
              {worst.train.stops[worst.train.stops.length - 1].code}
            </span>
          </div>
          <div className="mt-2 text-[13px] font-bold uppercase tracking-[0.1em] text-[#c98f85]">
            Worst delay
          </div>
        </>
      )}
    </div>
  );
}

function MostRiddenCard({ log }: { log: ReturnType<typeof useLogbook> }) {
  if (!log.mostCat) return null;
  return (
    <div className="rounded-[24px] bg-gradient-to-br from-[#c9c4f2] to-[#bfd3f0] p-6">
      <div className="text-[19px] font-bold text-[#2d2a66]">Most-ridden type</div>
      <div className="mt-1 text-[40px] font-extrabold leading-tight tracking-tight text-[#1f1c4d]">
        {CATEGORY_LABEL[log.mostCat]}
      </div>
      <div className="text-[15px] text-[#4b4787]">
        {log.mostCount} {log.mostCount === 1 ? "trip" : "trips"} on this class
      </div>
    </div>
  );
}

export default function LogbookPage() {
  usePageTitle("Logbook");
  const now = useNow();
  const records = useTrips();
  const numbers = useMemo(() => records.map((r) => r.number), [records]);
  const { trains } = useResolvedTrains(numbers);

  const past = useMemo(() => {
    if (!now) return [];
    const resolved = Object.fromEntries(
      Object.entries(trains).filter(([, v]) => v !== undefined),
    ) as Record<string, NonNullable<ReturnType<typeof trainBank.cached>>>;
    return classifyTrips(records, resolved, now).past;
  }, [now, trains, records]);

  const log = useLogbook(past);

  return (
    <div className="min-h-dvh bg-white px-5 pb-32 pt-8">
      <header className="flex items-center gap-3.5">
        <span className="flex h-14 w-14 items-center justify-center rounded-full bg-[#cfe3f8] text-[19px] font-bold text-[#2563ab]">
          Y
        </span>
        <div>
          <h1 className="text-[28px] font-bold leading-tight tracking-tight text-inkline">
            Logbook
          </h1>
          <p className="text-[16px] text-sub">Every completed trip you tracked</p>
        </div>
      </header>

      {!now ? (
        <div className="mt-6 space-y-4">
          {[0, 1].map((i) => (
            <div key={i} className="h-52 animate-pulse rounded-[24px] bg-fill" />
          ))}
        </div>
      ) : past.length === 0 ? (
        <p className="pt-16 text-center text-[17px] text-faded">
          Your logbook fills in as tracked trips complete.
        </p>
      ) : (
        <>
          <div className="mt-5 space-y-4">
            <PassportCard log={log} />
            <DelayCard log={log} />
            <MostRiddenCard log={log} />
          </div>

          <section className="mt-8">
            <h2 className="text-[26px] font-bold tracking-tight text-inkline">Past Trips</h2>
            <div className="mt-2 flex items-baseline justify-between border-b border-hairline pb-2">
              <span className="text-[19px] font-bold text-inkline">All time</span>
              <span className="text-[12px] font-bold uppercase tracking-[0.08em] text-faded">
                {past.length} {past.length === 1 ? "trip" : "trips"}
              </span>
            </div>
            {past.map((trip) => {
              const origin = trip.train.stops[0];
              const dest = trip.train.stops[trip.train.stops.length - 1];
              return (
                <Link
                  key={trip.id}
                  href={`/app/trip/${trip.id}`}
                  className="flex items-center gap-3 border-b border-hairline py-3.5"
                >
                  <TrainMark category={trip.train.category} size={28} />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-baseline gap-2 text-[14px] text-sub">
                      <span className="tnum">{trip.train.number}</span>
                      <span className="text-faded">
                        {origin.code} → {dest.code}
                      </span>
                      <span className="ml-auto shrink-0">{fmtDay(trip.live.arrivesEst)}</span>
                    </div>
                    <div className="truncate text-[18px] font-semibold text-inkline">
                      {cityFor(origin.code, origin.name)} to {cityFor(dest.code, dest.name)}
                    </div>
                  </div>
                </Link>
              );
            })}
          </section>

          <p className="mt-8 text-center text-[13px] text-faded">
            Stats are tallied from the trips you track here. Times are estimated from
            schedule, not a live feed.
          </p>
        </>
      )}
    </div>
  );
}
