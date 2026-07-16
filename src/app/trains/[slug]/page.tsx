import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import {
  ArrowLeft,
  ArrowRight,
  CalendarDays,
  ChevronDown,
  Clock,
  MapPin,
  Route,
  TrainFront,
} from "lucide-react";
import { APP_CTA_HREF } from "@/lib/cta";
import { PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { JsonLd } from "@/components/seo/JsonLd";
import seed from "@/data/seed-trains.json";

/* ------------------------------------------------------------------ */
/* Data                                                                */
/* ------------------------------------------------------------------ */

export type Stop = {
  name: string;
  code: string;
  lat: number;
  lng: number;
  arrMin: number;
  depMin: number;
  platform: string | null;
};

export type SeedTrain = {
  number: string;
  name: string;
  category: string;
  departureTime: string;
  days: string[];
  distanceKm: number;
  trainId: number;
  typeName: string;
  stops: Stop[];
  classes: string[];
};

export const TRAINS = seed as SeedTrain[];

/** Well-known display names for the seed trains — all real services. */
const NICE_NAMES: Record<string, string> = {
  "12951": "Mumbai Rajdhani",
  "12301": "Howrah Rajdhani",
  "22436": "New Delhi–Varanasi Vande Bharat",
  "20901": "Mumbai–Gandhinagar Vande Bharat",
  "12009": "Mumbai–Ahmedabad Shatabdi",
  "12259": "Sealdah–Bikaner Duronto",
  "12841": "Coromandel Express",
  "12627": "Karnataka Express",
  "12002": "Bhopal Shatabdi",
  "12622": "Tamil Nadu Express",
  "12309": "Patna Rajdhani",
  "12137": "Punjab Mail",
};

const TYPE_LABELS: Record<string, string> = {
  rajdhani: "Rajdhani",
  "vande-bharat": "Vande Bharat",
  shatabdi: "Shatabdi",
  superfast: "Superfast",
};

const CLASS_NAMES: Record<string, string> = {
  "1A": "AC First Class",
  "2A": "AC 2-Tier",
  "3A": "AC 3-Tier",
  "3E": "AC 3-Tier Economy",
  CC: "AC Chair Car",
  EC: "Executive Chair Car",
  EA: "Executive Anubhuti",
  EV: "Vistadome",
  SL: "Sleeper",
  GN: "Second Sitting / General",
  "2S": "Second Sitting",
};

const AC_CLASSES = new Set(["1A", "2A", "3A", "3E", "CC", "EC", "EA", "EV"]);

function kebab(s: string) {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function trainDisplayName(t: SeedTrain) {
  return NICE_NAMES[t.number] ?? t.name;
}

export function trainSlug(t: SeedTrain) {
  return `${t.number}-${kebab(trainDisplayName(t))}`;
}

export function trainTypeLabel(t: SeedTrain) {
  return TYPE_LABELS[t.category] ?? t.typeName;
}

function parseClock(hhmm: string) {
  const [h, m] = hhmm.split(":").map(Number);
  return h * 60 + m;
}

function fmtClock(min: number) {
  const m = ((min % 1440) + 1440) % 1440;
  return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}

function dayOf(base: number, offset: number) {
  return Math.floor((base + offset) / 1440) + 1;
}

function haversine(a: Stop, b: Stop) {
  const R = 6371;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const s =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(s));
}

/** Cumulative km per stop, scaled so the last equals the route's stated length. */
function cumulativeKm(t: SeedTrain): number[] {
  const raw = [0];
  for (let i = 1; i < t.stops.length; i++) {
    raw[i] = raw[i - 1] + haversine(t.stops[i - 1], t.stops[i]);
  }
  const total = raw[raw.length - 1];
  const scale = total > 0 ? t.distanceKm / total : 1;
  return raw.map((r) => Math.round(r * scale));
}

function daysLabel(t: SeedTrain) {
  return t.days.length === 7 ? "Daily" : t.days.join(", ");
}

function durationLabel(t: SeedTrain) {
  const total = t.stops[t.stops.length - 1].arrMin;
  const h = Math.floor(total / 60);
  const m = total % 60;
  return m > 0 ? `${h}h ${m}m` : `${h}h`;
}

function trainFromSlug(slug: string) {
  return TRAINS.find((t) => trainSlug(t) === slug);
}

/* ------------------------------------------------------------------ */
/* Static params + metadata                                            */
/* ------------------------------------------------------------------ */

export const dynamicParams = false;

export function generateStaticParams() {
  return TRAINS.map((t) => ({ slug: trainSlug(t) }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const t = trainFromSlug(slug);
  if (!t) return {};

  const name = trainDisplayName(t);
  const origin = t.stops[0].name;
  const dest = t.stops[t.stops.length - 1].name;
  const runs =
    t.days.length === 7 ? "runs daily" : `runs on ${t.days.join(", ")}`;

  const title = `${t.number} ${name} — Live Running Status, Route & Schedule | Railly`;
  const description = `Full route, schedule and live running status for the ${t.number} ${name} — ${origin} to ${dest}, ${t.stops.length} stops, ${Math.round(t.distanceKm)} km, departs ${t.departureTime}, ${runs}. Track it live with Railly, built for iPhone.`;

  return {
    title: { absolute: title },
    description,
    alternates: { canonical: `/trains/${slug}` },
    openGraph: {
      type: "website",
      siteName: "Railly",
      locale: "en_IN",
      url: `/trains/${slug}`,
      title,
      description,
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
    },
  };
}

/* ------------------------------------------------------------------ */
/* Pieces                                                              */
/* ------------------------------------------------------------------ */

function Faq({ q, a }: { q: string; a: string }) {
  return (
    <details className="group rounded-2xl bg-linen ring-1 ring-black/[0.05]">
      <summary className="flex cursor-pointer list-none items-center justify-between gap-4 px-6 py-5 marker:content-none [&::-webkit-details-marker]:hidden">
        <span className="text-[16px] font-semibold leading-snug text-black">
          {q}
        </span>
        <ChevronDown
          size={18}
          strokeWidth={2}
          className="shrink-0 text-steel transition-transform duration-300 group-open:rotate-180"
        />
      </summary>
      <div className="px-6 pb-6 text-[15px] leading-relaxed text-carbon">
        <p>{a}</p>
      </div>
    </details>
  );
}

/* ------------------------------------------------------------------ */
/* Page                                                                */
/* ------------------------------------------------------------------ */

export default async function TrainPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const t = trainFromSlug(slug);
  if (!t) notFound();

  const name = trainDisplayName(t);
  const type = trainTypeLabel(t);
  const base = parseClock(t.departureTime);
  const km = cumulativeKm(t);
  const origin = t.stops[0];
  const dest = t.stops[t.stops.length - 1];
  const lastIndex = t.stops.length - 1;

  const chartAbs = base - 480;
  const chartClock = fmtClock(chartAbs);
  const chartWhen = chartAbs < 0 ? "the evening before" : "that morning";

  const acClasses = t.classes.filter((c) => AC_CLASSES.has(c));
  const nonAcClasses = t.classes.filter((c) => !AC_CLASSES.has(c));

  let tatkalA = `Tatkal opens one day before the journey date, counted from the train's origin at ${origin.name}. `;
  if (acClasses.length && nonAcClasses.length) {
    tatkalA += `For the ${name}, that's 10 AM for its AC classes (${acClasses.join(", ")}) and 11 AM for non-AC (${nonAcClasses.join(", ")}). `;
  } else if (acClasses.length) {
    tatkalA += `The ${name} is all-AC (${acClasses.join(", ")}), so its Tatkal window opens at 10 AM. `;
  } else {
    tatkalA += `The ${name} runs non-AC classes (${nonAcClasses.join(", ")}), so its Tatkal window opens at 11 AM. `;
  }
  tatkalA += `On busy routes the quota can be gone within minutes — Railly nudges you minutes ahead of the window if a journey you're watching is still waitlisted.`;

  const faqs = [
    {
      q: `When does the chart prepare for ${t.number} ${name}?`,
      a: `The reservation chart for the ${name} (${t.number}) is usually drawn up about eight hours before its ${t.departureTime} departure from ${origin.name} — roughly ${chartClock} ${chartWhen}. Until then a waitlisted or RAC ticket can still move. Railly watches the PNR right up to chart time and notifies you the moment it prepares, with your final status and, if you cleared, your coach and berth.`,
    },
    {
      q: `When does Tatkal booking open for ${t.number} ${name}?`,
      a: tatkalA,
    },
  ];

  const siblings = [
    ...TRAINS.filter((x) => x.number !== t.number && x.category === t.category),
    ...TRAINS.filter((x) => x.number !== t.number && x.category !== t.category),
  ].slice(0, 6);

  const graphJsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "BreadcrumbList",
        itemListElement: [
          {
            "@type": "ListItem",
            position: 1,
            name: "Home",
            item: "https://railly.app",
          },
          {
            "@type": "ListItem",
            position: 2,
            name: "Trains",
            item: "https://railly.app/trains",
          },
          {
            "@type": "ListItem",
            position: 3,
            name: `${t.number} ${name}`,
            item: `https://railly.app/trains/${slug}`,
          },
        ],
      },
      {
        "@type": "FAQPage",
        mainEntity: faqs.map((f) => ({
          "@type": "Question",
          name: f.q,
          acceptedAnswer: { "@type": "Answer", text: f.a },
        })),
      },
    ],
  };

  const stats: [React.ReactNode, string, string][] = [
    [<Route key="r" size={16} />, "Route", `${origin.code} → ${dest.code}`],
    [<MapPin key="d" size={16} />, "Distance", `${Math.round(t.distanceKm)} km`],
    [<Clock key="t" size={16} />, "Duration", durationLabel(t)],
    [<CalendarDays key="c" size={16} />, "Runs", daysLabel(t)],
  ];

  return (
    <PageShell>
      <JsonLd data={graphJsonLd} />

      <div className="mx-auto max-w-4xl px-4 pt-16 md:pt-24">
        <Link
          href="/trains"
          className="inline-flex items-center gap-1.5 text-[13px] font-semibold text-steel transition-colors hover:text-black"
        >
          <ArrowLeft size={15} strokeWidth={2.2} />
          All trains
        </Link>
      </div>

      {/* Header */}
      <header className="mx-auto max-w-4xl px-4 pt-6 md:pt-8">
        <div className="text-[12px] font-bold uppercase tracking-[2px] text-signal">
          {t.number} · {type}
        </div>
        <h1 className="mt-3 text-[36px] font-bold leading-[1.05] tracking-[-1px] text-black md:text-[52px]">
          {name}
        </h1>
        <p className="mt-4 max-w-2xl text-[17px] leading-relaxed text-carbon">
          {origin.name} to {dest.name} — {t.stops.length} stops over{" "}
          {Math.round(t.distanceKm)} km, departing {origin.code} at{" "}
          {t.departureTime}. Below is the full schedule; Railly tracks it live,
          predicts the delay at your station, and watches your PNR.
        </p>

        <div className="mt-8 grid grid-cols-2 gap-3 md:grid-cols-4">
          {stats.map(([icon, label, value]) => (
            <div
              key={label}
              className="rounded-2xl bg-linen p-4 ring-1 ring-black/[0.05]"
            >
              <div className="flex items-center gap-1.5 text-fog">
                {icon}
                <span className="text-[11px] font-bold uppercase tracking-[1px] text-steel">
                  {label}
                </span>
              </div>
              <div className="mt-2 text-[18px] font-bold tracking-tight text-black">
                {value}
              </div>
            </div>
          ))}
        </div>

        {/* classes */}
        <div className="mt-4 flex flex-wrap items-center gap-2">
          {t.classes.map((c) => (
            <span
              key={c}
              title={CLASS_NAMES[c] ?? c}
              className="rounded-full bg-fill px-3 py-1 text-[12px] font-bold text-carbon"
            >
              {c}
            </span>
          ))}
        </div>
      </header>

      {/* Schedule */}
      <section className="mx-auto max-w-4xl px-4 py-16 md:py-20">
        <Reveal>
          <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
            Schedule &amp; route
          </h2>
          <p className="mt-2 max-w-2xl text-[15px] leading-relaxed text-carbon">
            Every scheduled halt, with arrival and departure, day of the
            journey, distance from {origin.code}, and the platform where the
            railway has published one.
          </p>
        </Reveal>

        <Reveal delay={60}>
          <div className="mt-8 overflow-hidden rounded-3xl bg-white shadow-float ring-1 ring-black/[0.05]">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[720px] border-separate border-spacing-0 text-left">
                <thead>
                  <tr className="text-[11px] font-bold uppercase tracking-[1px] text-steel">
                    <th scope="col" className="px-4 py-4 md:px-6">
                      Station
                    </th>
                    <th scope="col" className="px-4 py-4 text-center">
                      Arrival
                    </th>
                    <th scope="col" className="px-4 py-4 text-center">
                      Departure
                    </th>
                    <th scope="col" className="px-4 py-4 text-center">
                      Day
                    </th>
                    <th scope="col" className="px-4 py-4 text-right">
                      Distance
                    </th>
                    <th scope="col" className="px-4 py-4 text-center">
                      PF
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {t.stops.map((stop, i) => {
                    const stopDay = dayOf(base, i === 0 ? stop.depMin : stop.arrMin);
                    return (
                      <tr key={stop.code}>
                        <th
                          scope="row"
                          className="border-t border-black/[0.06] px-4 py-4 text-left font-normal md:px-6"
                        >
                          <span className="block text-[15px] font-semibold leading-snug text-black">
                            {stop.name}
                          </span>
                          <span className="tnum mt-0.5 block text-[12px] text-steel">
                            {stop.code}
                          </span>
                        </th>
                        <td className="tnum border-t border-black/[0.06] px-4 py-4 text-center text-[14px] text-carbon">
                          {i === 0 ? (
                            <span className="text-fog">Source</span>
                          ) : (
                            fmtClock(base + stop.arrMin)
                          )}
                        </td>
                        <td className="tnum border-t border-black/[0.06] px-4 py-4 text-center text-[14px] text-carbon">
                          {i === lastIndex ? (
                            <span className="text-fog">Destination</span>
                          ) : (
                            fmtClock(base + stop.depMin)
                          )}
                        </td>
                        <td className="tnum border-t border-black/[0.06] px-4 py-4 text-center text-[14px] text-steel">
                          {stopDay}
                        </td>
                        <td className="tnum border-t border-black/[0.06] px-4 py-4 text-right text-[14px] text-carbon">
                          {km[i]} km
                        </td>
                        <td className="border-t border-black/[0.06] px-4 py-4 text-center">
                          {stop.platform ? (
                            <span className="rounded-md bg-gate/25 px-2 py-0.5 text-[12px] font-bold text-[#8a6d00]">
                              {stop.platform}
                            </span>
                          ) : (
                            <span className="text-fog">—</span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </Reveal>

        <Reveal delay={80}>
          <p className="mt-4 text-[13px] leading-relaxed text-fog">
            Times reflect the published timetable from {origin.code}; distance is
            measured cumulatively along the route to the {Math.round(t.distanceKm)}{" "}
            km total. Live running can differ — the app shows the real position
            and the predicted delay at your station.
          </p>
        </Reveal>
      </section>

      {/* Track live CTA */}
      <section className="bg-linen px-4 py-16 md:py-20">
        <Reveal from="zoom">
          <div className="mx-auto flex max-w-2xl flex-col items-center gap-5 rounded-3xl bg-white p-8 text-center shadow-float ring-1 ring-black/[0.05] md:p-10">
            <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-signal/10">
              <TrainFront size={22} className="text-signal" />
            </span>
            <div>
              <h2 className="text-[24px] font-bold tracking-tight text-black">
                Track the {name} live
              </h2>
              <p className="mx-auto mt-2 max-w-md text-[15px] leading-relaxed text-carbon">
                Add {t.number} to Railly and get its live position, a predicted
                delay at your station, platform alerts, and your PNR watched
                right up to chart time.
              </p>
            </div>
            <a
              href={APP_CTA_HREF}
              className="rounded-full bg-sun px-7 py-3.5 text-[15px] font-semibold text-black transition-transform hover:scale-[1.03] active:scale-95"
            >
              Join the waitlist
            </a>
          </div>
        </Reveal>
      </section>

      {/* FAQs */}
      <section className="mx-auto max-w-3xl px-4 py-16 md:py-20">
        <Reveal>
          <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
            {name} — common questions
          </h2>
        </Reveal>
        <div className="mt-6 flex flex-col gap-3">
          {faqs.map((f) => (
            <Reveal key={f.q}>
              <Faq q={f.q} a={f.a} />
            </Reveal>
          ))}
        </div>
        <Reveal delay={60}>
          <p className="mt-6 text-[14px] leading-relaxed text-steel">
            More on statuses and timing in the{" "}
            <Link
              href="/guides/pnr-status-explained"
              className="font-semibold text-signal underline-offset-4 hover:underline"
            >
              PNR status guide
            </Link>{" "}
            and the{" "}
            <Link
              href="/guides/tatkal-booking-time"
              className="font-semibold text-signal underline-offset-4 hover:underline"
            >
              Tatkal timing guide
            </Link>
            .
          </p>
        </Reveal>
      </section>

      {/* Sibling trains */}
      <section className="mx-auto max-w-4xl px-4 pb-24">
        <Reveal>
          <h2 className="text-[13px] font-bold uppercase tracking-[2px] text-steel">
            More trains to track
          </h2>
          <div className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {siblings.map((s) => (
              <Link
                key={s.number}
                href={`/trains/${trainSlug(s)}`}
                className="card-lift flex h-full flex-col rounded-2xl bg-linen p-5 ring-1 ring-black/[0.05]"
              >
                <span className="tnum text-[13px] font-bold text-steel">
                  {s.number}
                </span>
                <span className="mt-1 text-[15px] font-semibold leading-snug text-black">
                  {trainDisplayName(s)}
                </span>
                <span className="mt-1 text-[12px] text-steel">
                  {s.stops[0].code} → {s.stops[s.stops.length - 1].code}
                </span>
                <span className="mt-3 inline-flex items-center gap-1 text-[13px] font-semibold text-signal">
                  Schedule
                  <ArrowRight size={14} strokeWidth={2.2} />
                </span>
              </Link>
            ))}
          </div>
        </Reveal>
      </section>
    </PageShell>
  );
}
