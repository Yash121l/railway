"use client";

import { useEffect, useRef, useState } from "react";
import { NotifCard } from "./NotifCard";
import { PhoneMock } from "./PhoneMock";

/**
 * Only notifications the app really sends, worded the way PNRWatch and
 * TatkalReminder word them: PNR status changes, chart prepared, and the
 * Tatkal reminder you set. Trains and numbers are examples.
 */
const NOTIFS = [
  {
    title: "PNR confirmed",
    body: "Mumbai Rajdhani: your ticket is confirmed, B8 57.",
    time: "19:12",
    accent: "go" as const,
    mark: "RJ",
    markColor: "#C62828",
  },
  {
    title: "Waitlist moving",
    body: "Karnataka Express: GNWL 21 → GNWL 9.",
    time: "14:05",
    accent: "sun" as const,
    mark: "SF",
    markColor: "#6A1B9A",
  },
  {
    title: "Chart prepared",
    body: "ADI Shatabdi Express: the chart is out. Your PNR status and coach position are now final.",
    time: "22:10",
    accent: "signal" as const,
    mark: "SH",
    markColor: "#546E7A",
  },
  {
    title: "Tatkal opens soon",
    body: "Mumbai Rajdhani: AC 3 Tier Tatkal opens at 10:00 IST. Be ready to book.",
    time: "9:45",
    accent: "sun" as const,
    mark: "RJ",
    markColor: "#C62828",
  },
  {
    title: "Moved to RAC",
    body: "Karnataka Express: now RAC 12. You can board.",
    time: "11:55",
    accent: "sun" as const,
    mark: "SF",
    markColor: "#6A1B9A",
  },
  {
    title: "PNR confirmed",
    body: "ADI Shatabdi Express: all passengers confirmed, C3 69.",
    time: "18:40",
    accent: "go" as const,
    mark: "SH",
    markColor: "#546E7A",
  },
  {
    title: "Waitlist moving",
    body: "Vande Bharat: WL 14 → WL 6.",
    time: "16:20",
    accent: "sun" as const,
    mark: "VB",
    markColor: "#0D47A1",
  },
  {
    title: "Chart prepared",
    body: "Mumbai Rajdhani: the chart is out. Your PNR status and coach position are now final.",
    time: "8:40",
    accent: "signal" as const,
    mark: "RJ",
    markColor: "#C62828",
  },
  {
    title: "Tatkal opens soon",
    body: "Coromandel Express: Sleeper Tatkal opens at 11:00 IST. Be ready to book.",
    time: "10:45",
    accent: "sun" as const,
    mark: "SF",
    markColor: "#6A1B9A",
  },
  {
    title: "Moved to RAC",
    body: "Howrah Rajdhani: now RAC 3. You can board.",
    time: "13:30",
    accent: "sun" as const,
    mark: "RJ",
    markColor: "#C62828",
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
    const el = stage.current;
    if (!el) return;
    let id: ReturnType<typeof setInterval> | null = null;
    const tick = () => {
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
    };
    // only swap while the hero is on screen — no work for an idle backgrounded tab
    const io = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        if (id === null) id = setInterval(tick, 2400);
      } else if (id !== null) {
        clearInterval(id);
        id = null;
      }
    });
    io.observe(el);
    return () => {
      if (id !== null) clearInterval(id);
      io.disconnect();
    };
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
