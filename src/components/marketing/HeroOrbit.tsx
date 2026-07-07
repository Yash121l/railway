"use client";

import { useEffect, useState } from "react";
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
];

/**
 * Straight notification columns flanking the device, outer cards ghosted —
 * the real site scatters opacity, not rotation.
 */
const LEFT = [
  { idx: 0, ghost: false },
  { idx: 1, ghost: true },
  { idx: 2, ghost: false },
];
const RIGHT = [
  { idx: 3, ghost: false },
  { idx: 4, ghost: true },
  { idx: 5, ghost: false },
];

function Column({
  slots,
  head,
  align,
}: {
  slots: { idx: number; ghost: boolean }[];
  head: number;
  align: "left" | "right";
}) {
  return (
    <div
      className={`hidden w-[300px] flex-col gap-6 lg:flex ${
        align === "left" ? "items-start" : "items-end"
      }`}
    >
      {slots.map(({ idx, ghost }) => {
        const notif = NOTIFS[(head + idx) % NOTIFS.length];
        return (
          <div
            key={idx}
            className={ghost ? "opacity-35" : "opacity-100"}
          >
            <div key={head} className="animate-rise">
              <NotifCard {...notif} />
            </div>
          </div>
        );
      })}
    </div>
  );
}

export function HeroOrbit() {
  const [head, setHead] = useState(0);

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const id = setInterval(() => setHead((h) => h + 1), 3600);
    return () => clearInterval(id);
  }, []);

  return (
    <div className="relative mx-auto mt-16 flex max-w-6xl items-center justify-center gap-8">
      <Column slots={LEFT} head={head} align="left" />
      <div className="shrink-0">
        <PhoneMock />
        {/* single cycling card on small screens */}
        <div className="mx-auto -mt-10 w-[290px] lg:hidden">
          <div key={head} className="animate-rise">
            <NotifCard {...NOTIFS[head % NOTIFS.length]} />
          </div>
        </div>
      </div>
      <Column slots={RIGHT} head={head} align="right" />
    </div>
  );
}
