"use client";

import { useEffect, useState } from "react";

/**
 * Client clock. Returns null until mounted so server HTML and first client
 * render agree — every live surface shows a skeleton for one frame instead
 * of a hydration mismatch.
 */
export function useNow(intervalMs = 1000): Date | null {
  const [now, setNow] = useState<Date | null>(null);
  useEffect(() => {
    const tick = () => setNow(new Date());
    const first = setTimeout(tick, 0);
    const id = setInterval(tick, intervalMs);
    return () => {
      clearTimeout(first);
      clearInterval(id);
    };
  }, [intervalMs]);
  return now;
}
