"use client";

import Link from "next/link";
import {
  AlertTriangle,
  ArrowDownRight,
  BadgeCheck,
  Bell,
  ChevronLeft,
  CircleDot,
  Gauge,
  TrainFront,
} from "lucide-react";
import { CATEGORY_LABEL, cityFor } from "@/lib/format";
import { pickInt, seededRng } from "@/lib/rng";
import { fmtDay, fmtDuration, fmtTime } from "@/lib/time";
import { getTrip, type HeldTrip } from "@/lib/trips";
import type {
  LiveStatus,
  Train,
  TrainEvent,
  TrainEventKind,
} from "@/lib/types";
import { LiveMap } from "./LiveMap";
import { ProgressBar } from "./ProgressBar";
import { StatusPill } from "./StatusPill";
import { TrainMark } from "./TrainMark";
import { useNow } from "./useNow";

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <h3 className="mb-2 text-[11px] font-bold uppercase tracking-[1px] text-white/40">
      {children}
    </h3>
  );
}

function Card({ children }: { children: React.ReactNode }) {
  return (
    <div className="rounded-2xl bg-cabin p-4 ring-1 ring-white/[0.06]">
      {children}
    </div>
  );
}

/* ---------- status header ---------- */

function summaryLine(live: LiveStatus): string {
  const dest = live.train.stops[live.train.stops.length - 1];
  const destCity = cityFor(dest.code, dest.name);
  switch (live.phase) {
    case "enroute":
      return live.delayMin > 5
        ? `Arriving ${destCity} ${fmtTime(live.arrivesEst)}, ${live.delayMin}m late`
        : `Arriving ${destCity} ${fmtTime(live.arrivesEst)}, on time`;
    case "boarding":
      return `Departs ${fmtTime(live.departsAt)} from ${live.train.stops[0].name}`;
    case "scheduled":
      return `Departs ${fmtDay(live.departsAt)} · ${fmtTime(live.departsAt)}`;
    case "arrived":
      return `Arrived ${destCity} ${fmtTime(live.arrivesEst)}`;
  }
}

function StatusCard({ live }: { live: LiveStatus }) {
  const { train } = live;
  return (
    <Card>
      <div className="flex items-center gap-3">
        <TrainMark category={train.category} size={34} />
        <div className="min-w-0 flex-1">
          <div className="truncate text-[15px] font-semibold">{train.name}</div>
          <div className="text-[13px] text-white/50">
            {CATEGORY_LABEL[train.category]} · {train.number}
          </div>
        </div>
        <StatusPill tone={live.tone} text={live.statusText} />
      </div>
      <p className="mt-3 border-t border-white/[0.07] pt-3 text-[13px] text-white/60">
        {summaryLine(live)}
      </p>
    </Card>
  );
}

/* ---------- departure / arrival blocks ---------- */

function EndBlock({
  live,
  end,
}: {
  live: LiveStatus;
  end: "dep" | "arr";
}) {
  const stops = live.train.stops;
  const idx = end === "dep" ? 0 : stops.length - 1;
  const stop = stops[idx];
  const timing = live.stopTimings[idx];
  const sched = end === "dep" ? timing.depSched : timing.arrSched;
  const est = end === "dep" ? timing.depEst : timing.arrEst;
  const late = timing.delayMin > 5;
  return (
    <div className="flex-1">
      <div className="text-[11px] font-bold uppercase tracking-[1px] text-white/40">
        {end === "dep" ? "Departure" : "Arrival"}
      </div>
      <div className="mt-2 text-[26px] font-extrabold leading-none tracking-[-0.5px]">
        {stop.code}
      </div>
      <div className="mt-1 truncate text-[12px] text-white/50">{stop.name}</div>
      <div className="mt-3 text-[20px] font-semibold">
        PF {stop.platform ?? "—"}
      </div>
      <div className="tnum mt-2 text-[15px] font-semibold">
        {late ? (
          <>
            <span className="mr-1.5 text-[12px] font-normal text-white/35 line-through">
              {fmtTime(sched)}
            </span>
            <span className="text-late">{fmtTime(est)}</span>
          </>
        ) : (
          <span className="text-go">{fmtTime(sched)}</span>
        )}
      </div>
      <div className="mt-0.5 text-[11px] text-white/40">{fmtDay(sched)}</div>
    </div>
  );
}

