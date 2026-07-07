import {
  ArrowDownRight,
  ArrowUpRight,
  ChevronDown,
  Search,
  TrainFront,
} from "lucide-react";

function MiniTimeCell({
  kind,
  code,
  time,
  late = false,
}: {
  kind: "dep" | "arr";
  code: string;
  time: string;
  late?: boolean;
}) {
  const Arrow = kind === "dep" ? ArrowUpRight : ArrowDownRight;
  const color = late ? "text-latered" : "text-ontime";
  const bg = late ? "bg-latered" : "bg-ontime";
  return (
    <span className="flex items-center gap-1">
      <span className={`flex h-3 w-3 items-center justify-center rounded-full ${bg}`}>
        <Arrow size={8} strokeWidth={3.5} className="text-white" />
      </span>
      <span className={`text-[8.5px] font-semibold ${color} opacity-80`}>{code}</span>
      <span className={`tnum text-[9.5px] font-bold ${color}`}>{time}</span>
    </span>
  );
}

/** Static miniature of the app's home screen inside a device frame. */
export function PhoneMock() {
  return (
    <div className="relative mx-auto w-[300px] rounded-[46px] bg-ink p-[10px] shadow-deep ring-1 ring-black/50">
      <div className="relative overflow-hidden rounded-[37px] bg-[#05070d]">
        {/* the dark map strip with a blue route arc */}
        <div className="relative h-[110px] overflow-hidden">
          <svg viewBox="0 0 280 110" className="absolute inset-0 h-full w-full">
            <circle cx="200" cy="130" r="95" fill="#0d1622" />
            <path
              d="M40 92 Q 130 18 244 40"
              fill="none"
              stroke="#4d9fff"
              strokeWidth="7"
              strokeLinecap="round"
              opacity="0.25"
            />
            <path
              d="M40 92 Q 130 18 244 40"
              fill="none"
              stroke="#7eb6f6"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <circle cx="40" cy="92" r="4" fill="#05070d" stroke="#fff" strokeWidth="1.6" />
            <circle cx="244" cy="40" r="4" fill="#05070d" stroke="#fff" strokeWidth="1.6" />
            <circle cx="150" cy="47" r="5.5" fill="#fff" stroke="#4d9fff" strokeWidth="2.5" />
          </svg>
          <div className="absolute left-1/2 top-2.5 h-[20px] w-[80px] -translate-x-1/2 rounded-full bg-black" />
        </div>

        {/* the white sheet */}
        <div className="rounded-t-[26px] bg-white px-4 pb-6 pt-3.5 text-left">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1 text-[16px] font-extrabold tracking-tight text-inkline">
              My Trips
              <ChevronDown size={11} strokeWidth={3.5} />
            </div>
            <span className="flex h-6 w-6 items-center justify-center rounded-full bg-fill text-[9px] font-bold text-sub">
              Y
            </span>
          </div>

          <div className="mt-2 flex h-8 items-center gap-1.5 rounded-xl bg-fill px-2.5">
            <Search size={11} className="text-faded" />
            <span className="text-[9.5px] text-faded">Search to add trains</span>
          </div>

          {/* live row */}
          <div className="flex gap-2 pt-3">
            <div className="flex w-[42px] shrink-0 flex-col items-center gap-1">
              <span className="flex h-7 w-7 items-center justify-center rounded-full bg-fill">
                <TrainFront size={13} className="text-inkline" />
              </span>
              <span className="text-[6px] font-bold uppercase tracking-[0.08em] text-faded">
                On rails
              </span>
            </div>
            <div className="min-w-0 flex-1 border-b border-hairline pb-2.5">
              <div className="flex items-center gap-1.5">
                <span className="flex h-3.5 w-3.5 items-center justify-center rounded-full bg-[#c62828] text-[5px] font-bold text-white">
                  RJ
                </span>
                <span className="tnum text-[9px] text-sub">12951</span>
                <span className="ml-auto text-[9px] font-bold text-ontime">
                  Arriving in 5h 48m
                </span>
              </div>
              <div className="mt-0.5 text-[13px] leading-tight text-inkline">
                <span className="font-bold">Mumbai</span>
                <span className="text-sub"> to </span>
                <span className="font-bold">New Delhi</span>
              </div>
              <div className="mt-1 flex items-center justify-between">
                <MiniTimeCell kind="dep" code="MMCT" time="17:00" />
                <MiniTimeCell kind="arr" code="NDLS" time="09:57" late />
              </div>
            </div>
          </div>

          {/* upcoming row */}
          <div className="flex gap-2 pt-2.5">
            <div className="w-[42px] shrink-0 pt-0.5 text-center">
              <div className="text-[17px] font-extrabold leading-none text-inkline">5h</div>
              <div className="mt-0.5 text-[6px] font-bold uppercase tracking-[0.08em] text-faded">
                41 minutes
              </div>
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-1.5">
                <span className="flex h-3.5 w-3.5 items-center justify-center rounded-full bg-[#0d47a1] text-[5px] font-bold text-white">
                  VB
                </span>
                <span className="tnum text-[9px] text-sub">22436</span>
                <span className="ml-auto text-[9px] text-sub">
                  Departs <span className="font-bold text-ontime">On Time</span>
                </span>
              </div>
              <div className="mt-0.5 text-[13px] leading-tight text-inkline">
                <span className="font-bold">New Delhi</span>
                <span className="text-sub"> to </span>
                <span className="font-bold">Varanasi</span>
              </div>
              <div className="mt-1 flex items-center justify-between">
                <MiniTimeCell kind="dep" code="NDLS" time="06:00" />
                <MiniTimeCell kind="arr" code="BSB" time="14:00" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
