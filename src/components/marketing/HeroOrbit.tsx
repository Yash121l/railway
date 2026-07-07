"use client";

import { useEffect, useRef, useState } from "react";
import { NotifCard } from "./NotifCard";
import { PhoneMock } from "./PhoneMock";

const NOTIFS = [
  {
    title: "Good morning! Your train today is on time.",
    body: "12951 Mumbai Rajdhani · departs 17:00 from PF 2.",
    time: "9:02",
    accent: "go" as const,
  },
  {
    title: "MMCT → NDLS · Delayed 25m",
    body: "Held at the outer signal near Ratlam. New arrival 09:57.",
    time: "22:41",
    accent: "sun" as const,
  },
  {
    title: "Platform changed at Kota",
    body: "PF 1 → PF 3 · announced 38 min before arrival.",
    time: "4:12",
    accent: "crit" as const,
  },
  {
    title: "Dad arrived in New Delhi",
    body: "It's 10:12 (12m early) and ☀️ 34° outside.",
    time: "10:12",
    accent: "go" as const,
  },
  {
    title: "Boarding now · Coach C4",
    body: "Your coach stops near the PF 2 stairs. Seat 32A window.",
    time: "16:38",
    accent: "signal" as const,
  },
  {
    title: "Delay expected · +40m",
    body: "Inbound rake is running late. Predicted 5h before the railway said anything.",
    time: "11:55",
    accent: "sun" as const,
  },
  {
    title: "Departed Mumbai Central",
    body: "Right on time. Next stop Borivali at 17:29.",
    time: "17:01",
    accent: "go" as const,
  },
  {
    title: "Crossed Vadodara · 128 km/h",
    body: "Running 6m early. Arrival now predicted 08:26.",
    time: "20:14",
    accent: "signal" as const,
  },
  {
    title: "Fog advisory · your route",
    body: "Speed restrictions after Mathura. We'll re-predict as it clears.",
    time: "5:40",
    accent: "sun" as const,
  },
  {
    title: "Arriving New Delhi · PF 2",
    body: "Exit via Gate 1 for the Metro. Baggage coach at the rear.",
    time: "8:22",
    accent: "signal" as const,
  },
];

/**
 * Straight notification columns flanking the device, outer cards ghosted.
 * One slot at a time swaps to the next bulletin, springing in from its own
 * side of the phone — the way flighty.com's hero cards slide in from ±200px.
 */
const GHOST_SLOTS = new Set([1, 4]);
const SWAP_ORDER = [0, 3, 1, 4, 2, 5]; // alternate sides so both columns feel alive

function Column({
  slots,
  side,
}: {
  slots: { notif: number; ver: number }[];
  side: "left" | "right";
}) {
  return (
    <div
      className={`hidden w-[300px] flex-col gap-6 lg:flex ${
        side === "left" ? "items-start" : "items-end"
      }`}
    >
      {slots.map(({ notif, ver }, i) => {
        const slotIndex = side === "left" ? i : i + 3;
        return (
          <div
            key={i}
            className={`transition-opacity duration-500 ${
              GHOST_SLOTS.has(slotIndex) ? "opacity-35" : "opacity-100"
            }`}
          >
            <div
              key={ver}
              className={
                ver === 0
                  ? ""
                  : side === "left"
                    ? "animate-slide-left motion-reduce:animate-none"
                    : "animate-slide-right motion-reduce:animate-none"
              }
            >
              <NotifCard {...NOTIFS[notif % NOTIFS.length]} />
            </div>
          </div>
        );
      })}
    </div>
  );
}

export function HeroOrbit() {
  const [slots, setSlots] = useState(
    () => Array.from({ length: 6 }, (_, i) => ({ notif: i, ver: 0 })),
  );
  const [mobileHead, setMobileHead] = useState(0);
  const pool = useRef(6);
  const turn = useRef(0);

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const id = setInterval(() => {
      const slot = SWAP_ORDER[turn.current % SWAP_ORDER.length];
      turn.current += 1;
      const nextNotif = pool.current;
      pool.current += 1;
      setSlots((prev) =>
        prev.map((s, i) =>
          i === slot ? { notif: nextNotif, ver: s.ver + 1 } : s,
        ),
      );
      setMobileHead((h) => h + 1);
    }, 2400);
    return () => clearInterval(id);
  }, []);

  return (
    <div className="relative mx-auto mt-16 flex max-w-6xl items-center justify-center gap-8">
      {/* soft screen-glow so the floating phone reads as lit, not pasted */}
      <div
        aria-hidden
        className="absolute left-1/2 top-1/2 h-[420px] w-[520px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-signal/[0.07] blur-3xl"
      />
      <Column slots={slots.slice(0, 3)} side="left" />
      <div className="relative shrink-0">
        <div className="animate-levitate motion-reduce:animate-none">
          <PhoneMock />
        </div>
        {/* single cycling card on small screens */}
        <div className="mx-auto -mt-10 w-[290px] lg:hidden">
          <div key={mobileHead} className="animate-rise">
            <NotifCard {...NOTIFS[mobileHead % NOTIFS.length]} />
          </div>
        </div>
      </div>
      <Column slots={slots.slice(3)} side="right" />
    </div>
  );
}
