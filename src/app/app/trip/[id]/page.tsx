"use client";

import Link from "next/link";
import { use, useMemo, useState } from "react";
import {
  ArrowDownRight,
  ArrowUpRight,
  Armchair,
  Bell,
  BellOff,
  Clock,
  Moon,
  Share,
  Sparkles,
  Ticket,
  Trash2,
  X,
} from "lucide-react";
import { CATEGORY_LABEL, cityFor } from "@/lib/format";
import { fmtDay, fmtDuration, fmtTime, istDateISO } from "@/lib/time";
import {
  heldTripForRun,
  parseTripId,
  tripStore,
  useResolvedTrain,
  useTrips,
  type HeldTrip,
} from "@/lib/trainbank";
import type { LiveStatus } from "@/lib/types";
import {
  EstimateBadge,
  RouteMap,
  TrainMark,
  useNow,
  usePageTitle,
} from "../../layout";

const ontimeOrLate = (delayMin: number) =>
  delayMin > 5 ? "text-latered" : "text-ontime";

function Card({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={`rounded-[20px] border border-[#ececee] bg-white p-5 ${className}`}>{children}</div>
  );
}

function CardTitle({ title, sub }: { title: string; sub?: string }) {
  return (
    <div className="mb-4">
      <h3 className="text-[21px] font-bold tracking-tight text-inkline">{title}</h3>
      {sub && <p className="mt-0.5 text-[14px] text-sub">{sub}</p>}
    </div>
  );
}

function StatusBanner({ live, now }: { live: LiveStatus; now: Date }) {
  const late = live.delayMin > 5;
  const dest = live.train.stops[live.train.stops.length - 1];
  const destCity = cityFor(dest.code, dest.name);
  const origin = live.train.stops[0];
  const originCity = cityFor(origin.code, origin.name);

  let headline: React.ReactNode;
  let detail: string;
  if (live.phase === "enroute") {
    const remaining = Math.max(0, (live.arrivesEst.getTime() - now.getTime()) / 60_000);
    headline = (
      <>
        Arriving in{" "}
        <span className={`font-bold ${ontimeOrLate(live.delayMin)}`}>{fmtDuration(remaining)}</span>
      </>
    );
    detail = late
      ? `Estimated ~${live.delayMin}m behind schedule — reaches ${destCity} around ${fmtTime(live.arrivesEst)}`
      : `On schedule — estimated into ${destCity} at ${fmtTime(live.arrivesEst)}`;
  } else if (live.phase === "boarding") {
    const depEst = live.stopTimings[0].depEst;
    const toDep = Math.max(0, (depEst.getTime() - now.getTime()) / 60_000);
    headline = (
      <>
        Departure in{" "}
        <span className={`font-bold ${ontimeOrLate(live.delayMin)}`}>{fmtDuration(toDep)}</span>
      </>
    );
    const pf = origin.platform;
    detail = `Boarding${pf ? ` from PF ${pf}` : ""} — estimated departure ${fmtTime(depEst)}`;
  } else if (live.phase === "scheduled") {
    const toDep = Math.max(0, (live.stopTimings[0].depEst.getTime() - now.getTime()) / 60_000);
    headline = (
      <>
        Departs in{" "}
        <span className={`font-bold ${ontimeOrLate(live.delayMin)}`}>{fmtDuration(toDep)}</span>
      </>
    );
    detail = late
      ? `Estimated ~${live.delayMin}m late start from ${originCity}`
      : `Scheduled ${fmtTime(live.departsAt)} from ${originCity}`;
  } else {
    headline = (
      <>
        Arrived{" "}
        <span className={`font-bold ${ontimeOrLate(live.delayMin)}`}>
          {late ? `${live.delayMin}m late` : "on time"}
        </span>
      </>
    );
    detail = `Estimated into ${destCity} at ${fmtTime(live.arrivesEst)}`;
  }

  return (
    <div className={`px-5 py-3.5 ${late ? "bg-[#fbf0ee]" : "bg-[#f2f8f4]"}`}>
      <p className="text-[18px] font-semibold text-inkline">{headline}</p>
      <p className="mt-0.5 text-[15px] leading-snug text-[#374151]">{detail}</p>
    </div>
  );
}

