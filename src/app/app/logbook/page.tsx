import type { Metadata } from "next";
import { TrainFront } from "lucide-react";
import { TrainMark } from "@/components/app/TrainMark";
import { CATEGORY_LABEL } from "@/lib/format";
import { TRAINS } from "@/lib/trains";

export const metadata: Metadata = { title: "Logbook" };

function BigStat({ value, label }: { value: string; label: string }) {
  return (
    <div className="rounded-2xl bg-cabin p-4 ring-1 ring-white/[0.06]">
      <div className="tnum text-[30px] font-extrabold leading-none tracking-tight">
        {value}
      </div>
      <div className="mt-1.5 text-[11px] font-bold uppercase tracking-[1px] text-white/40">
        {label}
      </div>
    </div>
  );
}

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <h3 className="mb-2 mt-7 text-[11px] font-bold uppercase tracking-[1px] text-white/40">
      {children}
    </h3>
  );
}

/** Passport-style lifetime stats — the year in trains. */
export default function LogbookPage() {
  const topTrains = [TRAINS[0], TRAINS[3], TRAINS[7]];
  const counts = [14, 9, 6];

  return (
    <div className="px-4 pt-14">
      <h1 className="text-[34px] font-bold tracking-tight">Logbook</h1>

      {/* passport cover */}
      <div className="glow-violet mt-5 overflow-hidden rounded-2xl p-5 ring-1 ring-white/10">
        <div className="flex items-center justify-between">
          <span className="text-[11px] font-bold uppercase tracking-[2px] text-sun">
            Railly Passport
          </span>
          <TrainFront size={18} className="text-sun" />
        </div>
        <div className="mt-6 text-[22px] font-bold tracking-tight text-white">
          Yash L.
        </div>
        <div className="mt-1 text-[12px] text-white/55">
          Riding the rails since 2024
        </div>
        <div className="mt-5 flex gap-5 border-t border-white/15 pt-4">
          <div>
            <div className="tnum text-[17px] font-bold text-white">2026</div>
            <div className="text-[10px] uppercase tracking-[1px] text-white/45">
              Season
            </div>
          </div>
          <div>
            <div className="tnum text-[17px] font-bold text-white">6 mo</div>
            <div className="text-[10px] uppercase tracking-[1px] text-white/45">
              Trip streak
            </div>
          </div>
          <div>
            <div className="tnum text-[17px] font-bold text-white">Top 4%</div>
            <div className="text-[10px] uppercase tracking-[1px] text-white/45">
              Of riders
            </div>
          </div>
        </div>
      </div>

      <SectionLabel>Lifetime</SectionLabel>
      <div className="grid grid-cols-2 gap-3">
        <BigStat value="47" label="Trips" />
        <BigStat value="28,412" label="Kilometres" />
        <BigStat value="214h" label="On rails" />
        <BigStat value="38" label="Stations" />
      </div>

      <SectionLabel>Top trains</SectionLabel>
      <div className="rounded-2xl bg-cabin px-4 py-1 ring-1 ring-white/[0.06]">
        {topTrains.map((train, i) => (
          <div
            key={train.number}
            className="flex items-center gap-3 border-b border-white/[0.06] py-3 last:border-0"
          >
            <span className="tnum w-4 text-[13px] font-bold text-white/35">
              {i + 1}
            </span>
            <TrainMark category={train.category} size={28} />
            <div className="min-w-0 flex-1">
              <div className="truncate text-[14px] font-semibold">
                {train.name}
              </div>
              <div className="text-[12px] text-white/45">
                {CATEGORY_LABEL[train.category]} · {train.number}
              </div>
            </div>
            <span className="tnum text-[13px] font-semibold text-white/70">
              {counts[i]}×
            </span>
          </div>
        ))}
      </div>

      <SectionLabel>Delay report · 2026</SectionLabel>
      <div className="rounded-2xl bg-cabin p-4 ring-1 ring-white/[0.06]">
        <div className="flex h-2.5 w-full gap-[2px] overflow-hidden rounded-full">
          <span className="w-[72%] bg-go" />
          <span className="w-[19%] bg-sun" />
          <span className="w-[9%] bg-late" />
        </div>
        <div className="mt-2.5 flex justify-between text-[11px] text-white/45">
          <span>72% on time</span>
          <span>19% under 30m</span>
          <span>9% worse</span>
        </div>
        <div className="mt-4 space-y-1.5 border-t border-white/[0.07] pt-3">
          <div className="flex justify-between text-[13px]">
            <span className="text-white/45">Hours lost to delays</span>
            <span className="tnum font-semibold text-white/85">18h 40m</span>
          </div>
          <div className="flex justify-between text-[13px]">
            <span className="text-white/45">Worst delay</span>
            <span className="tnum font-semibold text-white/85">
              +2h 05m · Karnataka Exp
            </span>
          </div>
          <div className="flex justify-between text-[13px]">
            <span className="text-white/45">Longest journey</span>
            <span className="tnum font-semibold text-white/85">
              2,395 km · SBC → NDLS
            </span>
          </div>
        </div>
      </div>

      <p className="mt-6 pb-2 text-center text-[11px] text-white/30">
        Lifetime stats are illustrative in this demo.
      </p>
    </div>
  );
}