/* ---------- live progress ---------- */

function ProgressCard({ live, now }: { live: LiveStatus; now: Date }) {
  const next = live.train.stops[live.nextStopIdx];
  const nextTiming = live.stopTimings[live.nextStopIdx];
  const remainingMin = Math.max(
    0,
    (live.arrivesEst.getTime() - now.getTime()) / 60_000,
  );
  return (
    <Card>
      <ProgressBar progress={live.progress} />
      <div className="mt-3 grid grid-cols-3 text-center">
        <div>
          <div className="tnum text-[17px] font-bold">
            {Math.round(live.progressKm)}
            <span className="text-[12px] font-normal text-white/40">
              {" "}
              / {Math.round(live.totalKm)} km
            </span>
          </div>
          <div className="mt-0.5 text-[11px] uppercase tracking-[0.5px] text-white/40">
            Covered
          </div>
        </div>
        <div>
          <div className="tnum text-[17px] font-bold">
            {live.speedKmh}
            <span className="text-[12px] font-normal text-white/40"> km/h</span>
          </div>
          <div className="mt-0.5 text-[11px] uppercase tracking-[0.5px] text-white/40">
            Speed
          </div>
        </div>
        <div>
          <div className="tnum text-[17px] font-bold">
            {fmtDuration(remainingMin)}
          </div>
          <div className="mt-0.5 text-[11px] uppercase tracking-[0.5px] text-white/40">
            To go
          </div>
        </div>
      </div>
      <div className="mt-3 flex items-center justify-between border-t border-white/[0.07] pt-3 text-[13px]">
        <span className="text-white/50">
          {live.atStation ? "At" : "Next"} ·{" "}
          <span className="text-white/85">{next?.name}</span>
        </span>
        <span className="tnum font-semibold text-white/85">
          {fmtTime(nextTiming.arrEst)}
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
      return <AlertTriangle size={14} className={`${cls} text-late`} />;
    case "recovery":
      return <ArrowDownRight size={14} className={`${cls} text-go`} />;
    case "platform":
      return <Bell size={14} className={`${cls} text-sun`} />;
    case "arrived":
      return <BadgeCheck size={14} className={`${cls} text-go`} />;
    default:
      return <CircleDot size={14} className={`${cls} text-white/40`} />;
  }
}

function UpdatesFeed({ events }: { events: TrainEvent[] }) {
  if (events.length === 0) return null;
  return (
    <div>
      <SectionLabel>Updates</SectionLabel>
      <Card>
        <ul className="space-y-3.5">
          {events.map((event, i) => (
            <li key={i} className="flex gap-3">
              <EventIcon kind={event.kind} />
              <div className="min-w-0 flex-1">
                <div className="text-[14px] leading-snug">{event.text}</div>
                {event.detail && (
                  <div className="mt-0.5 text-[12px] text-white/45">
                    {event.detail}
                  </div>
                )}
              </div>
              <span className="tnum shrink-0 text-[12px] text-white/40">
                {fmtTime(event.time)}
              </span>
            </li>
          ))}
        </ul>
      </Card>
    </div>
  );
}

/* ---------- station timeline ---------- */

function StationTimeline({ live }: { live: LiveStatus }) {
  const stops = live.train.stops;
  return (
    <div>
      <SectionLabel>Timetable</SectionLabel>
      <Card>
        <ul>
          {stops.map((stop, i) => {
            const t = live.stopTimings[i];
            const isFirst = i === 0;
            const isLast = i === stops.length - 1;
            const late = t.delayMin > 5;
            return (
              <li key={stop.code} className="relative flex gap-3 pb-4 last:pb-0">
                {/* rail */}
                {!isLast && (
                  <span
                    className={`absolute left-[5px] top-4 h-full w-[2px] ${
                      t.passed ? "bg-flame/70" : "bg-white/12"
                    }`}
                  />
                )}
                <span
                  className={`relative mt-[5px] h-3 w-3 shrink-0 rounded-full border-2 ${
                    t.current
                      ? "border-flame bg-flame shadow-[0_0_10px_rgba(255,138,61,0.9)]"
                      : t.passed
                        ? "border-flame bg-flame/80"
                        : "border-white/25 bg-void"
                  }`}
                />
                <div
                  className={`min-w-0 flex-1 ${t.passed && !t.current ? "opacity-50" : ""}`}
                >
                  <div className="flex items-baseline gap-2">
                    <span className="text-[14px] font-semibold">{stop.name}</span>
                    <span className="text-[11px] text-white/40">{stop.code}</span>
                    {stop.platform && (
                      <span className="text-[11px] text-white/40">
                        PF {stop.platform}
                      </span>
                    )}
                  </div>
                  <div className="tnum mt-0.5 text-[12px] text-white/45">
                    {isFirst
                      ? `dep ${fmtTime(t.depSched)}`
                      : isLast
                        ? `arr ${fmtTime(t.arrSched)}`
                        : `arr ${fmtTime(t.arrSched)} · dep ${fmtTime(t.depSched)}`}
                  </div>
                </div>
                <span
                  className={`tnum mt-[2px] shrink-0 text-[13px] font-semibold ${
                    late ? "text-late" : "text-go"
                  }`}
                >
                  {late ? `+${t.delayMin}m` : "On time"}
                </span>
              </li>
            );
          })}
        </ul>
      </Card>
    </div>
  );
}

