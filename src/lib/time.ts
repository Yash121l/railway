import type { Day } from "./types";

/** All schedules are IST; India has no DST so a fixed offset is exact. */
export const IST_OFFSET_MIN = 330;

export const DAYS: Day[] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

/** Date for a YYYY-MM-DD + minutes-past-midnight, both interpreted in IST */
export function istDateTime(dateISO: string, minutes: number): Date {
  const [y, m, d] = dateISO.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d) + (minutes - IST_OFFSET_MIN) * 60_000);
}

/** YYYY-MM-DD of a Date as seen in IST */
export function istDateISO(date: Date): string {
  return new Date(date.getTime() + IST_OFFSET_MIN * 60_000)
    .toISOString()
    .slice(0, 10);
}

export function istWeekday(dateISO: string): Day {
  const [y, m, d] = dateISO.split("-").map(Number);
  return DAYS[new Date(Date.UTC(y, m - 1, d)).getUTCDay()];
}

export function addDaysISO(dateISO: string, delta: number): string {
  const [y, m, d] = dateISO.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d + delta)).toISOString().slice(0, 10);
}

export function parseHM(hm: string): number {
  const [h, m] = hm.split(":").map(Number);
  return h * 60 + m;
}

const timeFmt = new Intl.DateTimeFormat("en-GB", {
  hour: "2-digit",
  minute: "2-digit",
  hour12: false,
  timeZone: "Asia/Kolkata",
});

const dayFmt = new Intl.DateTimeFormat("en-IN", {
  weekday: "short",
  day: "numeric",
  month: "short",
  timeZone: "Asia/Kolkata",
});

/** "17:05" in IST */
export function fmtTime(date: Date): string {
  return timeFmt.format(date);
}

/** "Mon 7 Jul" in IST */
export function fmtDay(date: Date): string {
  return dayFmt.format(date);
}

/** "15h 32m" */
export function fmtDuration(minutes: number): string {
  const m = Math.round(minutes);
  const h = Math.floor(m / 60);
  const rest = m % 60;
  if (h === 0) return `${rest}m`;
  if (rest === 0) return `${h}h`;
  return `${h}h ${rest}m`;
}

/** "in 2h 5m" / "2h 5m ago" */
export function fmtRelative(target: Date, now: Date): string {
  const diffMin = Math.round((target.getTime() - now.getTime()) / 60_000);
  if (Math.abs(diffMin) < 1) return "now";
  const span = fmtDuration(Math.abs(diffMin));
  return diffMin > 0 ? `in ${span}` : `${span} ago`;
}
