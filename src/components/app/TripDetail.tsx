"use client";

import Link from "next/link";
import { useState } from "react";
import {
  AlertTriangle,
  ArrowDownRight,
  ArrowUpRight,
  Armchair,
  BadgeCheck,
  Bell,
  BellOff,
  CircleDot,
  Clock,
  Moon,
  Share,
  Sparkles,
  Ticket,
  TrainFront,
  TrendingDown,
  X,
} from "lucide-react";
import { CATEGORY_LABEL, cityFor } from "@/lib/format";
import { pickInt, seededRng } from "@/lib/rng";
import { fmtDay, fmtDuration, fmtTime, istDateISO } from "@/lib/time";
import { getTrip, type HeldTrip } from "@/lib/trips";
import type { LiveStatus, Train, TrainEvent, TrainEventKind } from "@/lib/types";
import { LiveMap } from "./LiveMap";
import { TrainMark } from "./TrainMark";
import { useNow } from "./useNow";

const ontimeOrLate = (delayMin: number) =>
  delayMin > 5 ? "text-latered" : "text-ontime";

function ProPill() {
  return (
    <span className="rounded-md bg-[#f1e8fa] px-2 py-0.5 text-[11px] font-bold uppercase tracking-wide text-pro">
      Pro
    </span>
  );
}

function Card({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={`rounded-[20px] border border-[#ececee] bg-white p-5 ${className}`}>
      {children}
    </div>
  );
}

function CardTitle({
  title,
  sub,
  pro = false,
}: {
  title: string;
  sub?: string;
  pro?: boolean;
}) {
  return (
    <div className="mb-4">
      <div className="flex items-center justify-between">
        <h3 className="text-[21px] font-bold tracking-tight text-inkline">{title}</h3>
        {pro && <ProPill />}
      </div>
      {sub && <p className="mt-0.5 text-[14px] text-sub">{sub}</p>}
    </div>
  );
}

/* ---------- status banner ---------- */

function StatusBanner({ live, now }: { live: LiveStatus; now: Date }) {
  const late = live.delayMin > 5;
  const dest = live.train.stops[live.train.stops.length - 1];
  const destCity = cityFor(dest.code, dest.name);
  const latestDelay = live.events.find((e) => e.kind === "delay");

  let headline: React.ReactNode;
  let detail: string;
  if (live.phase === "enroute") {
    const remaining = Math.max(0, (live.arrivesEst.getTime() - now.getTime()) / 60_000);
    headline = (
      <>
        Arriving in{" "}
        <span className={`font-bold ${ontimeOrLate(live.delayMin)}`}>
          {fmtDuration(remaining)}
        </span>
      </>
    );
    detail = late
      ? `${latestDelay ? latestDelay.text : "Running behind schedule"} — reaches ${destCity} ${live.delayMin}m late ›`
      : `Running on time — reaches ${destCity} at ${fmtTime(live.arrivesEst)} ›`;
  } else if (live.phase === "boarding") {
    // Estimated departure, not the scheduled one that may already be missed.
    const depEst = live.stopTimings[0].depEst;
    const toDep = Math.max(0, (depEst.getTime() - now.getTime()) / 60_000);
    headline = (
      <>
        Departure in{" "}
        <span className={`font-bold ${ontimeOrLate(live.delayMin)}`}>
          {fmtDuration(toDep)}
        </span>
      </>
    );
    const pf = live.train.stops[0].platform;
    detail = `Boarding${pf ? ` from PF ${pf}` : ""} — departs ${fmtTime(depEst)} ›`;
  } else if (live.phase === "scheduled") {
    const toDep = Math.max(
      0,
      (live.stopTimings[0].depEst.getTime() - now.getTime()) / 60_000,
    );
    headline = (
      <>
        Departure in{" "}
        <span className={`font-bold ${ontimeOrLate(live.delayMin)}`}>
          {fmtDuration(toDep)}
        </span>
      </>
    );
    detail = late
      ? `Railly predicts a ${live.delayMin}m late start — the railway hasn't announced it yet ›`
      : `Inbound rake is on schedule, with enough time for a ${fmtTime(live.departsAt)} departure ›`;
  } else {
    headline = (
      <>
        Arrived{" "}
        <span className={`font-bold ${ontimeOrLate(live.delayMin)}`}>
          {late ? `${live.delayMin}m late` : "on time"}
        </span>
      </>
    );
    detail = `Reached ${destCity} at ${fmtTime(live.arrivesEst)} ›`;
  }

  return (
    <div className={`px-5 py-3.5 ${late ? "bg-[#fbf0ee]" : "bg-[#f2f8f4]"}`}>
      <p className="text-[18px] font-semibold text-inkline">{headline}</p>
      <p className="mt-0.5 text-[15px] leading-snug text-[#374151]">{detail}</p>
    </div>
  );
}

