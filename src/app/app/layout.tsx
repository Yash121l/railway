"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import {
  ArrowDownRight,
  ArrowUpRight,
  BookOpen,
  Check,
  Radar,
  TrainFront,
} from "lucide-react";
import { cityFor } from "@/lib/format";
import { fmtDay, fmtDuration, fmtTime, istDateISO } from "@/lib/time";
import type { HeldTrip } from "@/lib/trainbank";
import type { LiveStatus, TrainCategory } from "@/lib/types";

/**
 * The web port of the Railly app, framed the way Flighty's press shots do:
 * a bright phone-width device on a black table. Screens are white sheets that
 * float over a dark schematic map. This module owns the frame plus every
 * shared building block the four screens compose (there are no separate
 * component files in this lane).
 *
 * Honesty first: the live picture is projected from the real schedule, never a
 * live feed, so every position and ETA is badged "Estimated from schedule",
 * and a standing ribbon says the full experience is the iPhone app.
 */

export default function AppLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <div className="min-h-dvh bg-black">
      <div className="relative mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-black text-inkline shadow-[0_0_90px_rgba(0,0,0,0.9)]">
        <PreviewRibbon />
        <main className="min-h-dvh pb-24">{children}</main>
        <TabBar />
      </div>
    </div>
  );
}

function PreviewRibbon() {
  return (
    <div className="sticky top-0 z-50 flex items-center justify-center gap-2 border-b border-white/10 bg-black/85 px-4 py-2 text-center text-[12px] text-white/80 backdrop-blur-md">
      <span className="h-1.5 w-1.5 shrink-0 animate-pulse-dot rounded-full bg-go" />
      <span>
        Web preview — the full experience is the{" "}
        <Link href="/" className="font-semibold text-white underline underline-offset-2">
          iPhone app
        </Link>
      </span>
    </div>
  );
}

const TABS = [
  { href: "/app", label: "My Trips", icon: TrainFront },
  { href: "/app/track", label: "Track", icon: Radar },
  { href: "/app/logbook", label: "Logbook", icon: BookOpen },
] as const;

