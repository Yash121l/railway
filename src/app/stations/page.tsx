import Link from "next/link";
import {
  ArrowDownRight,
  ArrowRight,
  ArrowUpRight,
  CloudFog,
  Construction,
  Gauge,
  Info,
  Layers,
  TrainFront,
  TriangleAlert,
} from "lucide-react";
import type { Metadata } from "next";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { Starfield } from "@/components/marketing/Starfield";

const STATIONS_TITLE =
  "Indian Railways Station Boards, Platforms & Live Delays";
const STATIONS_DESCRIPTION =
  "Live boards for India's major railway stations — departures and arrivals, average delays, platform pressure, and what's disrupting the network right now.";

export const metadata: Metadata = {
  title: STATIONS_TITLE,
  description: STATIONS_DESCRIPTION,
  alternates: { canonical: "/stations" },
  openGraph: {
    type: "website",
    siteName: "Railly",
    locale: "en_IN",
    url: "/stations",
    title: `${STATIONS_TITLE} — Railly`,
    description: STATIONS_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: `${STATIONS_TITLE} — Railly`,
    description: STATIONS_DESCRIPTION,
  },
};

type Status = "go" | "sun" | "crit";

const STATUS = {
  go: { label: "Flowing", dot: "bg-go", pill: "text-ontime ring-ontime/25" },
  sun: { label: "Strained", dot: "bg-sun", pill: "text-[#8a6a00] ring-sun/40" },
  crit: { label: "Disrupted", dot: "bg-crit", pill: "text-crit ring-crit/30" },
} as const;

function StatusPill({ status, solid }: { status: Status; solid?: boolean }) {
  const s = STATUS[status];
  return (
    <span
      className={`inline-flex shrink-0 items-center gap-1.5 rounded-full py-1 pl-2 pr-2.5 text-[11px] font-bold ring-1 ${s.pill} ${
        solid ? "bg-white" : ""
      }`}
    >
      <span
        className={`h-1.5 w-1.5 rounded-full ${s.dot} ${status !== "go" ? "animate-pulse-dot" : ""}`}
      />
      {s.label}
    </span>
  );
}

/* ─────────────────────────  Preview banner  ───────────────────────── */

function PreviewBanner() {
  return (
    <section className="mx-auto max-w-6xl px-4 pt-8">
      <Reveal>
        <div className="flex items-center justify-center gap-2 rounded-2xl bg-sun/10 px-4 py-3 text-center text-[13px] font-semibold text-[#8a6a00] ring-1 ring-sun/25">
          <Info size={15} className="shrink-0" />
          Preview with sample data — live Station Intelligence ships with the app.
        </div>
      </Reveal>
    </section>
  );
}

/* ─────────────────────────  Featured live board  ───────────────────────── */

type BoardRow = {
  no: string;
  name: string;
  kind: "dep" | "arr";
  time: string;
  to: string;
  pf: string;
  status: Status;
  note: string;
};

const NDLS_BOARD: BoardRow[] = [
  { no: "12951", name: "Mumbai Rajdhani", kind: "dep", time: "16:25", to: "MMCT", pf: "3", status: "go", note: "On time" },
  { no: "12259", name: "Sealdah Duronto", kind: "dep", time: "16:50", to: "SDAH", pf: "7", status: "go", note: "On time" },
  { no: "12417", name: "Prayagraj Express", kind: "dep", time: "17:05", to: "PRYJ", pf: "12", status: "sun", note: "Delayed 20m" },
  { no: "12002", name: "Bhopal Shatabdi", kind: "arr", time: "17:12", to: "from RKMP", pf: "1", status: "go", note: "On time" },
  { no: "12621", name: "Tamil Nadu Express", kind: "arr", time: "17:40", to: "from MAS", pf: "9", status: "crit", note: "Late 1h 45m" },
  { no: "12283", name: "Ernakulam Duronto", kind: "dep", time: "18:00", to: "ERS", pf: "5", status: "go", note: "On time" },
];