/* ---------- giant time blocks ---------- */

function EndBlock({ trip, end }: { trip: HeldTrip; end: "dep" | "arr" }) {
  const { live, train } = trip;
  const idx = end === "dep" ? 0 : train.stops.length - 1;
  const stop = train.stops[idx];
  const timing = live.stopTimings[idx];
  const sched = end === "dep" ? timing.depSched : timing.arrSched;
  const est = end === "dep" ? timing.depEst : timing.arrEst;
  const late = timing.delayMin > 5;
  const isPast = end === "dep"
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
          {late && (
            <span className="tnum text-[15px] text-faded line-through">
              {fmtTime(sched)}
            </span>
          )}
        </div>
        <p className="mt-1.5 text-[14px]">
          <span className={`font-semibold ${ontimeOrLate(timing.delayMin)}`}>
            {late ? `${timing.delayMin}m Late` : "On Time"}
          </span>
          <span className="text-sub"> • {fmtDay(est)}</span>
        </p>
      </div>
      <div className="shrink-0 text-right">
        <span className="inline-block rounded-[10px] bg-gate px-3 py-1.5 text-[19px] font-bold text-black">
          {stop.platform ? `PF ${stop.platform}` : "PF --"}
        </span>
        <p className="mt-1.5 text-[13px] text-sub">
          {end === "dep" ? `Coach ${trip.coach}` : "Platform"}
        </p>
      </div>
    </div>
  );
}

function MetaDivider({ live }: { live: LiveStatus }) {
  const { train } = live;
  const journeyMin = train.stops[train.stops.length - 1].arrMin;
  const overnight =
    istDateISO(live.arrivesSched) !== istDateISO(live.departsAt);
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

/* ---------- live run stats ---------- */

function LiveRun({ live, now }: { live: LiveStatus; now: Date }) {
  // Standing at a station means prevStopIdx IS the station — nextStopIdx is
  // still hundreds of km away.
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
      <CardTitle title="Live Run" sub={`${Math.round(live.progress * 100)}% of ${Math.round(live.totalKm)} km`} />
      <div className="h-2 w-full overflow-hidden rounded-full bg-fill">
        <div
          className="h-full rounded-full bg-arc"
          style={{ width: `${live.progress * 100}%` }}
        />
      </div>
      <div className="mt-4 grid grid-cols-3">
        {stats.map(([label, value]) => (
          <div key={label}>
            <div className="text-[14px] text-sub">{label}</div>
            <div className="tnum mt-0.5 text-[19px] font-semibold text-inkline">
              {value}
            </div>
          </div>
        ))}
      </div>
      <div className="mt-4 flex items-center justify-between border-t border-hairline pt-3.5 text-[15px]">
        <span className="text-sub">
          {live.atStation ? "At" : "Next"}{" "}
          <span className="font-semibold text-inkline">{hereStop?.name}</span>
          {live.atStation && <span className="text-sub"> · departs</span>}
        </span>
        <span className={`tnum font-bold ${ontimeOrLate(hereTiming.delayMin)}`}>
          {fmtTime(hereTime)}
        </span>
      </div>
    </Card>
  );
}

