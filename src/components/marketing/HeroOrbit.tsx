"use client";

import { useEffect, useRef, useState } from "react";
import { NotifCard } from "./NotifCard";
import { PhoneMock } from "./PhoneMock";

const NOTIFS = [
  {
    title: "MMCT → NDLS · On Time",
    body: "Good morning! Your Rajdhani departs 17:00 from PF 2.",
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
 * The flighty.com hero, faithfully: on load the notification cards fly in
 * from ±200px on a spring, one per beat; while you scroll away, the two
 * columns part around the phone and the phone lags behind the page — the
 * scroll-scrubbed choreography their Framer runtime drives.
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
      data-hero-col={side}
      className={`hidden w-[300px] flex-col gap-6 will-change-transform lg:flex ${
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
                  ? side === "left"
                    ? "fly-in-left"
                    : "fly-in-right"
                  : side === "left"
                    ? "animate-slide-left motion-reduce:animate-none"
                    : "animate-slide-right motion-reduce:animate-none"
              }
              style={
                ver === 0
                  ? ({ "--stagger": `${380 + slotIndex * 130}ms` } as React.CSSProperties)
                  : undefined
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
  const stage = useRef<HTMLDivElement>(null);

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

  // Scroll scrub: columns part outward, the phone trails the page slightly.
  useEffect(() => {
    const el = stage.current;
    if (!el) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const left = el.querySelector<HTMLElement>("[data-hero-col=left]");
    const right = el.querySelector<HTMLElement>("[data-hero-col=right]");
    const phone = el.querySelector<HTMLElement>("[data-hero-phone]");
    let ticking = false;

    const apply = () => {
      ticking = false;
      const top = el.getBoundingClientRect().top;
      const p = Math.min(1, Math.max(0, -top / 520));
      if (left) left.style.transform = `translate3d(${(-130 * p).toFixed(1)}px,0,0)`;
      if (right) right.style.transform = `translate3d(${(130 * p).toFixed(1)}px,0,0)`;
      if (phone) phone.style.transform = `translate3d(0,${(70 * p).toFixed(1)}px,0)`;
    };
    const onScroll = () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(apply);
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    apply();
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <div
      ref={stage}
      className="relative mx-auto mt-16 flex max-w-6xl items-center justify-center gap-8"
    >
      {/* soft screen-glow so the floating phone reads as lit, not pasted */}
      <div
        aria-hidden
        className="absolute left-1/2 top-1/2 h-[420px] w-[520px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-signal/[0.07] blur-3xl"
      />
      <Column slots={slots.slice(0, 3)} side="left" />
      <div data-hero-phone className="relative shrink-0 will-change-transform">
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
