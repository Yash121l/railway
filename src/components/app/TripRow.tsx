import Link from "next/link";
import { ArrowDownRight, ArrowUpRight, Check, TrainFront } from "lucide-react";
import { cityFor } from "@/lib/format";
import { fmtDay, fmtDuration, fmtTime, istDateISO } from "@/lib/time";
import type { HeldTrip } from "@/lib/trips";
import { TrainMark } from "./TrainMark";

type Tone = "ontime" | "late" | "muted";

const TONE_TEXT: Record<Tone, string> = {
  ontime: "text-ontime",
  late: "text-latered",
  muted: "text-faded",
};
const TONE_BG: Record<Tone, string> = {
  ontime: "bg-ontime",
  late: "bg-latered",
  muted: "bg-faded",
};

/** The colored dep/arr cell — the whole cluster inherits status color. */
function TimeCell({
  kind,
  code,
  time,
  tone,
  nextDay,
}: {
  kind: "dep" | "arr";
  code: string;
  time: Date;
  tone: Tone;
  nextDay?: boolean;
}) {
  const Arrow = kind === "dep" ? ArrowUpRight : ArrowDownRight;
  return (
    <span className="flex items-center gap-1.5">
      <span
        className={`flex h-[18px] w-[18px] items-center justify-center rounded-full ${TONE_BG[tone]}`}
      >
        <Arrow size={12} strokeWidth={3} className="text-white" />
      </span>
      <span className={`text-[15px] font-semibold ${TONE_TEXT[tone]} opacity-80`}>
        {code}
      </span>
      <span className={`tnum text-[16px] font-bold ${TONE_TEXT[tone]}`}>
        {fmtTime(time)}
        {nextDay && <sup className="text-[10px] font-bold">+1</sup>}
      </span>
    </span>
  );
}

/** Left rail: huge countdown, or the ON RAILS / ARRIVED circle. */
function Rail({ trip, now }: { trip: HeldTrip; now: Date }) {
  const { live } = trip;

  if (live.phase === "enroute" || live.phase === "boarding") {
    return (
      <div className="flex w-[72px] shrink-0 flex-col items-center gap-1.5 pt-1">
        <span className="flex h-11 w-11 items-center justify-center rounded-full bg-fill">
          <TrainFront size={20} className="text-inkline" />
        </span>
        <span className="text-[10px] font-bold uppercase tracking-[0.08em] text-faded">
          {live.phase === "enroute" ? "On rails" : "Boarding"}
        </span>
      </div>
    );
  }

  if (live.phase === "arrived") {
    return (
      <div className="flex w-[72px] shrink-0 flex-col items-center gap-1.5 pt-1">
        <span className="flex h-11 w-11 items-center justify-center rounded-full bg-fill">
          <Check size={20} className="text-sub" />
        </span>
        <span className="text-[10px] font-bold uppercase tracking-[0.08em] text-faded">
          Arrived
        </span>
      </div>
    );
  }

  // scheduled: big countdown to the estimated departure
  const mins = Math.max(
    0,
    (live.stopTimings[0].depEst.getTime() - now.getTime()) / 60_000,
  );
  let value: string;
  let caption: string;
  if (mins >= 48 * 60) {
    const days = Math.round(mins / (24 * 60));
    value = String(days);
    caption = days === 1 ? "day" : "days";
  } else if (mins >= 60) {
    value = `${Math.floor(mins / 60)}h`;
    const rest = Math.round(mins % 60);
    caption = `${rest} minutes`;
  } else {
    value = String(Math.max(1, Math.round(mins)));
    caption = "minutes";
  }
  return (
    <div className="w-[72px] shrink-0 pt-0.5 text-center">
      <div className="text-[32px] font-extrabold leading-none tracking-tight text-inkline">
        {value}
      </div>
      <div className="mt-1 text-[10px] font-bold uppercase tracking-[0.08em] text-faded">
        {caption}
      </div>
    </div>
  );
}

function StatusText({ trip, now }: { trip: HeldTrip; now: Date }) {
  const { live } = trip;
  const late = live.delayMin > 5;

  if (live.phase === "enroute") {
    const remaining = Math.max(
      0,
      (live.arrivesEst.getTime() - now.getTime()) / 60_000,
    );
    return (
      <span className={`font-bold ${late ? "text-latered" : "text-ontime"}`}>
        Arriving in {fmtDuration(remaining)}
      </span>
    );
  }
  if (live.phase === "arrived") {
    return <span className="text-faded">{fmtDay(live.arrivesEst)}</span>;
  }
  // boarding / scheduled
  const farOut =
    live.departsAt.getTime() - now.getTime() > 36 * 3_600_000;
  if (farOut) return <span className="text-faded">{fmtDay(live.departsAt)}</span>;
  return (
    <span className="text-sub">
      Departs{" "}
      <span className={`font-bold ${late ? "text-latered" : "text-ontime"}`}>
        {late ? `${live.delayMin}m late` : "On Time"}
      </span>
    </span>
  );
}

/** One journey, one dense line — Dec 2025 Flighty row anatomy. */
export function TripRow({
  trip,
  now,
  divider = true,
}: {
  trip: HeldTrip;
  now: Date;
  divider?: boolean;
}) {
  const { train, live } = trip;
  const n = train.stops.length;
  const origin = train.stops[0];
  const dest = train.stops[n - 1];
  const depT = live.stopTimings[0];
  const arrT = live.stopTimings[n - 1];
  const isPast = live.phase === "arrived";

  const depTone: Tone = isPast ? "muted" : depT.delayMin > 5 ? "late" : "ontime";
  const arrTone: Tone = isPast ? "muted" : arrT.delayMin > 5 ? "late" : "ontime";
  const nextDay = istDateISO(arrT.arrEst) !== istDateISO(depT.depEst);

  return (
    <Link
      href={`/app/trip/${trip.id}`}
      className={`flex gap-2 pt-4 transition-colors active:bg-fill/60 ${isPast ? "opacity-60" : ""}`}
    >
      <Rail trip={trip} now={now} />
      <div
        className={`min-w-0 flex-1 pb-4 ${divider ? "border-b border-hairline" : ""}`}
      >
        <div className="flex items-center gap-2">
          <TrainMark category={train.category} size={20} />
          <span className="tnum text-[15px] text-sub">{train.number}</span>
          <span className="ml-auto text-[15px]">
            <StatusText trip={trip} now={now} />
          </span>
        </div>
        <div className="mt-1 truncate text-[21px] leading-tight text-inkline">
          <span className="font-bold">{cityFor(origin.code, origin.name)}</span>
          <span className="text-sub"> to </span>
          <span className="font-bold">{cityFor(dest.code, dest.name)}</span>
        </div>
        <div className="mt-1.5 flex items-center justify-between gap-2">
          <TimeCell kind="dep" code={origin.code} time={depT.depEst} tone={depTone} />
          <TimeCell
            kind="arr"
            code={dest.code}
            time={arrT.arrEst}
            tone={arrTone}
            nextDay={nextDay}
          />
        </div>
      </div>
    </Link>
  );
}
