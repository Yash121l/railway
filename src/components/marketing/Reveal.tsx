"use client";

import { useEffect, useRef, useState } from "react";

type Phase = "ssr" | "hidden" | "shown";

/**
 * Framer-style scroll reveal. Server HTML ships fully visible (LCP and
 * no-JS safe); after hydration, only elements still below the fold are
 * hidden and then revealed as they enter the viewport.
 */
export function Reveal({
  children,
  delay = 0,
  className = "",
}: {
  children: React.ReactNode;
  delay?: number;
  className?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [phase, setPhase] = useState<Phase>("ssr");

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    let io: IntersectionObserver | undefined;
    const raf = requestAnimationFrame(() => {
      if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
      // Never hide something the user can already see.
      if (el.getBoundingClientRect().top < window.innerHeight * 0.95) return;
      setPhase("hidden");
      io = new IntersectionObserver(
        ([entry]) => {
          if (entry.isIntersecting) {
            setPhase("shown");
            io?.disconnect();
          }
        },
        { threshold: 0.12 },
      );
      io.observe(el);
    });
    return () => {
      cancelAnimationFrame(raf);
      io?.disconnect();
    };
  }, []);

  const motion =
    phase === "hidden"
      ? "translate-y-5 opacity-0"
      : phase === "shown"
        ? "translate-y-0 opacity-100 transition-all duration-700 ease-[cubic-bezier(0.16,1,0.3,1)]"
        : "";

  return (
    <div
      ref={ref}
      className={`${className} ${motion}`}
      style={phase === "shown" ? { transitionDelay: `${delay}ms` } : undefined}
    >
      {children}
    </div>
  );
}
