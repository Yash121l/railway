"use client";

import { useEffect, useRef } from "react";

/**
 * flighty.com's signature ambient effect: wide horizontal strips whose X
 * position is scrubbed by the scroll wheel, top row and bottom row moving
 * in opposite directions. Pure transform, rAF-throttled, asleep offscreen.
 */
export function ScrollScrub({
  children,
  amplitude = 130,
  className = "",
}: {
  children: React.ReactNode;
  /** total px of travel across the section's trip through the viewport */
  amplitude?: number;
  className?: string;
}) {
  const wrap = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = wrap.current;
    if (!el) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const rows = Array.from(
      el.querySelectorAll<HTMLElement>("[data-scrub-row]"),
    );
    if (!rows.length) return;

    let ticking = false;
    let inView = false;

    const apply = () => {
      ticking = false;
      const rect = el.getBoundingClientRect();
      const vh = window.innerHeight;
      // 0 → section top enters at the bottom; 1 → section bottom leaves at the top
      const progress = Math.min(
        1,
        Math.max(0, (vh - rect.top) / (vh + rect.height)),
      );
      const shift = (progress - 0.5) * amplitude;
      rows.forEach((row, i) => {
        const dir = i % 2 === 0 ? 1 : -1;
        row.style.transform = `translate3d(${(dir * shift).toFixed(1)}px, 0, 0)`;
      });
    };

    const onScroll = () => {
      if (!inView || ticking) return;
      ticking = true;
      requestAnimationFrame(apply);
    };

    const io = new IntersectionObserver(([entry]) => {
      inView = entry.isIntersecting;
      if (inView) onScroll();
    });
    io.observe(el);

    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll, { passive: true });
    apply();

    return () => {
      io.disconnect();
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
    };
  }, [amplitude]);

  return (
    <div ref={wrap} className={className}>
      {children}
    </div>
  );
}