/* ---------- arrival forecast (seeded 60-day punctuality) ---------- */

function ForecastCard({ train }: { train: Train }) {
  const rng = seededRng(`forecast:${train.number}`);
  const early = pickInt(rng, 5, 25);
  const onTime = pickInt(rng, 30, 60);
  const late = Math.max(5, 100 - early - onTime);
  const verdict =
    late > 40
      ? "Often runs late on this route"
      : late > 25
        ? "Occasionally delayed into the terminus"
        : "Usually on time";
  return (
    <div>
      <SectionLabel>Arrival forecast</SectionLabel>
      <Card>
        <div className="flex h-2.5 w-full gap-[2px] overflow-hidden rounded-full">
          <span className="bg-go/80" style={{ width: `${early}%` }} />
          <span className="bg-go" style={{ width: `${onTime}%` }} />
          <span className="bg-sun" style={{ width: `${late * 0.6}%` }} />
          <span className="bg-late" style={{ width: `${late * 0.4}%` }} />
        </div>
        <div className="mt-2.5 flex justify-between text-[11px] text-white/45">
          <span>{early + onTime}% early or on time</span>
          <span>{late}% late · last 60 days</span>
        </div>
        <p className="mt-2 text-[13px] text-white/70">{verdict}</p>
      </Card>
    </div>
  );
}

/* ---------- rake / booking / good-to-know ---------- */

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between py-1.5">
      <span className="text-[13px] text-white/45">{label}</span>
      <span className="tnum text-[13px] font-semibold text-white/85">{value}</span>
    </div>
  );
}

function RakeCard({ train }: { train: Train }) {
  const rng = seededRng(`rake:${train.number}`);
  const isEmu = train.category === "vande-bharat";
  const loco = isEmu
    ? "Integral Coach Factory EMU"
    : train.category === "shatabdi"
      ? "WAP-5 electric"
      : "WAP-7 electric";
  const coaches = isEmu ? 16 : pickInt(rng, 18, 22);
  const age = pickInt(rng, 2, isEmu ? 4 : 14);
  return (
    <div>
      <SectionLabel>Rake</SectionLabel>
      <Card>
        <div className="flex items-center gap-3 pb-2">
          <span className="flex h-9 w-9 items-center justify-center rounded-full bg-cabin2 ring-1 ring-white/10">
            <TrainFront size={18} className="text-white/70" />
          </span>
          <div>
            <div className="text-[14px] font-semibold">{loco}</div>
            <div className="text-[12px] text-white/45">
              {isEmu ? "Self-propelled trainset" : "LHB rake"} · {coaches} coaches
            </div>
          </div>
        </div>
        <InfoRow label="Rake age" value={`${age} years`} />
        <InfoRow
          label="Top speed"
          value={train.category === "vande-bharat" ? "160 km/h" : "130 km/h"}
        />
      </Card>
    </div>
  );
}

const CLASS_BY_CATEGORY: Record<string, string> = {
  "vande-bharat": "AC Chair Car (CC)",
  shatabdi: "Executive Chair Car (EC)",
  rajdhani: "AC 2 Tier (2A)",
  duronto: "AC 2 Tier (2A)",
  tejas: "AC Chair Car (CC)",
  superfast: "AC 3 Tier (3A)",
  express: "AC 3 Tier (3A)",
};