/* ---------- updates feed ---------- */

function EventIcon({ kind }: { kind: TrainEventKind }) {
  const cls = "mt-[3px] shrink-0";
  switch (kind) {
    case "delay":
      return <AlertTriangle size={15} className={`${cls} text-latered`} />;
    case "recovery":
      return <TrendingDown size={15} className={`${cls} text-ontime`} />;
    case "platform":
      return <Bell size={15} className={`${cls} text-[#b58900]`} />;
    case "arrived":
      return <BadgeCheck size={15} className={`${cls} text-ontime`} />;
    default:
      return <CircleDot size={15} className={`${cls} text-faded`} />;
  }
}

function Updates({ events }: { events: TrainEvent[] }) {
  if (events.length === 0) return null;
  return (
    <Card>
      <CardTitle title="Updates" sub={`${events.length} updates for this trip`} pro />
      <ul className="space-y-3.5">
        {events.map((event, i) => (
          <li key={i} className="flex gap-3">
            <EventIcon kind={event.kind} />
            <div className="min-w-0 flex-1">
              <div className="text-[15px] leading-snug text-inkline">{event.text}</div>
              {event.detail && (
                <div className="mt-0.5 text-[13px] text-sub">{event.detail}</div>
              )}
            </div>
            <span className="tnum shrink-0 text-[13px] text-faded">
              {fmtTime(event.time)}
            </span>
          </li>
        ))}
      </ul>
    </Card>
  );
}

/* ---------- detailed timetable ---------- */

function Timetable({ live }: { live: LiveStatus }) {
  const stops = live.train.stops;
  return (
    <Card>
      <CardTitle
        title="Detailed Timetable"
        sub="Scheduled and estimated for every halt"
      />
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
            <li
              key={stop.code}
              className={`flex items-baseline ${dimmed ? "opacity-45" : ""}`}
            >
              <div className="min-w-0 flex-1">
                <span className="text-[16px] text-inkline">
                  {stop.name}
                  {t.current && (
                    <span className="ml-2 text-[12px] font-bold uppercase tracking-wide text-arc">
                      Here
                    </span>
                  )}
                </span>
                <span className="ml-2 text-[12px] text-faded">
                  {stop.platform ? `PF ${stop.platform}` : stop.code}
                </span>
              </div>
              <span className="tnum w-[76px] text-right text-[16px] text-inkline">
                {fmtTime(sched)}
              </span>
              <span
                className={`tnum w-[76px] text-right text-[16px] font-semibold ${ontimeOrLate(t.delayMin)}`}
              >
                {fmtTime(est)}
              </span>
            </li>
          );
        })}
      </ul>
    </Card>
  );
}

/* ---------- arrival forecast histogram ---------- */

function Forecast({ train }: { train: Train }) {
  const rng = seededRng(`forecast:${train.number}`);
  const early = pickInt(rng, 4, 22);
  const onTime = pickInt(rng, 28, 62);
  const late15 = pickInt(rng, 5, Math.max(6, 90 - early - onTime));
  const late30 = pickInt(rng, 2, Math.max(3, 96 - early - onTime - late15));
  const cancelled = pickInt(rng, 0, 2);
  const late45 = Math.max(0, 100 - early - onTime - late15 - late30 - cancelled);
  const rows: [string, number, string][] = [
    ["Early", early, "#34a853"],
    ["On Time", onTime, "#6fcf6f"],
    ["15m late", late15, "#f5c518"],
    ["30m late", late30, "#f29a2e"],
    ["45m+ late", late45, "#e5493d"],
    ["Cancelled", cancelled, "#9ca3af"],
  ];
  return (
    <Card>
      <CardTitle
        title="Arrival Forecast"
        sub={`${train.number} performance over the last 60 days`}
        pro
      />
      <div className="space-y-3">
        {rows.map(([label, pct, color]) => (
          <div key={label} className="flex items-center gap-3">
            <span className="w-[84px] shrink-0 text-[15px] text-inkline">{label}</span>
            <span className="h-3.5 flex-1 overflow-hidden rounded-full bg-[#eef0f2]">
              <span
                className="block h-full rounded-full"
                style={{ width: `${pct}%`, background: color }}
              />
            </span>
            <span className="tnum w-10 shrink-0 text-right text-[15px] font-semibold text-inkline">
              {pct}%
            </span>
          </div>
        ))}
      </div>
    </Card>
  );
}

