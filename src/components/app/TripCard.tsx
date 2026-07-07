import Link from "next/link";
import { TrainFront } from "lucide-react";
import { CATEGORY_LABEL, cityFor } from "@/lib/format";
import { fmtDay, fmtDuration, fmtTime } from "@/lib/time";
import type { HeldTrip } from "@/lib/trips";
import { ProgressBar } from "./ProgressBar";
import { StatusPill } from "./StatusPill";
import { TrainMark } from "./TrainMark";

function TimeBlock({
  sched,
  est,
  delayMin,
  align,
}: {
  sched: Date;
  est: Date;
  delayMin: number;
  align: "left" | "right";
}) {
  const late = delayMin > 5;
  return (
    <div className={`tnum text-[17px] font-semibold ${align === "right" ? "text-right" : ""}`}>
      {late ? (
        <>
          <span className="mr-1.5 text-[13px] font-normal text-white/35 line-through">
            {fmtTime(sched)}
          </span>
          <span className="text-late">{fmtTime(est)}</span>
        </>
      ) : (
        <span className="text-go">{fmtTime(sched)}</span>
      )}
    </div>
  );
}

/** One journey, one dense scannable card — the departure-board rule. */
export function TripCard({ trip, now }: { trip: HeldTrip; now: Date }) {
  const { train, live } = trip;
  const n = train.stops.length;
  const origin = train.stops[0];
  const dest = train.stops[n - 1];
  const depTiming = live.stopTimings[0];
  const arrTiming = live.stopTimings[n - 1];
  const isPast = live.phase === "arrived";
  const nextStop = train.stops[live.nextStopIdx];
  const remainingMin = Math.max(
    0,
    (live.arrivesEst.getTime() - now.getTime()) / 60_000,
  );

  return (
    <Link
      href={`/app/trip/${trip.id}`}
      className={`block rounded-2xl bg-cabin p-4 ring-1 ring-white/[0.06] transition-transform active:scale-[0.985] ${
        isPast ? "opacity-55" : ""
      }`}
    >
      <div className="flex items-center gap-2.5">
        <TrainMark category={train.category} size={26} />
        <span className="min-w-0 truncate text-[13px] text-white/55">
          {CATEGORY_LABEL[train.category]} · {train.number}
        </span>
        <span className="ml-auto">
          <StatusPill tone={live.tone} text={live.statusText} />
        </span>
      </div>

      <div className="mt-3 grid grid-cols-[1fr_auto_1fr] items-center gap-2">
        <div>
          <div className="text-[28px] font-extrabold leading-none tracking-[-0.5px]">
            {origin.code}
          </div>
          <div className="mt-1 text-xs text-white/45">
            {cityFor(origin.code, origin.name)}
          </div>
        </div>
        <div className="flex flex-col items-center gap-1 px-1">
          <TrainFront size={15} className="text-white/30" />
          <span className="text-[11px] text-white/35">
            {fmtDuration(dest.arrMin)}
          </span>
        </div>
        <div className="text-right">
          <div className="text-[28px] font-extrabold leading-none tracking-[-0.5px]">
            {dest.code}
          </div>
          <div className="mt-1 text-xs text-white/45">
            {cityFor(dest.code, dest.name)}
          </div>
        </div>
      </div>

      <div className="mt-2 grid grid-cols-2 items-center">
        <TimeBlock
          sched={depTiming.depSched}
          est={depTiming.depEst}
          delayMin={depTiming.delayMin}
          align="left"
        />
        <TimeBlock
          sched={arrTiming.arrSched}
          est={arrTiming.arrEst}
          delayMin={arrTiming.delayMin}
          align="right"
        />
      </div>

      {live.phase === "enroute" && (
        <div className="mt-3.5">
          <ProgressBar progress={live.progress} />
          <div className="mt-2 flex items-center justify-between text-[12px] text-white/45">
            <span>{fmtDuration(remainingMin)} remaining</span>
            <span>
              Next · {nextStop ? cityFor(nextStop.code, nextStop.name) : "—"}
            </span>
          </div>
        </div>
      )}

      {live.phase === "boarding" && (
        <div className="mt-3 flex items-center justify-between text-[12px] text-white/45">
          <span>
            Departs {fmtTime(live.departsAt)}
            {origin.platform ? ` · PF ${origin.platform}` : ""}
          </span>
          <span>
            Coach {trip.coach} · {trip.seat}
          </span>
        </div>
      )}

      {live.phase === "scheduled" && (
        <div className="mt-3 flex items-center justify-between text-[12px] text-white/45">
          <span>{fmtDay(live.departsAt)}</span>
          <span>
            Coach {trip.coach} · {trip.seat}
          </span>
        </div>
      )}

      {isPast && (
        <div className="mt-3.5">
          <ProgressBar progress={1} muted />
          <div className="mt-2 text-[12px] text-white/40">
            {fmtDay(live.arrivesEst)} · {Math.round(live.totalKm)} km
          </div>
        </div>
      )}
    </Link>
  );
}
