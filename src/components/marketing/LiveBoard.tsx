"use client";

import { useEffect, useRef, useState } from "react";

type Row = {
  no: string;
  route: string;
  status: string;
  tone: "sun" | "go" | "signal" | "crit";
};

const TONE: Record<Row["tone"], string> = {
  sun: "text-sun bg-sun/15",
  go: "text-go bg-go/15",
  signal: "text-[#4da3ff] bg-signal/15",
  crit: "text-crit bg-crit/15",
};

/** Each row cycles through a believable evening of updates. */
const FEEDS: { no: string; route: string; states: [string, Row["tone"]][] }[] = [
  {
    no: "12627",
    route: "Bengaluru → New Delhi",
    states: [
      ["DELAYED +20M", "sun"],
      ["DELAYED +25M", "sun"],
      ["RECOVERING", "go"],
      ["DELAYED +18M", "sun"],
    ],
  },
  {
    no: "12841",
    route: "Kolkata → Chennai",
    states: [
      ["ON TIME", "go"],
      ["DEPARTED PF 9", "go"],
      ["ON TIME", "go"],
      ["71 KM/H", "signal"],
    ],
  },
  {
    no: "22436",
    route: "New Delhi → Varanasi",
    states: [
      ["ON TIME", "go"],
      ["ARRIVING KANPUR", "signal"],
      ["PF CHANGE → 4", "crit"],
      ["ON TIME", "go"],
    ],
  },
  {
    no: "12951",
    route: "Mumbai → New Delhi",
    states: [
      ["BOARDING", "signal"],
      ["COACH C4 AT PF 2", "signal"],
      ["DEPARTED", "go"],
      ["ON TIME", "go"],
    ],
  },
];

/**
 * The network board is alive: one row at a time flips to its next bulletin
 * with a split-flap-style bottom-hinged swing. Sleeps offscreen and under
 * reduced motion — the first bulletin of each feed is real content on its own.
 */
export function LiveBoard() {
  const [steps, setSteps] = useState<number[]>(() => FEEDS.map(() => 0));
  const [flipping, setFlipping] = useState(-1);
  const boardRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const el = boardRef.current;
    if (!el) return;

    let timer: ReturnType<typeof setInterval> | undefined;
    let next = 0;
    const io = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !timer) {
        timer = setInterval(() => {
          const row = next % FEEDS.length;
          next += 1;
          setFlipping(row);
          setSteps((s) => s.map((v, i) => (i === row ? v + 1 : v)));
        }, 2600);
      } else if (!entry.isIntersecting && timer) {
        clearInterval(timer);
        timer = undefined;
      }
    });
    io.observe(el);
    return () => {
      io.disconnect();
      if (timer) clearInterval(timer);
    };
  }, []);

  return (
    <div
      ref={boardRef}
      className="relative mx-auto mt-12 max-w-3xl overflow-hidden rounded-3xl bg-ink ring-1 ring-white/[0.08]"
    >
      <div className="flex items-center justify-between border-b border-white/[0.08] px-5 py-3.5">
        <span className="text-[13px] font-bold uppercase tracking-[1px] text-white/60">
          Network board · live
        </span>
        <span className="flex items-center gap-1.5 text-[12px] font-semibold text-go">
          <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-go" />
          8 trains watched
        </span>
      </div>
      {FEEDS.map(({ no, route, states }, i) => {
        const [status, tone] = states[steps[i] % states.length];
        return (
          <div
            key={no}
            className="flex items-center gap-3 border-b border-white/[0.06] px-5 py-3.5 last:border-0"
          >
            <span className="tnum text-[14px] font-bold text-white">{no}</span>
            <span className="flex-1 truncate text-[14px] text-white/60">
              {route}
            </span>
            <span
              key={steps[i]}
              className={`rounded-full px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.5px] ${TONE[tone]} ${
                flipping === i ? "animate-flap-in" : ""
              }`}
            >
              {status}
            </span>
          </div>
        );
      })}
    </div>
  );
}