function EndBlock({ trip, end }: { trip: HeldTrip; end: "dep" | "arr" }) {
  const { live, train } = trip;
  const idx = end === "dep" ? 0 : train.stops.length - 1;
  const stop = train.stops[idx];
  const timing = live.stopTimings[idx];
  const sched = end === "dep" ? timing.depSched : timing.arrSched;
  const est = end === "dep" ? timing.depEst : timing.arrEst;
  const late = timing.delayMin > 5;
  const isPast =
    end === "dep"
      ? live.phase === "enroute" || live.phase === "arrived"
      : live.phase === "arrived";
  const Arrow = end === "dep" ? ArrowUpRight : ArrowDownRight;

  return (
    <div className="flex items-start justify-between gap-4 py-4">
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <span className="flex h-[22px] w-[22px] items-center justify-center rounded-full bg-inkline">
            <Arrow size={14} strokeWidth={3} className="text-white" />
          </span>
          <span className="truncate text-[15px] font-semibold text-inkline">
            {stop.code} · {stop.name}
          </span>
        </div>
        <div className="mt-1.5 flex items-baseline gap-2.5">
          <span
            className={`tnum text-[38px] font-extrabold leading-none tracking-tight ${
              isPast && !late ? "text-ontime" : ontimeOrLate(timing.delayMin)
            }`}
          >
            {fmtTime(est)}
          </span>
          {late && <span className="tnum text-[15px] text-faded line-through">{fmtTime(sched)}</span>}
        </div>
        <p className="mt-1.5 text-[14px]">
          <span className={`font-semibold ${ontimeOrLate(timing.delayMin)}`}>
            {late ? `Est. ${timing.delayMin}m late` : "On schedule"}
          </span>
          <span className="text-sub"> • {fmtDay(est)}</span>
        </p>
      </div>
      <div className="shrink-0 text-right">
        <span className="inline-block rounded-[10px] bg-gate px-3 py-1.5 text-[19px] font-bold text-black">
          {stop.platform ? `PF ${stop.platform}` : "PF --"}
        </span>
        <p className="mt-1.5 text-[13px] text-sub">Platform</p>
      </div>
    </div>
  );
}

function MetaDivider({ live }: { live: LiveStatus }) {
  const { train } = live;
  const journeyMin = train.stops[train.stops.length - 1].arrMin;
  const overnight = istDateISO(live.arrivesSched) !== istDateISO(live.departsAt);
  return (
    <div className="flex items-center gap-2 text-[13px] text-faded">
      <Clock size={13} />
      <span>{fmtDuration(journeyMin)}</span>
      <span>•</span>
      <span>{Math.round(live.totalKm)} km</span>
      {overnight && (
        <>
          <span>•</span>
          <Moon size={13} />
          <span>Overnight</span>
        </>
      )}
      <span className="ml-1 h-px flex-1 bg-hairline" />
    </div>
  );
}

function LiveRun({ live, now }: { live: LiveStatus; now: Date }) {
  const hereIdx = live.atStation ? live.prevStopIdx : live.nextStopIdx;
  const hereStop = live.train.stops[hereIdx];
  const hereTiming = live.stopTimings[hereIdx];
  const hereTime = live.atStation ? hereTiming.depEst : hereTiming.arrEst;
  const remaining = Math.max(0, (live.arrivesEst.getTime() - now.getTime()) / 60_000);
  const stats: [string, string][] = [
    ["Covered", `${Math.round(live.progressKm)} km`],
    ["Speed", `${live.speedKmh} km/h`],
    ["To go", fmtDuration(remaining)],
  ];
  return (
    <Card>
      <CardTitle
        title="Live Run"
        sub={`Estimated from schedule · ${Math.round(live.progress * 100)}% of ${Math.round(live.totalKm)} km`}
      />
      <div className="h-2 w-full overflow-hidden rounded-full bg-fill">
        <div className="h-full rounded-full bg-arc" style={{ width: `${live.progress * 100}%` }} />
      </div>
      <div className="mt-4 grid grid-cols-3">
        {stats.map(([label, value]) => (
          <div key={label}>
            <div className="text-[14px] text-sub">{label}</div>
            <div className="tnum mt-0.5 text-[19px] font-semibold text-inkline">{value}</div>
          </div>
        ))}
      </div>
      <div className="mt-4 flex items-center justify-between border-t border-hairline pt-3.5 text-[15px]">
        <span className="text-sub">
          {live.atStation ? "At" : "Next"}{" "}
          <span className="font-semibold text-inkline">{hereStop?.name}</span>
          {live.atStation && <span className="text-sub"> · departs</span>}
        </span>
        <span className={`tnum font-bold ${ontimeOrLate(hereTiming.delayMin)}`}>{fmtTime(hereTime)}</span>
      </div>
    </Card>
  );
}

