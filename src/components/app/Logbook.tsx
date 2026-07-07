"use client";

import Link from "next/link";
import { ChevronRight, Settings, TrainFront, Users } from "lucide-react";
import { cityFor } from "@/lib/format";
import { fmtDay } from "@/lib/time";
import { getMyTrips } from "@/lib/trips";
import { TrainMark } from "./TrainMark";
import { useNow } from "./useNow";

/** The Delay Report signature: a split-flap departure board. */
function SplitFlap({ text }: { text: string }) {
  return (
    <div className="flex gap-1.5">
      {text.split("").map((ch, i) => {
        const ghost = /[A-Z]/.test(ch);
        return (
          <span
            key={i}
            className="split-flap h-[68px] w-[48px] text-[38px] font-bold"
            style={{ color: ghost ? "rgba(255,235,220,0.3)" : "#fdf3e7" }}
          >
            {ch}
          </span>
        );
      })}
    </div>
  );
}

function GradientButton({
  children,
  dark = false,
}: {
  children: React.ReactNode;
  dark?: boolean;
}) {
  return (
    <Link
      href="/app/track"
      className={`mt-5 flex h-[52px] items-center justify-between rounded-[14px] px-4 text-[17px] font-semibold ${
        dark ? "bg-black/15 text-[#2d2a66]" : "bg-white/15 text-white"
      }`}
    >
      {children}
      <ChevronRight size={18} />
    </Link>
  );
}

function PassportCard() {
  const stats: [string, string, string?][] = [
    ["Trips", "47", "12 overnight"],
    ["Rail time", "214h"],
    ["Stations", "38"],
    ["Trains", "8"],
  ];
  return (
    <div className="rounded-[24px] bg-gradient-to-br from-[#2a1052] to-[#1b2e7a] p-6">
      <div className="text-[19px] font-semibold tracking-[0.06em] text-white">
        ALL-TIME RAILLY PASSPORT
      </div>
      <div className="mt-1 text-[12px] font-semibold uppercase tracking-[0.12em] text-[#8b7bc4]">
        Passport • Pass • पासपोर्ट
      </div>

      <div className="mt-6">
        <div className="text-[13px] font-bold uppercase tracking-[0.1em] text-[#a79bd6]">
          Distance
        </div>
        <div className="tnum mt-1 text-[42px] font-extrabold leading-none text-white">
          28,412 <span className="text-[26px] font-semibold text-[#a79bd6]">km</span>
        </div>
        <div className="mt-1 text-[15px] text-[#a79bd6]">0.71x around the world</div>
      </div>

      <div className="mt-6 grid grid-cols-2 gap-x-4 gap-y-5">
        {stats.map(([label, value, sub]) => (
          <div key={label}>
            <div className="text-[13px] font-bold uppercase tracking-[0.1em] text-[#a79bd6]">
              {label}
            </div>
            <div className="tnum mt-0.5 text-[28px] font-bold leading-none text-white">
              {value}
            </div>
            {sub && <div className="mt-0.5 text-[14px] text-[#a79bd6]">{sub}</div>}
          </div>
        ))}
      </div>

      <GradientButton>All Trip Stats</GradientButton>
    </div>
  );
}

function DelayCard() {
  return (
    <div className="rounded-[24px] bg-gradient-to-b from-[#140302] via-[#5a0e0e] to-[#7a1e14] p-6">
      <SplitFlap text="42MIN" />
      <div className="mt-5 text-[26px] font-bold text-white">Lost to Delays</div>
      <p className="mt-1 text-[15px] text-[#c98f85]">
        Delayed trips averaged 42m late · 19h lost all-time
      </p>

      <div className="led-board tnum mt-5 flex items-center justify-between rounded-md px-4 py-3 text-[17px] font-bold">
        <span>2H05M</span>
        <span>12627</span>
        <span>SBC-NDLS</span>
      </div>
      <div className="mt-2 text-[13px] font-bold uppercase tracking-[0.1em] text-[#c98f85]">
        Worst delay
      </div>

      <GradientButton>All Delay Stats</GradientButton>
    </div>
  );
}

function MostRiddenCard() {
  return (
    <div className="rounded-[24px] bg-gradient-to-br from-[#c9c4f2] to-[#bfd3f0] p-6">
      <div className="text-[19px] font-bold text-[#2d2a66]">Most ridden train</div>
      <div className="mt-1 text-[40px] font-extrabold leading-tight tracking-tight text-[#1f1c4d]">
        Vande Bharat
      </div>
      <div className="text-[15px] text-[#4b4787]">14 trips • 96 hours on board</div>
      <div className="flex justify-center py-4">
        <TrainFront
          size={96}
          strokeWidth={1.1}
          className="text-[#2d2a66] drop-shadow-[0_12px_20px_rgba(45,42,102,0.35)]"
        />
      </div>
      <GradientButton dark>All Train Stats</GradientButton>
    </div>
  );
}

function Chip({ children }: { children: React.ReactNode }) {
  return (
    <span className="flex h-11 items-center gap-2 rounded-full border border-hairline px-4 text-[15px] font-semibold text-inkline">
      {children}
    </span>
  );
}

export function Logbook() {
  const now = useNow();
  const past = now ? getMyTrips(now).past : [];

  return (
    <div className="min-h-dvh bg-white px-5 pb-32 pt-12">
      <header className="flex items-center gap-3.5">
        <span className="flex h-14 w-14 items-center justify-center rounded-full bg-[#cfe3f8] text-[19px] font-bold text-[#2563ab]">
          Y
        </span>
        <div>
          <h1 className="text-[28px] font-bold leading-tight tracking-tight text-inkline">
            Yash L.
          </h1>
          <p className="text-[16px] text-sub">My Trip Log</p>
        </div>
      </header>

      <div className="mt-4 flex gap-2.5">
        <Chip>
          <Users size={16} />
          Railly Friends
        </Chip>
        <Chip>
          <Settings size={16} />
          Settings
        </Chip>
      </div>

      <div className="mt-5 flex items-center gap-3">
        <span className="rounded-xl bg-fill px-4 py-2 text-[15px] font-semibold text-inkline">
          ALL-TIME
        </span>
        <span className="text-[15px] text-faded">2026</span>
      </div>

      <Link
        href="/#pricing"
        className="mt-4 block rounded-[16px] border border-[#d8b4e8] bg-[#faf3fc] p-4"
      >
        <div className="flex items-center gap-2">
          <span className="rounded-md bg-[#eddcf5] px-2 py-0.5 text-[11px] font-bold uppercase text-pro">
            Pro
          </span>
          <span className="text-[17px] font-semibold text-pro">
            Complete Your Map &amp; Stats
          </span>
          <ChevronRight size={16} className="ml-auto text-pro" />
        </div>
        <p className="mt-1 text-[15px] text-[#6b21a8]">
          Upgrade to add trips older than 12 months.
        </p>
      </Link>

      <div className="mt-4 space-y-4">
        <PassportCard />
        <DelayCard />
        <MostRiddenCard />
      </div>

      <section className="mt-8">
        <h2 className="text-[26px] font-bold tracking-tight text-inkline">
          Past Trips
        </h2>
        <div className="mt-2 flex items-baseline justify-between border-b border-hairline pb-2">
          <span className="text-[19px] font-bold text-inkline">2026</span>
          <span className="text-[12px] font-bold uppercase tracking-[0.08em] text-faded">
            47 trips
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
                  <span className="tnum">{trip.trainNumber}</span>
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

      <p className="mt-8 text-center text-[12px] text-faded">
        Lifetime stats are illustrative in this demo.
      </p>
    </div>
  );
}