/* ---------- where's my rake ---------- */

function WheresMyRake({ trip }: { trip: HeldTrip }) {
  const { train, live } = trip;
  const rng = seededRng(`rake:${train.number}`);
  const isEmu = train.category === "vande-bharat";
  const loco = isEmu ? "ICF trainset" : train.category === "shatabdi" ? "WAP-5" : "WAP-7";
  const age = pickInt(rng, 2, isEmu ? 4 : 14);
  const originDelay = live.stopTimings[0].delayMin;
  const issue = originDelay > 5;
  return (
    <div className="overflow-hidden rounded-[20px] bg-gradient-to-b from-[#4a7dc4] via-[#bfd3e8] to-white">
      <div className="p-5">
        <div className="flex items-center justify-between">
          <h3 className="text-[21px] font-bold tracking-tight text-white">
            Where&apos;s My Rake?
          </h3>
          <ProPill />
        </div>
        <p className="mt-0.5 text-[14px] text-[#e2ecf8]">
          {loco} • {isEmu ? "16-car rake" : "LHB rake"} • {age} years old
        </p>
        <div className="flex items-center justify-center py-5">
          <TrainFront
            size={110}
            strokeWidth={1.2}
            className="text-white drop-shadow-[0_10px_24px_rgba(20,50,90,0.45)]"
          />
        </div>
        <span
          className={`inline-block rounded-[10px] px-2.5 py-1 text-[12px] font-bold uppercase tracking-wide text-white ${
            issue ? "bg-[#c07a12]" : "bg-[#2e8b4f]"
          }`}
        >
          {issue ? "Minor delay" : "✓ No issue"}
        </span>
        <p className="mt-2.5 text-[16px] leading-snug text-inkline">
          {issue
            ? `Your rake reached the platform ${originDelay}m behind — Railly predicted the knock-on before the announcement.`
            : "Looking good! Your rake is at the platform with no issues upstream."}
        </p>
      </div>
    </div>
  );
}

/* ---------- operator card ---------- */

const ZONE_BY_ORIGIN: Record<string, [string, string]> = {
  MMCT: ["Western Railway", "Mumbai"],
  NDLS: ["Northern Railway", "New Delhi"],
  HWH: ["Eastern Railway", "Kolkata"],
  SDAH: ["Eastern Railway", "Kolkata"],
  SHM: ["South Eastern Railway", "Kolkata"],
  SBC: ["South Western Railway", "Hubballi"],
};

function OperatorCard({ train }: { train: Train }) {
  const [zone, hq] = ZONE_BY_ORIGIN[train.stops[0].code] ?? ["Indian Railways", "New Delhi"];
  return (
    <Card>
      <div className="flex items-center gap-3">
        <TrainMark category={train.category} size={44} />
        <div>
          <h3 className="text-[21px] font-bold tracking-tight text-inkline">
            Indian Railways
          </h3>
          <p className="text-[14px] text-sub">{zone}</p>
        </div>
      </div>
      <div className="mt-4 grid grid-cols-2 gap-3">
        {(
          [
            ["Phone", "tel:139"],
            ["Website", "https://enquiry.indianrail.gov.in"],
            ["X / Twitter", "https://x.com/RailMinIndia"],
            ["Rail Madad", "https://railmadad.indianrailways.gov.in"],
          ] as const
        ).map(([label, href]) => (
          <a
            key={label}
            href={href}
            target={href.startsWith("http") ? "_blank" : undefined}
            rel={href.startsWith("http") ? "noopener noreferrer" : undefined}
            className="flex h-11 items-center justify-center rounded-xl bg-fill text-[13px] font-semibold uppercase tracking-wide text-inkline"
          >
            {label}
          </a>
        ))}
      </div>
      <div className="mt-4 grid grid-cols-3">
        {(
          [
            ["Category", CATEGORY_LABEL[train.category]],
            ["Zone HQ", hq],
            ["Helpline", "139"],
          ] as const
        ).map(([label, value]) => (
          <div key={label}>
            <div className="text-[13px] text-faded">{label}</div>
            <div className="mt-0.5 text-[15px] font-semibold text-inkline">{value}</div>
          </div>
        ))}
      </div>
    </Card>
  );
}

