"use client";

import { useEffect, useState } from "react";
import { Armchair, Flag, LayoutGrid, Ticket, TrainFront } from "lucide-react";
import { APP_CTA_HREF, APP_CTA_LABEL } from "@/lib/cta";

const STOPS = [
  ["before-you-book", "Before you book", Armchair],
  ["before-you-board", "Before you board", Ticket],
  ["on-the-platform", "On the platform", TrainFront],
  ["passport", "After arrival", Flag],
] as const;

/**
 * flighty.com's dark segmented pill pinned to the viewport bottom — but
 * theirs highlights the leg of the journey you're reading. Ours now does
 * too: a scroll-spy moves the amber highlight between segments.
 */
export function JourneyBar() {
  const [active, setActive] = useState<string>(STOPS[0][0]);

  useEffect(() => {
    const io = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) setActive(entry.target.id);
        }
      },
      // a slim band around the viewport's middle decides the active leg
      { rootMargin: "-40% 0px -45% 0px" },
    );
    for (const [id] of STOPS) {
      const el = document.getElementById(id);
      if (el) io.observe(el);
    }
    return () => io.disconnect();
  }, []);

  return (
    <div className="pointer-events-none sticky bottom-6 z-40 flex justify-center px-4 pb-2">
      <div className="pointer-events-auto flex items-center gap-1 overflow-x-auto rounded-full bg-[#111318]/95 p-1.5 shadow-[0_10px_36px_rgba(0,0,0,0.35)] backdrop-blur no-scrollbar">
        {STOPS.map(([id, label, Icon]) => {
          const is = active === id;
          return (
            <a
              key={id}
              href={`#${id}`}
              className={`flex shrink-0 items-center gap-1.5 rounded-full px-4 py-2 text-[14px] transition-colors duration-300 ${
                is
                  ? "bg-sun font-semibold text-black"
                  : "font-medium text-white/85 hover:text-white"
              }`}
            >
              <Icon size={14} />
              {label}
            </a>
          );
        })}
        <span className="mx-1 h-5 w-px shrink-0 bg-white/20" />
        <a
          href={APP_CTA_HREF}
          className="flex shrink-0 items-center gap-1.5 rounded-full px-4 py-2 text-[14px] font-semibold text-white transition-transform active:scale-95"
        >
          <LayoutGrid size={14} />
          {APP_CTA_LABEL}
        </a>
      </div>
    </div>
  );
}
