import { TrainFront } from "lucide-react";

/** Static miniature of the app's home screen inside a device frame. */
export function PhoneMock() {
  return (
    <div className="relative mx-auto w-[300px] rounded-[46px] bg-ink p-[10px] shadow-deep ring-1 ring-black/50">
      <div className="relative overflow-hidden rounded-[37px] bg-void pb-7">
        <div className="mx-auto mt-2.5 h-[22px] w-[86px] rounded-full bg-black" />

        <div className="px-4 pt-4 text-left">
          <div className="text-[21px] font-bold tracking-tight text-white">
            My Trips
          </div>
          <div className="mt-2 flex items-center gap-1.5 text-[9px] font-bold uppercase tracking-[1px] text-white/40">
            <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-go" />
            Live now
          </div>

          {/* live journey */}
          <div className="mt-1.5 rounded-2xl bg-cabin p-3 ring-1 ring-white/[0.06]">
            <div className="flex items-center gap-2">
              <span className="flex h-5 w-5 items-center justify-center rounded-full bg-[#c62828] text-[7px] font-bold text-white">
                RJ
              </span>
              <span className="text-[10px] text-white/55">Rajdhani · 12951</span>
              <span className="ml-auto rounded-full bg-go/15 px-1.5 py-0.5 text-[8px] font-semibold uppercase tracking-[0.5px] text-go">
                On Time
              </span>
            </div>
            <div className="mt-2 flex items-end justify-between">
              <div>
                <div className="text-[22px] font-extrabold leading-none text-white">
                  MMCT
                </div>
                <div className="mt-0.5 text-[9px] text-white/45">Mumbai</div>
              </div>
              <TrainFront size={11} className="mb-2 text-white/30" />
              <div className="text-right">
                <div className="text-[22px] font-extrabold leading-none text-white">
                  NDLS
                </div>
                <div className="mt-0.5 text-[9px] text-white/45">New Delhi</div>
              </div>
            </div>
            <div className="tnum mt-1.5 flex justify-between text-[11px] font-semibold text-go">
              <span>17:00</span>
              <span>09:32</span>
            </div>
            <div className="relative mt-2 h-[3px] w-full rounded-full bg-white/12">
              <div className="h-full w-[62%] rounded-full bg-flame" />
              <TrainFront
                size={10}
                className="absolute left-[62%] top-1/2 -translate-x-1/2 -translate-y-1/2 text-flame"
              />
            </div>
            <div className="mt-1.5 flex justify-between text-[9px] text-white/45">
              <span>5h 48m remaining</span>
              <span>Next · Kota</span>
            </div>
          </div>

          <div className="mt-3 text-[9px] font-bold uppercase tracking-[1px] text-white/40">
            Wed, 8 Jul
          </div>

          {/* upcoming journey */}
          <div className="mt-1.5 rounded-2xl bg-cabin p-3 ring-1 ring-white/[0.06]">
            <div className="flex items-center gap-2">
              <span className="flex h-5 w-5 items-center justify-center rounded-full bg-[#0d47a1] text-[7px] font-bold text-white">
                VB
              </span>
              <span className="text-[10px] text-white/55">
                Vande Bharat · 22436
              </span>
              <span className="ml-auto rounded-full bg-go/15 px-1.5 py-0.5 text-[8px] font-semibold uppercase tracking-[0.5px] text-go">
                On Time
              </span>
            </div>
            <div className="mt-2 flex items-end justify-between">
              <div>
                <div className="text-[22px] font-extrabold leading-none text-white">
                  NDLS
                </div>
                <div className="mt-0.5 text-[9px] text-white/45">New Delhi</div>
              </div>
              <TrainFront size={11} className="mb-2 text-white/30" />
              <div className="text-right">
                <div className="text-[22px] font-extrabold leading-none text-white">
                  BSB
                </div>
                <div className="mt-0.5 text-[9px] text-white/45">Varanasi</div>
              </div>
            </div>
            <div className="tnum mt-1.5 flex justify-between text-[11px] font-semibold text-go">
              <span>06:00</span>
              <span>14:00</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