/* ---------- history / booking / good to know ---------- */

function History({ trip }: { trip: HeldTrip }) {
  const { train, live } = trip;
  const origin = train.stops[0];
  const dest = train.stops[train.stops.length - 1];
  const rng = seededRng(`history:${origin.code}-${dest.code}`);
  const trips = pickInt(rng, 0, 6);
  const stats: [string, string][] = [
    ["Trips", String(trips)],
    ["Distance", `${(trips * Math.round(live.totalKm)).toLocaleString("en-IN")} km`],
    ["Rail time", fmtDuration(trips * dest.arrMin)],
  ];
  return (
    <Card>
      <CardTitle
        title="My History on This Route"
        sub={`${origin.code} → ${dest.code}`}
      />
      <div className="grid grid-cols-3">
        {stats.map(([label, value]) => (
          <div key={label}>
            <div className="text-[14px] text-sub">{label}</div>
            <div className="tnum mt-0.5 text-[19px] font-semibold text-inkline">
              {value}
            </div>
          </div>
        ))}
      </div>
      {trips === 0 && (
        <p className="mt-3 text-[15px] text-faded">No past trips on this route</p>
      )}
    </Card>
  );
}

const CLASS_BY_CATEGORY: Record<string, string> = {
  "vande-bharat": "AC Chair Car",
  shatabdi: "Executive Chair Car",
  rajdhani: "AC 2 Tier",
  duronto: "AC 2 Tier",
  tejas: "AC Chair Car",
  superfast: "AC 3 Tier",
  express: "AC 3 Tier",
};

function BookingTiles({ trip }: { trip: HeldTrip }) {
  const [copied, setCopied] = useState(false);
  return (
    <div className="grid grid-cols-2 gap-3">
      <div className="rounded-[16px] border border-hairline p-4">
        <div className="flex items-start justify-between">
          <Ticket size={20} className="text-inkline" />
          <button
            onClick={() => {
              navigator.clipboard?.writeText(trip.pnr);
              setCopied(true);
              setTimeout(() => setCopied(false), 1500);
            }}
            className="rounded-md bg-[#e8f1fe] px-2 py-0.5 text-[11px] font-bold text-[#1d6fe0]"
          >
            {copied ? "COPIED" : "COPY"}
          </button>
        </div>
        <div className="tnum mt-3 text-[19px] font-bold text-inkline">{trip.pnr}</div>
        <div className="mt-0.5 text-[14px] text-faded">PNR</div>
      </div>
      <div className="rounded-[16px] border border-hairline p-4">
        <div className="flex items-start justify-between">
          <Armchair size={20} className="text-inkline" />
        </div>
        <div className="mt-3 text-[19px] font-bold text-inkline">
          {trip.coach} · {trip.seat}
        </div>
        <div className="mt-0.5 text-[14px] text-faded">
          {CLASS_BY_CATEGORY[trip.train.category] ?? "AC 3 Tier"}
        </div>
      </div>
    </div>
  );
}

