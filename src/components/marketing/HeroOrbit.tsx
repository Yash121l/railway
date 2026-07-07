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
    body: "Your inbound rake is running late. Predicted 5h before the railway said anything.",
    time: "11:55",
    accent: "sun" as const,
  },
];

/** Positions orbiting the phone — slight tilts, never gridded. */
const SLOTS = [
  { className: "left-0 top-6 hidden lg:block", tilt: -3 },
  { className: "left-6 bottom-16 hidden lg:block", tilt: 2 },
  { className: "right-0 top-16 hidden lg:block", tilt: 3 },
  { className: "right-4 bottom-6 hidden lg:block", tilt: -2 },
];

export function HeroOrbit() {
  const [head, setHead] = useState(0);

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const id = setInterval(() => setHead((h) => h + 1), 3200);
    return () => clearInterval(id);
  }, []);

  return (
    <div className="relative mx-auto mt-14 max-w-5xl">
      {SLOTS.map((slot, i) => {
        const notif = NOTIFS[(head + i) % NOTIFS.length];
        return (
          <div key={i} className={`absolute z-10 ${slot.className}`}>
            <div key={head} className="animate-rise">
              <NotifCard {...notif} tilt={slot.tilt} />
            </div>
          </div>
        );
      })}

      <PhoneMock />

      {/* single scattered card on small screens so the signature survives mobile */}
      <div className="absolute -bottom-5 left-1/2 z-10 w-[290px] -translate-x-1/2 lg:hidden">
        <div key={head} className="animate-rise">
          <NotifCard {...NOTIFS[head % NOTIFS.length]} tilt={-2} />
        </div>
      </div>
    </div>
  );
}