function StationBoard() {
  return (
    <section className="mx-auto max-w-6xl px-4 pt-8">
      <Reveal>
        <div className="overflow-hidden rounded-3xl bg-ink ring-1 ring-white/[0.06]">
          {/* board header */}
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-white/[0.08] px-6 py-5">
            <div>
              <div className="flex items-center gap-2.5">
                <span className="tnum text-[26px] font-extrabold leading-none tracking-tight text-white">
                  NDLS
                </span>
                <StatusPill status="sun" />
              </div>
              <div className="mt-1 text-[13px] text-white/55">
                New Delhi · Northern Railway
              </div>
            </div>
            <div className="flex items-center gap-1.5 text-[12px] font-semibold text-white/60">
              <span className="h-1.5 w-1.5 rounded-full bg-white/30" />
              Sample board
            </div>
          </div>

          {/* split-flap style rows */}
          <div className="divide-y divide-white/[0.06]">
            {NDLS_BOARD.map((r) => {
              const late = r.status !== "go";
              return (
                <div
                  key={r.no}
                  className="grid grid-cols-[auto_1fr_auto] items-center gap-4 px-6 py-3.5 md:grid-cols-[92px_1fr_120px_auto]"
                >
                  <div className="tnum text-[18px] font-bold text-white">
                    {r.time}
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span
                        className={`flex h-5 w-5 items-center justify-center rounded-full ${
                          r.kind === "dep" ? "bg-white/10" : "bg-arc/20"
                        }`}
                      >
                        {r.kind === "dep" ? (
                          <ArrowUpRight size={12} className="text-white" />
                        ) : (
                          <ArrowDownRight size={12} className="text-arc" />
                        )}
                      </span>
                      <span className="truncate text-[15px] font-semibold text-white">
                        {r.name}
                      </span>
                    </div>
                    <div className="tnum mt-0.5 pl-7 text-[12px] text-white/60">
                      {r.no} · {r.kind === "dep" ? `to ${r.to}` : r.to}
                    </div>
                  </div>
                  <div className="hidden md:block">
                    <span className="rounded-md bg-gate px-2 py-1 text-[12px] font-bold text-black">
                      PF {r.pf}
                    </span>
                  </div>
                  <div
                    className={`tnum text-right text-[13px] font-semibold ${
                      late ? "text-[#ff8d7f]" : "text-go"
                    }`}
                  >
                    {r.note}
                  </div>
                </div>
              );
            })}
          </div>

          {/* board footer stats */}
          <div className="grid grid-cols-3 border-t border-white/[0.08] text-center">
            {[
              ["16", "Platforms"],
              ["~430", "Trains a day"],
              ["78%", "On time"],
            ].map(([v, l]) => (
              <div key={l} className="px-3 py-4">
                <div className="tnum text-[19px] font-bold text-white">{v}</div>
                <div className="mt-0.5 text-[11px] font-semibold uppercase tracking-[0.5px] text-white/60">
                  {l}
                </div>
              </div>
            ))}
          </div>
        </div>
        <p className="mt-3 text-center text-[12px] text-steel">
          Illustrative board — the app shows every live arrival and departure
          for all 9,161 stations.
        </p>
      </Reveal>
    </section>
  );
}

/* ─────────────────────────  Network metrics  ───────────────────────── */

const METRICS: [string, string, string][] = [
  ["9,161", "Stations tracked", "Every code in the network, from terminals to halts"],
  ["4,022", "Trains tracked", "Every mail, express and superfast in the offline catalogue"],
  ["14m", "Avg network delay", "Across mail & express, in a typical evening peak"],
  ["NR", "Busiest zone", "Northern Railway, by train count"],
];