function GoodToKnow({ live }: { live: LiveStatus }) {
  const { train } = live;
  const rows: [string, string][] = [
    ["Halts", `${train.stops.length - 2} stations`],
    ["Runs", train.days.length === 7 ? "Daily" : train.days.join(" · ")],
    ["Timezone", "IST throughout — no change"],
    ["Pantry", train.category === "vande-bharat" ? "At seat" : "Pantry car"],
  ];
  return (
    <Card>
      <CardTitle title="Good to Know" />
      <div className="space-y-2.5">
        {rows.map(([label, value]) => (
          <div key={label} className="flex items-baseline justify-between gap-4">
            <span className="text-[15px] text-sub">{label}</span>
            <span className="text-right text-[15px] font-semibold text-inkline">
              {value}
            </span>
          </div>
        ))}
      </div>
    </Card>
  );
}

/* ---------- screen ---------- */

function DetailSkeleton() {
  return (
    <div className="bg-white px-5 pt-6">
      <div className="h-[300px] animate-pulse rounded-[20px] bg-fill" />
      <div className="mt-5 h-24 animate-pulse rounded-[20px] bg-fill" />
      <div className="mt-5 h-60 animate-pulse rounded-[20px] bg-fill" />
    </div>
  );
}

export function TripDetail({ id }: { id: string }) {
  const now = useNow();
  return !now ? <DetailSkeleton /> : <DetailBody id={id} now={now} />;
}

function DetailBody({ id, now }: { id: string; now: Date }) {
  const trip = getTrip(id, now);

  if (!trip) {
    return (
      <div className="bg-white px-6 pt-32 text-center">
        <p className="text-[17px] text-sub">This trip doesn&apos;t exist.</p>
        <Link
          href="/app"
          className="mt-5 inline-block rounded-full bg-action px-6 py-3 text-[15px] font-semibold text-white"
        >
          Back to My Trips
        </Link>
      </div>
    );
  }

  const { live, train } = trip;
  const origin = train.stops[0];
  const dest = train.stops[train.stops.length - 1];

  return (
    <div className="relative bg-black">
      <div className="relative">
        <LiveMap live={live} className="h-[320px] w-full" />
        {live.phase === "enroute" && (
          <span className="tnum absolute left-4 top-4 rounded-full bg-[#1c1e22]/90 px-3.5 py-1.5 text-[12px] font-bold uppercase tracking-[0.08em] text-white backdrop-blur">
            {live.speedKmh} km/h ·{" "}
            {live.delayMin > 5 ? `+${live.delayMin}m` : "on time"}
          </span>
        )}
      </div>

      {/* the sheet */}
      <div className="relative z-10 -mt-7 rounded-t-[28px] bg-white pb-40">
        <div className="flex items-start gap-3 px-5 pt-5">
          <TrainMark category={train.category} size={44} />
          <div className="min-w-0 flex-1">
            <div className="text-[13px] font-semibold uppercase tracking-wide text-sub">
              {train.number} • {fmtDay(live.departsAt)}
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
          <Updates events={live.events} />
          <Timetable live={live} />
          <Forecast train={train} />
          <WheresMyRake trip={trip} />
          <OperatorCard train={train} />
          <History trip={trip} />
          <BookingTiles trip={trip} />
          <GoodToKnow live={live} />
          <p className="pt-1 text-center text-[14px] text-faded">Report Data Issue</p>
        </div>
      </div>

      <ActionBar trip={trip} />
    </div>
  );
}

function ActionBar({ trip }: { trip: HeldTrip }) {
  const [alerts, setAlerts] = useState(true);
  const share = () => {
    const url = typeof window !== "undefined" ? window.location.href : "";
    const text = `Track ${trip.train.number} ${trip.train.name} live on Railly`;
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
        <button
          aria-label={alerts ? "Mute alerts" : "Enable alerts"}
          onClick={() => setAlerts((a) => !a)}
        >
          {alerts ? (
            <Bell size={20} className="text-inkline" />
          ) : (
            <BellOff size={20} className="text-faded" />
          )}
        </button>
      </div>
      <Link
        href="/#pricing"
        className="flex items-center gap-2 rounded-full bg-pro px-6 py-3.5 text-[17px] font-semibold text-white shadow-[0_8px_30px_rgba(124,58,237,0.4)]"
      >
        <Sparkles size={17} />
        Get Pro
      </Link>
    </div>
  );
}