function Timetable({ live }: { live: LiveStatus }) {
  const stops = live.train.stops;
  return (
    <Card>
      <CardTitle title="Detailed Timetable" sub="Scheduled vs. estimated for every halt" />
      <div className="mb-2 flex items-baseline justify-end gap-0 text-[13px] text-faded">
        <span className="w-[76px] text-right">Scheduled</span>
        <span className="w-[76px] text-right">Estimated</span>
      </div>
      <ul className="space-y-3">
        {stops.map((stop, i) => {
          const t = live.stopTimings[i];
          const isFirst = i === 0;
          const sched = isFirst ? t.depSched : t.arrSched;
          const est = isFirst ? t.depEst : t.arrEst;
          const dimmed = t.passed && !t.current;
          return (
            <li key={`${stop.code}-${i}`} className={`flex items-baseline ${dimmed ? "opacity-45" : ""}`}>
              <div className="min-w-0 flex-1">
                <span className="text-[16px] text-inkline">
                  {stop.name}
                  {t.current && (
                    <span className="ml-2 text-[12px] font-bold uppercase tracking-wide text-arc">Here</span>
                  )}
                </span>
                <span className="ml-2 text-[12px] text-faded">
                  {stop.platform ? `PF ${stop.platform}` : stop.code}
                </span>
              </div>
              <span className="tnum w-[76px] text-right text-[16px] text-inkline">{fmtTime(sched)}</span>
              <span className={`tnum w-[76px] text-right text-[16px] font-semibold ${ontimeOrLate(t.delayMin)}`}>
                {fmtTime(est)}
              </span>
            </li>
          );
        })}
      </ul>
    </Card>
  );
}

function BookingTiles({ trip }: { trip: HeldTrip }) {
  const [copied, setCopied] = useState(false);
  if (!trip.booking) return null;
  const { pnr, coach, seat } = trip.booking;
  return (
    <div className="grid grid-cols-2 gap-3">
      <div className="rounded-[16px] border border-hairline p-4">
        <div className="flex items-start justify-between">
          <Ticket size={20} className="text-inkline" />
          <button
            onClick={() => {
              navigator.clipboard?.writeText(pnr);
              setCopied(true);
              setTimeout(() => setCopied(false), 1500);
            }}
            className="rounded-md bg-[#e8f1fe] px-2 py-0.5 text-[11px] font-bold text-[#1d6fe0]"
          >
            {copied ? "COPIED" : "COPY"}
          </button>
        </div>
        <div className="tnum mt-3 text-[19px] font-bold text-inkline">{pnr}</div>
        <div className="mt-0.5 text-[14px] text-faded">PNR</div>
      </div>
      <div className="rounded-[16px] border border-hairline p-4">
        <Armchair size={20} className="text-inkline" />
        <div className="mt-3 text-[19px] font-bold text-inkline">
          {coach} · {seat}
        </div>
        <div className="mt-0.5 text-[14px] text-faded">Coach &amp; berth</div>
      </div>
    </div>
  );
}

function GoodToKnow({ train, totalKm }: { train: HeldTrip["train"]; totalKm: number }) {
  const rows: [string, string][] = [
    ["Halts", `${Math.max(0, train.stops.length - 2)} intermediate stations`],
    ["Runs", train.days.length === 7 ? "Daily" : train.days.join(" · ")],
    ["Classes", train.classes.length > 0 ? train.classes.join(" · ") : "See IRCTC"],
    ["Distance", `${Math.round(totalKm)} km`],
  ];
  return (
    <Card>
      <CardTitle title="Good to Know" />
      <div className="space-y-2.5">
        {rows.map(([label, value]) => (
          <div key={label} className="flex items-baseline justify-between gap-4">
            <span className="text-[15px] text-sub">{label}</span>
            <span className="text-right text-[15px] font-semibold text-inkline">{value}</span>
          </div>
        ))}
      </div>
    </Card>
  );
}

function DetailSkeleton() {
  return (
    <div className="bg-white px-5 pt-6">
      <div className="h-[300px] animate-pulse rounded-[20px] bg-fill" />
      <div className="mt-5 h-24 animate-pulse rounded-[20px] bg-fill" />
      <div className="mt-5 h-60 animate-pulse rounded-[20px] bg-fill" />
    </div>
  );
}

function NotFound({ message }: { message: string }) {
  return (
    <div className="bg-white px-6 pt-32 text-center">
      <p className="text-[17px] text-sub">{message}</p>
      <Link
        href="/app"
        className="mt-5 inline-block rounded-full bg-action px-6 py-3 text-[15px] font-semibold text-white"
      >
        Back to My Trips
      </Link>
    </div>
  );
}