function MetricsStrip() {
  return (
    <section className="mx-auto max-w-6xl px-4 py-16 md:py-20">
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {METRICS.map(([v, k, sub], i) => (
          <Reveal key={k} delay={(i % 4) * 60}>
            <div className="h-full rounded-2xl bg-linen p-5 ring-1 ring-black/[0.05]">
              <div className="tnum text-[30px] font-extrabold leading-none tracking-tight text-black">
                {v}
              </div>
              <div className="mt-2 text-[14px] font-bold text-black">{k}</div>
              <div className="mt-1 text-[12px] leading-relaxed text-steel">
                {sub}
              </div>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

/* ─────────────────────────  Station directory  ───────────────────────── */

type Station = {
  code: string;
  name: string;
  city: string;
  zone: string;
  status: Status;
  platforms: number;
  daily: string;
  ops: string;
};

const STATIONS: Station[] = [
  { code: "NDLS", name: "New Delhi", city: "New Delhi", zone: "Northern Railway", status: "sun", platforms: 16, daily: "430", ops: "Evening peak — departures avg 24m late" },
  { code: "HWH", name: "Howrah Junction", city: "Kolkata", zone: "Eastern Railway", status: "go", platforms: 23, daily: "600", ops: "34 live runs, avg arrival delay 7m" },
  { code: "CSMT", name: "C. Shivaji Maharaj Terminus", city: "Mumbai", zone: "Central Railway", status: "go", platforms: 18, daily: "1,200", ops: "Suburban & mail both to time" },
  { code: "MAS", name: "MGR Chennai Central", city: "Chennai", zone: "Southern Railway", status: "go", platforms: 30, daily: "550", ops: "18 departures next 2h, all on time" },
  { code: "SBC", name: "KSR Bengaluru City", city: "Bengaluru", zone: "South Western Railway", status: "go", platforms: 10, daily: "300", ops: "Avg departure delay 3m tonight" },
  { code: "SC", name: "Secunderabad Junction", city: "Hyderabad", zone: "South Central Railway", status: "go", platforms: 10, daily: "230", ops: "Yard congestion cleared — easing" },
  { code: "MMCT", name: "Mumbai Central", city: "Mumbai", zone: "Western Railway", status: "go", platforms: 5, daily: "150", ops: "Rajdhani & Tejas turning on time" },
  { code: "ADI", name: "Ahmedabad Junction", city: "Ahmedabad", zone: "Western Railway", status: "go", platforms: 12, daily: "220", ops: "Rakes turning to schedule" },
  { code: "PNBE", name: "Patna Junction", city: "Patna", zone: "East Central Railway", status: "sun", platforms: 10, daily: "200", ops: "Platform reallocations — arr 18m late" },
  { code: "LKO", name: "Lucknow Charbagh", city: "Lucknow", zone: "Northern Railway", status: "crit", platforms: 9, daily: "300", ops: "Line block Kanpur side — delays 40m+" },
  { code: "GHY", name: "Guwahati", city: "Guwahati", zone: "NF Railway", status: "sun", platforms: 7, daily: "70", ops: "Single-line near Kamakhya — 21m late" },
  { code: "BSB", name: "Varanasi Junction", city: "Varanasi", zone: "Northern Railway", status: "sun", platforms: 9, daily: "180", ops: "Holiday loading — dep avg 15m late" },
];

function StationDirectory() {
  return (
    <section className="mx-auto max-w-6xl px-4 pb-4">
      <Reveal>
        <div className="flex items-end justify-between">
          <div>
            <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
              Major stations, right now
            </h2>
            <p className="mt-2 max-w-xl text-[15px] leading-relaxed text-carbon">
              One honest status per station — platforms, daily traffic, and the
              single sentence that tells you whether tonight is smooth or not.
            </p>
          </div>
        </div>
      </Reveal>

      <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {STATIONS.map((st, i) => (
          <Reveal key={st.code} delay={(i % 3) * 60}>
            <div className="card-lift flex h-full flex-col rounded-2xl bg-linen p-5 ring-1 ring-black/[0.05]">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="tnum text-[24px] font-extrabold leading-none tracking-tight text-black">
                    {st.code}
                  </div>
                  <div className="mt-2 text-[14px] font-bold leading-snug text-black">
                    {st.name}
                  </div>
                  <div className="mt-0.5 text-[12px] text-steel">
                    {st.city} · {st.zone}
                  </div>
                </div>
                <StatusPill status={st.status} solid />
              </div>

              <div className="mt-4 flex items-center gap-4 text-[12px] text-carbon">
                <span className="inline-flex items-center gap-1.5">
                  <Layers size={13} className="text-fog" />
                  <b className="tnum font-bold text-black">{st.platforms}</b>{" "}
                  platforms
                </span>
                <span className="inline-flex items-center gap-1.5">
                  <TrainFront size={13} className="text-fog" />
                  <b className="tnum font-bold text-black">{st.daily}</b>/day
                </span>
              </div>

              <div className="mt-auto pt-4">
                <p className="border-t border-black/[0.06] pt-3 text-[13px] leading-relaxed text-carbon">
                  {st.ops}
                </p>
              </div>
            </div>
          </Reveal>
        ))}
      </div>
      <Reveal delay={80}>
        <p className="mt-6 text-center text-[13px] text-steel">
          A sample of major stations — open the app to search all 9,161.
        </p>
      </Reveal>
    </section>
  );
}

/* ─────────────────────────  Disruption feed  ───────────────────────── */

type Disruption = {
  icon: React.ComponentType<{ size?: number; className?: string }>;
  where: string;
  headline: string;
  detail: string;
  status: Status;
};

const DISRUPTIONS: Disruption[] = [
  {
    icon: CloudFog,
    where: "Itarsi–Bhopal section",
    headline: "Dense fog brings a speed restriction",
    detail: "Trains get regulated to 60 km/h through a fog window, with extensions common past dawn.",
    status: "sun",
  },
  {
    icon: Construction,
    where: "Kanpur–Lucknow line",
    headline: "Engineering block on the down line",
    detail: "Single-line working can push arrivals into LKO around 40 minutes late.",
    status: "crit",
  },
  {
    icon: TriangleAlert,
    where: "Vijayawada yard",
    headline: "Platform reallocation after a late rake",
    detail: "Coromandel-route services get shifted platforms when a rake runs late.",
    status: "sun",
  },
  {
    icon: Gauge,
    where: "Mughalsarai (DDU) approach",
    headline: "Priority path clears, delays recover",
    detail: "Once a held express gets a path, an average delay recovers from ~35m toward ~12m.",
    status: "go",
  },
];

function DisruptionFeed() {
  return (
    <section className="mx-auto max-w-6xl px-4 py-16 md:py-20">
      <Reveal>
        <div className="flex items-center gap-2.5">
          <span className="h-2 w-2 animate-pulse-dot rounded-full bg-crit" />
          <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
            What can disrupt the network
          </h2>
        </div>
        <p className="mt-2 max-w-xl text-[15px] leading-relaxed text-carbon">
          Reading control-room bulletins and turning them into plain language is
          on Railly&apos;s roadmap — so you&apos;ll see the cause behind a delay,
          not just the number. The examples below show what that looks like.
        </p>
      </Reveal>

      <div className="mt-8 grid gap-3 md:grid-cols-2">
        {DISRUPTIONS.map((d, i) => (
          <Reveal key={d.where} delay={(i % 2) * 70}>
            <div className="flex h-full gap-4 rounded-2xl bg-white p-5 ring-1 ring-black/[0.06]">
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-linen">
                <d.icon size={18} className="text-carbon" />
              </span>
              <div className="min-w-0">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-[13px] font-bold text-black">
                    {d.where}
                  </span>
                  <StatusPill status={d.status} solid />
                </div>
                <div className="mt-1 text-[14px] font-semibold text-black">
                  {d.headline}
                </div>
                <p className="mt-1 text-[13px] leading-relaxed text-carbon">
                  {d.detail}
                </p>
              </div>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

/* ─────────────────────────  What it watches (dark)  ───────────────────────── */

const WATCHES = [
  [
    "Arrivals & departures",
    "Every live run in and out of a station, with the time, platform, and how late — the board, always current.",
  ],
  [
    "Delay causes",
    "Fog banks, rake shortages, yard congestion, engineering blocks — the reasons control rooms trade in, decoded.",
  ],
  [
    "Platform pressure",
    "Which platforms are turning rakes fast and which are backing up, so you know where the crush will be.",
  ],
] as const;

function WatchBand() {
  return (
    <section className="relative overflow-hidden bg-midnight px-4 py-20 text-white md:py-28">
      <Starfield className="opacity-60" />
      <div className="relative mx-auto max-w-6xl">
        <Reveal className="mx-auto max-w-3xl text-center">
          <h2 className="text-headline md:text-[44px] md:leading-[1.05] md:tracking-[-0.5px]">
            What Station Intelligence watches
          </h2>
          <p className="mt-5 text-[17px] leading-relaxed text-silver">
            Station Intelligence is designed to distill control-room bulletins
            from across the network into a single status. Here&apos;s what will
            feed it.
          </p>
        </Reveal>
        <div className="mt-12 grid gap-4 md:grid-cols-3">
          {WATCHES.map(([title, body], i) => (
            <Reveal key={title} delay={i * 80}>
              <div className="h-full rounded-3xl bg-white/[0.04] p-8 ring-1 ring-white/[0.06]">
                <div className="text-[13px] font-bold tabular-nums text-sun">
                  {String(i + 1).padStart(2, "0")}
                </div>
                <h3 className="mt-3 text-[17px] font-bold text-white">
                  {title}
                </h3>
                <p className="mt-2 text-[14px] leading-relaxed text-white/55">
                  {body}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
        <Reveal delay={160}>
          <div className="mt-12 text-center">
            <Link
              href="/#network"
              className="inline-flex items-center gap-1.5 text-[15px] font-semibold text-arc transition-colors hover:text-white"
            >
              See the network live
              <ArrowRight size={16} strokeWidth={2.2} />
            </Link>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

export default function StationsPage() {
  return (
    <PageShell>
      <PageHero
        eyebrow="STATIONS"
        title="Every junction, read like a control room."
        dek="Station Intelligence gives every major station a live board, an honest status, and the reason behind every delay — so you plan around the network instead of being surprised by it."
      />
      <PreviewBanner />
      <StationBoard />
      <MetricsStrip />
      <StationDirectory />
      <DisruptionFeed />
      <WatchBand />
    </PageShell>
  );
}