function TabBar() {
  const pathname = usePathname();
  return (
    <nav className="fixed bottom-0 left-1/2 z-40 w-full max-w-[430px] -translate-x-1/2 border-t border-hairline bg-white/90 pb-[max(env(safe-area-inset-bottom),10px)] pt-2 backdrop-blur-xl">
      <div className="grid grid-cols-3">
        {TABS.map(({ href, label, icon: Icon }) => {
          const active =
            href === "/app" ? pathname === "/app" : pathname.startsWith(href);
          return (
            <Link
              key={href}
              href={href}
              className={`flex flex-col items-center gap-1 py-1 ${
                active ? "text-inkline" : "text-faded"
              }`}
            >
              <Icon size={22} strokeWidth={active ? 2.4 : 1.8} />
              <span className={`text-[10px] ${active ? "font-bold" : "font-medium"}`}>
                {label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}

// MARK: shared hooks

/**
 * Client clock. Returns null until mounted so server HTML and the first client
 * render agree — live surfaces show a skeleton for one frame instead of a
 * hydration mismatch.
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

/** Set the document title without a server metadata export (screens are client). */
export function usePageTitle(title: string): void {
  useEffect(() => {
    document.title = `${title} — Railly`;
  }, [title]);
}

// MARK: livery monogram (TrainMark)

const LIVERY: Record<TrainCategory, { bg: string; mark: string }> = {
  rajdhani: { bg: "#c62828", mark: "RJ" },
  "vande-bharat": { bg: "#0d47a1", mark: "VB" },
  shatabdi: { bg: "#546e7a", mark: "SH" },
  duronto: { bg: "#2e7d32", mark: "DR" },
  tejas: { bg: "#ef6c00", mark: "TJ" },
  superfast: { bg: "#6a1b9a", mark: "SF" },
  express: { bg: "#37474f", mark: "EX" },
};

export function TrainMark({
  category,
  size = 28,
}: {
  category: TrainCategory;
  size?: number;
}) {
  const livery = LIVERY[category];
  return (
    <span
      className="inline-flex shrink-0 items-center justify-center rounded-full font-bold text-white"
      style={{
        width: size,
        height: size,
        background: livery.bg,
        fontSize: Math.round(size * 0.36),
        letterSpacing: "0.02em",
      }}
      aria-hidden
    >
      {livery.mark}
    </span>
  );
}

// MARK: the honest-estimate label

export function EstimateBadge({ className = "" }: { className?: string }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full bg-[#1c1e22]/90 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.06em] text-white/90 backdrop-blur ${className}`}
    >
      <span className="h-1.5 w-1.5 rounded-full bg-arc" />
      Estimated from schedule
    </span>
  );
}

// MARK: dark schematic maps (self-contained SVG — no tiles, no external deps)

type LngLat = readonly [number, number];

/** A fitted equirectangular projector into a WxH viewBox (longitude compressed by cos φ). */
function makeProjector(points: LngLat[], w: number, h: number, pad: number) {
  const lats = points.map((p) => p[1]);
  const midLat = (Math.min(...lats) + Math.max(...lats)) / 2;
  const k = Math.cos((midLat * Math.PI) / 180) || 1;
  const xs = points.map((p) => p[0] * k);
  const minX = Math.min(...xs);
  const maxX = Math.max(...xs);
  const minY = Math.min(...lats);
  const maxY = Math.max(...lats);
  const spanX = maxX - minX || 1;
  const spanY = maxY - minY || 1;
  const scale = Math.min((w - 2 * pad) / spanX, (h - 2 * pad) / spanY);
  const offX = (w - scale * spanX) / 2;
  const offY = (h - scale * spanY) / 2;
  return (lng: number, lat: number): LngLat => [
    offX + (lng * k - minX) * scale,
    h - (offY + (lat - minY) * scale),
  ];
}

function toPath(coords: LngLat[]): string {
  return coords
    .map((c, i) => `${i === 0 ? "M" : "L"}${c[0].toFixed(1)} ${c[1].toFixed(1)}`)
    .join(" ");
}

function splitRoute(live: LiveStatus): { done: LngLat[]; rest: LngLat[] } {
  const coords: LngLat[] = live.train.stops.map((s) => [s.lng, s.lat]);
  const pos: LngLat = [live.position.lng, live.position.lat];
  if (live.phase === "arrived") return { done: coords, rest: [] };
  if (live.phase !== "enroute") return { done: [], rest: coords };
  return {
    done: [...coords.slice(0, live.prevStopIdx + 1), pos],
    rest: [pos, ...coords.slice(live.nextStopIdx)],
  };
}

/** One route on a dark map — flown portion solid, remaining dimmed & dashed. */
export function RouteMap({
  live,
  className = "",
}: {
  live: LiveStatus;
  className?: string;
}) {
  const W = 400;
  const H = 320;
  const stops: LngLat[] = live.train.stops.map((s) => [s.lng, s.lat]);
  const project = makeProjector(stops, W, H, 34);
  const projStops = stops.map(([lng, lat]) => project(lng, lat));
  const { done, rest } = splitRoute(live);
  const doneP = done.map(([lng, lat]) => project(lng, lat));
  const restP = rest.map(([lng, lat]) => project(lng, lat));
  const marker = project(live.position.lng, live.position.lat);

  return (
    <svg
      viewBox={`0 0 ${W} ${H}`}
      preserveAspectRatio="xMidYMid slice"
      className={className}
      role="img"
      aria-label={`Schematic map of ${live.train.name}`}
    >
      <rect width={W} height={H} fill="#0b0f14" />
      <MapGraticule w={W} h={H} />
      {restP.length >= 2 && (
        <path
          d={toPath(restP)}
          fill="none"
          stroke="#7eb6f6"
          strokeOpacity={0.5}
          strokeWidth={2.5}
          strokeDasharray="1 6"
          strokeLinecap="round"
        />
      )}
      {doneP.length >= 2 && (
        <>
          <path d={toPath(doneP)} fill="none" stroke="#4d9fff" strokeOpacity={0.3} strokeWidth={8} strokeLinecap="round" strokeLinejoin="round" />
          <path d={toPath(doneP)} fill="none" stroke="#4d9fff" strokeWidth={3} strokeLinecap="round" strokeLinejoin="round" />
        </>
      )}
      {projStops.map((p, i) => (
        <circle key={i} cx={p[0]} cy={p[1]} r={2.6} fill="#0b0f14" stroke="rgba(255,255,255,0.7)" strokeWidth={1.4} />
      ))}
      <circle cx={marker[0]} cy={marker[1]} r={9} fill="rgba(77,159,255,0.28)" />
      <circle cx={marker[0]} cy={marker[1]} r={5} fill="#ffffff" stroke="#4d9fff" strokeWidth={2.6} />
    </svg>
  );
}

/** The ambient hero: every watched route as a faint arc, live trains as dots. */
export function NetworkMap({
  trips,
  className = "",
}: {
  trips: HeldTrip[];
  className?: string;
}) {
  const W = 400;
  const H = 360;
  // Fixed India-ish frame so the shape reads even with a handful of routes.
  const frame: LngLat[] = [
    [68, 8],
    [92, 30],
  ];
  const allStops: LngLat[] = trips.flatMap((t) => t.train.stops.map((s) => [s.lng, s.lat] as LngLat));
  const project = makeProjector(allStops.length >= 2 ? allStops : frame, W, H, 30);

  return (
    <svg
      viewBox={`0 0 ${W} ${H}`}
      preserveAspectRatio="xMidYMid slice"
      className={className}
      role="img"
      aria-label="Schematic map of tracked routes"
    >
      <rect width={W} height={H} fill="#080b10" />
      <MapGraticule w={W} h={H} />
      {trips.map((t) => {
        const path = toPath(t.train.stops.map((s) => project(s.lng, s.lat)));
        return (
          <g key={t.id}>
            <path d={path} fill="none" stroke="#4d9fff" strokeOpacity={0.22} strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" />
            <path d={path} fill="none" stroke="#7eb6f6" strokeOpacity={0.85} strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round" />
          </g>
        );
      })}
      {trips.flatMap((t) => {
        const first = t.train.stops[0];
        const last = t.train.stops[t.train.stops.length - 1];
        return [first, last].map((s, i) => {
          const p = project(s.lng, s.lat);
          return <circle key={`${t.id}-${i}`} cx={p[0]} cy={p[1]} r={2.4} fill="#080b10" stroke="rgba(255,255,255,0.85)" strokeWidth={1.4} />;
        });
      })}
      {trips
        .filter((t) => t.live.phase === "enroute")
        .map((t) => {
          const p = project(t.live.position.lng, t.live.position.lat);
          return (
            <g key={`m-${t.id}`}>
              <circle cx={p[0]} cy={p[1]} r={6} fill="rgba(77,159,255,0.3)" />
              <circle cx={p[0]} cy={p[1]} r={3.5} fill="#ffffff" stroke="#4d9fff" strokeWidth={2} />
            </g>
          );
        })}
    </svg>
  );
}

function MapGraticule({ w, h }: { w: number; h: number }) {
  const cols = 6;
  const rows = 5;
  const lines: React.ReactNode[] = [];
  for (let i = 1; i < cols; i++) {
    const x = (w / cols) * i;
    lines.push(<line key={`v${i}`} x1={x} y1={0} x2={x} y2={h} stroke="rgba(255,255,255,0.04)" strokeWidth={1} />);
  }
  for (let i = 1; i < rows; i++) {
    const y = (h / rows) * i;
    lines.push(<line key={`h${i}`} x1={0} y1={y} x2={w} y2={y} stroke="rgba(255,255,255,0.04)" strokeWidth={1} />);
  }
  return <g>{lines}</g>;
}

// MARK: trip row (My Trips / Track)

type Tone = "ontime" | "late" | "muted";

const TONE_TEXT: Record<Tone, string> = {
  ontime: "text-ontime",
  late: "text-latered",
  muted: "text-faded",
};
const TONE_BG: Record<Tone, string> = {
  ontime: "bg-ontime",
  late: "bg-latered",
  muted: "bg-faded",
};

function TimeCell({
  kind,
  code,
  time,
  tone,
  nextDay,
}: {
  kind: "dep" | "arr";
  code: string;
  time: Date;
  tone: Tone;
  nextDay?: boolean;
}) {
  const Arrow = kind === "dep" ? ArrowUpRight : ArrowDownRight;
  return (
    <span className="flex items-center gap-1.5">
      <span className={`flex h-[18px] w-[18px] items-center justify-center rounded-full ${TONE_BG[tone]}`}>
        <Arrow size={12} strokeWidth={3} className="text-white" />
      </span>
      <span className={`text-[15px] font-semibold ${TONE_TEXT[tone]} opacity-80`}>{code}</span>
      <span className={`tnum text-[16px] font-bold ${TONE_TEXT[tone]}`}>
        {fmtTime(time)}
        {nextDay && <sup className="text-[10px] font-bold">+1</sup>}
      </span>
    </span>
  );
}

function Rail({ trip, now }: { trip: HeldTrip; now: Date }) {
  const { live } = trip;

  if (live.phase === "enroute" || live.phase === "boarding") {
    return (
      <div className="flex w-[72px] shrink-0 flex-col items-center gap-1.5 pt-1">
        <span className="flex h-11 w-11 items-center justify-center rounded-full bg-fill">
          <TrainFront size={20} className="text-inkline" />
        </span>
        <span className="text-[10px] font-bold uppercase tracking-[0.08em] text-faded">
          {live.phase === "enroute" ? "On rails" : "Boarding"}
        </span>
      </div>
    );
  }

  if (live.phase === "arrived") {
    return (
      <div className="flex w-[72px] shrink-0 flex-col items-center gap-1.5 pt-1">
        <span className="flex h-11 w-11 items-center justify-center rounded-full bg-fill">
          <Check size={20} className="text-sub" />
        </span>
        <span className="text-[10px] font-bold uppercase tracking-[0.08em] text-faded">
          Arrived
        </span>
      </div>
    );
  }

  const mins = Math.max(0, (live.stopTimings[0].depEst.getTime() - now.getTime()) / 60_000);
  let value: string;
  let caption: string;
  if (mins >= 48 * 60) {
    const days = Math.round(mins / (24 * 60));
    value = String(days);
    caption = days === 1 ? "day" : "days";
  } else if (mins >= 60) {
    value = `${Math.floor(mins / 60)}h`;
    caption = `${Math.round(mins % 60)} minutes`;
  } else {
    value = String(Math.max(1, Math.round(mins)));
    caption = "minutes";
  }
  return (
    <div className="w-[72px] shrink-0 pt-0.5 text-center">
      <div className="text-[32px] font-extrabold leading-none tracking-tight text-inkline">{value}</div>
      <div className="mt-1 text-[10px] font-bold uppercase tracking-[0.08em] text-faded">{caption}</div>
    </div>
  );
}

function StatusText({ trip, now }: { trip: HeldTrip; now: Date }) {
  const { live } = trip;
  const late = live.delayMin > 5;

  if (live.phase === "enroute") {
    const remaining = Math.max(0, (live.arrivesEst.getTime() - now.getTime()) / 60_000);
    return (
      <span className={`font-bold ${late ? "text-latered" : "text-ontime"}`}>
        Arriving in {fmtDuration(remaining)}
      </span>
    );
  }
  if (live.phase === "arrived") {
    return <span className="text-faded">{fmtDay(live.arrivesEst)}</span>;
  }
  const farOut = live.departsAt.getTime() - now.getTime() > 36 * 3_600_000;
  if (farOut) return <span className="text-faded">{fmtDay(live.departsAt)}</span>;
  return (
    <span className="text-sub">
      Departs{" "}
      <span className={`font-bold ${late ? "text-latered" : "text-ontime"}`}>
        {late ? `${live.delayMin}m late` : "On Time"}
      </span>
    </span>
  );
}

/** One journey, one dense line — the Dec-2025 Flighty row anatomy. */
export function TripRow({
  trip,
  now,
  divider = true,
}: {
  trip: HeldTrip;
  now: Date;
  divider?: boolean;
}) {
  const { train, live } = trip;
  const n = train.stops.length;
  const origin = train.stops[0];
  const dest = train.stops[n - 1];
  const depT = live.stopTimings[0];
  const arrT = live.stopTimings[n - 1];
  const isPast = live.phase === "arrived";

  const depTone: Tone = isPast ? "muted" : depT.delayMin > 5 ? "late" : "ontime";
  const arrTone: Tone = isPast ? "muted" : arrT.delayMin > 5 ? "late" : "ontime";
  const nextDay = istDateISO(arrT.arrEst) !== istDateISO(depT.depEst);

  return (
    <Link
      href={`/app/trip/${trip.id}`}
      className={`flex gap-2 pt-4 transition-colors active:bg-fill/60 ${isPast ? "opacity-60" : ""}`}
    >
      <Rail trip={trip} now={now} />
      <div className={`min-w-0 flex-1 pb-4 ${divider ? "border-b border-hairline" : ""}`}>
        <div className="flex items-center gap-2">
          <TrainMark category={train.category} size={20} />
          <span className="tnum text-[15px] text-sub">{train.number}</span>
          <span className="ml-auto text-[15px]">
            <StatusText trip={trip} now={now} />
          </span>
        </div>
        <div className="mt-1 truncate text-[21px] leading-tight text-inkline">
          <span className="font-bold">{cityFor(origin.code, origin.name)}</span>
          <span className="text-sub"> to </span>
          <span className="font-bold">{cityFor(dest.code, dest.name)}</span>
        </div>
        <div className="mt-1.5 flex items-center justify-between gap-2">
          <TimeCell kind="dep" code={origin.code} time={depT.depEst} tone={depTone} />
          <TimeCell kind="arr" code={dest.code} time={arrT.arrEst} tone={arrTone} nextDay={nextDay} />
        </div>
      </div>
    </Link>
  );
}