export default function TripPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  usePageTitle("Trip");
  const now = useNow();
  const parsed = parseTripId(id);
  const { train, loading, error } = useResolvedTrain(parsed ? parsed.number : null);
  const records = useTrips();

  const held = useMemo(() => records.some((r) => `${r.number}_${r.runDate}` === id), [records, id]);

  if (!parsed) return <NotFound message="This trip link isn't valid." />;
  if (!now || loading) return <DetailSkeleton />;
  if (!train) return <NotFound message={error ?? "Couldn't load this train."} />;

  const record = tripStore.record(id);
  const booking =
    record && record.coach && record.seat && record.pnr
      ? { coach: record.coach, seat: record.seat, pnr: record.pnr }
      : undefined;
  const trip = heldTripForRun(train, parsed.runDate, now, booking);
  const { live } = trip;
  const origin = train.stops[0];
  const dest = train.stops[train.stops.length - 1];

  return (
    <div className="relative bg-black">
      <div className="relative">
        <RouteMap live={live} className="h-[320px] w-full" />
        <EstimateBadge className="absolute left-4 top-4" />
        {live.phase === "enroute" && (
          <span className="tnum absolute right-4 top-4 rounded-full bg-[#1c1e22]/90 px-3.5 py-1.5 text-[12px] font-bold uppercase tracking-[0.08em] text-white backdrop-blur">
            {live.speedKmh} km/h · {live.delayMin > 5 ? `+${live.delayMin}m` : "on time"}
          </span>
        )}
      </div>

      <div className="relative z-10 -mt-7 rounded-t-[28px] bg-white pb-40">
        <div className="flex items-start gap-3 px-5 pt-5">
          <TrainMark category={train.category} size={44} />
          <div className="min-w-0 flex-1">
            <div className="text-[13px] font-semibold uppercase tracking-wide text-sub">
              {train.number} • {CATEGORY_LABEL[train.category]} • {fmtDay(live.departsAt)}
            </div>
            <h1 className="truncate text-[25px] font-bold leading-tight tracking-tight text-inkline">
              {cityFor(origin.code, origin.name)} to {cityFor(dest.code, dest.name)}
            </h1>
          </div>
          <Link
            href="/app"
            aria-label="Close"
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-fill text-inkline shadow-sm"
          >
            <X size={19} />
          </Link>
        </div>

        <div className="mt-4">
          <StatusBanner live={live} now={now} />
        </div>

        <div className="px-5">
          <EndBlock trip={trip} end="dep" />
          <MetaDivider live={live} />
          <EndBlock trip={trip} end="arr" />
        </div>

        <div className="space-y-4 px-5 pt-2">
          {live.phase === "enroute" && <LiveRun live={live} now={now} />}
          <Timetable live={live} />
          <BookingTiles trip={trip} />
          <GoodToKnow train={train} totalKm={live.totalKm} />
          <p className="pt-1 text-center text-[13px] text-faded">
            Live position and delays are estimated from the published schedule, not a
            real-time feed.
          </p>
        </div>
      </div>

      <ActionBar id={id} held={held} runDate={parsed.runDate} number={parsed.number} trip={trip} />
    </div>
  );
}

function ActionBar({
  id,
  held,
  number,
  runDate,
  trip,
}: {
  id: string;
  held: boolean;
  number: string;
  runDate: string;
  trip: HeldTrip;
}) {
  const [alerts, setAlerts] = useState(true);
  const share = () => {
    const url = typeof window !== "undefined" ? window.location.href : "";
    const text = `Track ${trip.train.number} ${trip.train.name} on Railly`;
    if (navigator.share) {
      navigator.share({ title: "Railly", text, url }).catch(() => {});
    } else {
      navigator.clipboard?.writeText(url);
    }
  };
  return (
    <div className="fixed bottom-[86px] left-1/2 z-40 flex w-full max-w-[430px] -translate-x-1/2 items-center justify-between px-5">
      <div className="flex items-center gap-6 rounded-full bg-white px-6 py-3.5 shadow-[0_8px_30px_rgba(0,0,0,0.16)] ring-1 ring-black/[0.04]">
        <button aria-label="Share this trip" onClick={share}>
          <Share size={20} className="text-inkline" />
        </button>
        <button aria-label={alerts ? "Mute alerts" : "Enable alerts"} onClick={() => setAlerts((a) => !a)}>
          {alerts ? <Bell size={20} className="text-inkline" /> : <BellOff size={20} className="text-faded" />}
        </button>
        {held ? (
          <button aria-label="Stop tracking" onClick={() => tripStore.remove(id)}>
            <Trash2 size={20} className="text-latered" />
          </button>
        ) : (
          <button
            className="text-[15px] font-semibold text-action"
            onClick={() => tripStore.add(number, runDate)}
          >
            Track
          </button>
        )}
      </div>
      <Link
        href="/"
        className="flex items-center gap-2 rounded-full bg-pro px-6 py-3.5 text-[17px] font-semibold text-white shadow-[0_8px_30px_rgba(124,58,237,0.4)]"
      >
        <Sparkles size={17} />
        Get the app
      </Link>
    </div>
  );
}