function BookingCard({ trip }: { trip: HeldTrip }) {
  return (
    <div>
      <SectionLabel>My booking</SectionLabel>
      <Card>
        <InfoRow label="PNR" value={trip.pnr} />
        <InfoRow label="Coach · Seat" value={`${trip.coach} · ${trip.seat}`} />
        <InfoRow
          label="Class"
          value={CLASS_BY_CATEGORY[trip.train.category] ?? "AC 3 Tier (3A)"}
        />
      </Card>
    </div>
  );
}

function GoodToKnow({ live }: { live: LiveStatus }) {
  const { train } = live;
  const journeyMin = train.stops[train.stops.length - 1].arrMin;
  return (
    <div>
      <SectionLabel>Good to know</SectionLabel>
      <Card>
        <InfoRow label="Distance" value={`${Math.round(live.totalKm)} km`} />
        <InfoRow label="Scheduled time" value={fmtDuration(journeyMin)} />
        <InfoRow label="Halts" value={`${train.stops.length - 2} stations`} />
        <InfoRow label="Times shown" value="IST" />
      </Card>
    </div>
  );
}

/* ---------- screen ---------- */

function DetailSkeleton() {
  return (
    <div className="px-4 pt-16">
      <div className="h-[300px] animate-pulse rounded-2xl bg-cabin" />
      <div className="mt-4 h-28 animate-pulse rounded-2xl bg-cabin" />
      <div className="mt-4 h-64 animate-pulse rounded-2xl bg-cabin" />
    </div>
  );
}

export function TripDetail({ id }: { id: string }) {
  const now = useNow();

  return (
    <div>
      <header className="fixed left-1/2 top-0 z-30 flex w-full max-w-[430px] -translate-x-1/2 items-center justify-between px-3 py-3">
        <Link
          href="/app"
          aria-label="Back to My Trips"
          className="flex h-9 w-9 items-center justify-center rounded-full bg-void/70 text-white/85 ring-1 ring-white/10 backdrop-blur-xl"
        >
          <ChevronLeft size={20} />
        </Link>
        <span className="rounded-full bg-void/70 px-3 py-1.5 text-[13px] font-semibold ring-1 ring-white/10 backdrop-blur-xl">
          {id.split("_")[0]}
        </span>
        <span className="flex h-9 w-9 items-center justify-center rounded-full bg-void/70 text-white/85 ring-1 ring-white/10 backdrop-blur-xl">
          <Gauge size={17} />
        </span>
      </header>

      {!now ? <DetailSkeleton /> : <DetailBody id={id} now={now} />}
    </div>
  );
}

function DetailBody({ id, now }: { id: string; now: Date }) {
  const trip = getTrip(id, now);

  if (!trip) {
    return (
      <div className="px-6 pt-32 text-center">
        <p className="text-[15px] text-white/70">This trip doesn&apos;t exist.</p>
        <Link
          href="/app"
          className="mt-4 inline-block rounded-full bg-signal px-5 py-2.5 text-[14px] font-semibold text-white"
        >
          Back to My Trips
        </Link>
      </div>
    );
  }

  const { live } = trip;

  return (
    <div>
      <LiveMap live={live} className="h-[360px] w-full" />

      {/* the sheet — pulled up over the map, Flighty style */}
      <div className="relative z-10 -mt-5 space-y-5 rounded-t-[20px] bg-void px-4 pb-10 pt-2.5">
        <div className="mx-auto h-[5px] w-9 rounded-full bg-white/25" />
        <StatusCard live={live} />
        <div>
          <SectionLabel>Journey</SectionLabel>
          <Card>
            <div className="flex gap-4">
              <EndBlock live={live} end="dep" />
              <div className="w-px bg-white/[0.07]" />
              <EndBlock live={live} end="arr" />
            </div>
          </Card>
        </div>
        {live.phase === "enroute" && <ProgressCard live={live} now={now} />}
        <UpdatesFeed events={live.events} />
        <StationTimeline live={live} />
        <ForecastCard train={live.train} />
        <RakeCard train={live.train} />
        <BookingCard trip={trip} />
        <GoodToKnow live={live} />
      </div>
    </div>
  );
}
