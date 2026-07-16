import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight, Check, TrainFront } from "lucide-react";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { JsonLd } from "@/components/seo/JsonLd";

const COMPARE_TITLE =
  "Railly vs NTES vs Where Is My Train vs RailYatri vs ixigo — Indian Train Apps Compared (2026)";
const COMPARE_DESCRIPTION =
  "An honest comparison of Railly with NTES, Where Is My Train, RailYatri, and ixigo — how India's train apps stack up on live running status, PNR status, delay predictions, and platform alerts, and what Railly is built around.";

export const metadata: Metadata = {
  title: { absolute: COMPARE_TITLE },
  description: COMPARE_DESCRIPTION,
  alternates: { canonical: "/compare" },
  openGraph: {
    type: "website",
    siteName: "Railly",
    locale: "en_IN",
    url: "/compare",
    title: COMPARE_TITLE,
    description: COMPARE_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: COMPARE_TITLE,
    description: COMPARE_DESCRIPTION,
  },
};

/* ------------------------------------------------------------------ */
/* Data                                                                */
/* ------------------------------------------------------------------ */

/**
 * Verdicts for competitor cells stay deliberately neutral: an app either
 * offers a feature ("yes"), offers some form of it ("varies"), or doesn't
 * as far as we can tell ("no" → rendered as an em-dash, never a red X).
 */
export type Verdict = "yes" | "varies" | "no";

export const APPS = [
  { id: "ntes", short: "NTES", name: "NTES", tag: "Official · Indian Railways" },
  { id: "wimt", short: "WIMT", name: "Where Is My Train", tag: "Live tracking" },
  { id: "railyatri", short: "RailYatri", name: "RailYatri", tag: "Full-service travel" },
  { id: "ixigo", short: "ixigo", name: "ixigo trains", tag: "Booking & planning" },
] as const;

/**
 * cells: [NTES, Where Is My Train, RailYatri, ixigo trains].
 * `claim` is one self-contained, quotable sentence per row — declarative about
 * what Railly does, framed against the common alternative behaviour without
 * overstating any one competitor.
 */
export const ROWS: {
  feature: string;
  note: string;
  claim: string;
  cells: [Verdict, Verdict, Verdict, Verdict];
}[] = [
  {
    feature: "Delay predictions before announcements",
    note: "Railly calls the delay before the station does.",
    claim:
      "Railly predicts the delay at your station before the railway announces it, instead of only relaying the current official figure.",
    cells: ["no", "no", "varies", "varies"],
  },
  {
    feature: "PNR watch with confirmation odds",
    note: "Waitlist movement, watched around the clock.",
    claim:
      "Railly watches your PNR around the clock and reads its confirmation chances in plain English, so you never refresh an enquiry page again.",
    cells: ["no", "varies", "varies", "yes"],
  },
  {
    feature: "Coach position on the platform",
    note: "Stand where your door will stop.",
    claim:
      "Railly shows where your coach will halt along the platform, so boarding is a walk to the right spot rather than a sprint down the length of the train.",
    cells: ["no", "varies", "varies", "varies"],
  },
  {
    feature: "Seat availability with Tatkal reminders",
    note: "A nudge before the window opens.",
    claim:
      "Railly reads the availability grid for you and nudges you minutes before the Tatkal window opens, instead of leaving you to remember the time.",
    cells: ["no", "varies", "varies", "varies"],
  },
  {
    feature: "Live route map",
    note: "Your train on real track geometry.",
    claim:
      "Railly draws your train moving along the real track geometry of the route, not a straight line pinned between two stations.",
    cells: ["varies", "yes", "varies", "varies"],
  },
  {
    feature: "Platform-change alerts when the railway publishes them",
    note: "The moment the railway publishes a platform change, it reaches you.",
    claim:
      "Railly pushes a platform change the moment the railway publishes it, so a last-minute swap reaches you before you reach the wrong platform.",
    cells: ["varies", "varies", "no", "no"],
  },
  {
    feature: "Trip logbook (Passport)",
    note: "Every kilometre you have ever ridden, remembered.",
    claim:
      "Railly keeps a personal logbook — Passport — of every kilometre you have ridden, so your travel history is remembered instead of forgotten.",
    cells: ["no", "no", "no", "no"],
  },
  {
    feature: "Ad-free experience",
    note: "No banners between you and your train.",
    claim:
      "Railly puts no banner ads between you and your train — the whole screen is your journey, not a billboard.",
    cells: ["yes", "no", "no", "no"],
  },
  {
    feature: "Design-first iOS app",
    note: "Built native, polished obsessively.",
    claim:
      "Railly is built native for iPhone and polished obsessively, rather than ported across from another platform.",
    cells: ["no", "no", "no", "no"],
  },
];

export const PROFILES: {
  id: string;
  slug: string;
  name: string;
  tag: string;
  about: string;
  fit: string;
}[] = [
  {
    id: "ntes",
    slug: "railly-vs-ntes",
    name: "NTES",
    tag: "Official · Indian Railways",
    about:
      "NTES is Indian Railways' own enquiry system — the official source, and where the ground truth of running status lives. Nothing replaces the railway's word on the railway's trains.",
    fit: "Railly reads the same journey and builds prediction, notifications, and design on top of it. If you want the unfiltered official line, keep NTES installed — we do.",
  },
  {
    id: "wimt",
    slug: "railly-vs-where-is-my-train",
    name: "Where Is My Train",
    tag: "Live tracking",
    about:
      "Where Is My Train made offline, cell-tower-based tracking work for an enormous number of journeys, and its live view set the bar for the whole category. It is loved for a reason.",
    fit: "Railly is for riders who want that live picture plus what happens next — delay predictions, platform alerts, and a trip history — in a native, design-first iOS app.",
  },
  {
    id: "railyatri",
    slug: "railly-vs-railyatri",
    name: "RailYatri",
    tag: "Full-service travel",
    about:
      "RailYatri wraps bookings, buses, and on-board meals around the train journey — a genuine one-stop shop for getting a whole trip organised end to end.",
    fit: "Railly deliberately does less: no bookings, no marketplace, no ads. Just tracking, predicting, and remembering your journey, done obsessively well.",
  },
  {
    id: "ixigo",
    slug: "railly-vs-ixigo",
    name: "ixigo trains",
    tag: "Booking & planning",
    about:
      "ixigo is one of India's most popular train apps, and its confirmation predictions are widely relied on at booking time. For finding and booking a ticket, it is a strong choice.",
    fit: "Railly isn't a booking app. It is the companion for everything after you have booked — built around the journey itself, from PNR watch to the platform to the logbook.",
  },
];

/**
 * The five apps this page compares, as SoftwareApplication stubs — Railly plus
 * the four competitor PROFILES, so the structured data stays in lockstep with
 * the prose on the page. Deliberately no aggregateRating anywhere: we have no
 * real ratings, and inventing them would be a lie search engines reward once
 * and users never forgive.
 */
const COMPARE_JSON_LD = {
  "@context": "https://schema.org",
  "@type": "ItemList",
  name: "Indian Railways train apps compared",
  itemListElement: [
    {
      "@type": "SoftwareApplication",
      name: "Railly",
      applicationCategory: "TravelApplication",
      operatingSystem: "iOS",
      url: "https://railly.app",
      description:
        "Railly is an independent train-tracking app for Indian Railways, built for iPhone — live running status, PNR watch, delay predictions, platform alerts, and a trip logbook. Not affiliated with Indian Railways or IRCTC.",
    },
    ...PROFILES.map((app) => ({
      "@type": "SoftwareApplication",
      name: app.name,
      applicationCategory: "TravelApplication",
      description: app.about,
    })),
  ].map((item, i) => ({
    "@type": "ListItem",
    position: i + 1,
    item,
  })),
};

/* ------------------------------------------------------------------ */
/* Pieces                                                              */
/* ------------------------------------------------------------------ */

function RaillyMark() {
  return (
    <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-go/15">
      <Check size={15} strokeWidth={3} className="text-go" />
      <span className="sr-only">Built into Railly</span>
    </span>
  );
}

function VerdictMark({ v }: { v: Verdict }) {
  if (v === "yes") {
    return <span className="text-[13px] font-medium text-carbon">Yes</span>;
  }
  if (v === "varies") {
    return <span className="text-[13px] text-steel">Varies</span>;
  }
  return (
    <span className="text-steel">
      <span aria-hidden>—</span>
      <span className="sr-only">Not offered, as far as we can tell</span>
    </span>
  );
}

function CompareTable() {
  return (
    <div className="overflow-hidden rounded-3xl bg-white shadow-float ring-1 ring-black/[0.05]">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[840px] border-separate border-spacing-0 text-left">
          <thead>
            <tr>
              <th
                scope="col"
                className="sticky left-0 z-10 border-r border-black/[0.06] bg-white px-6 py-5 text-[11px] font-bold uppercase tracking-[2px] text-steel md:px-8"
              >
                Feature
              </th>
              <th
                scope="col"
                className="bg-signal/[0.04] px-4 py-5 text-center align-middle"
              >
                <span className="inline-flex items-center gap-2">
                  <span className="flex h-6 w-6 items-center justify-center rounded-[7px] bg-signal">
                    <TrainFront size={13} className="text-white" />
                  </span>
                  <span className="text-[14px] font-bold text-black">Railly</span>
                </span>
              </th>
              {APPS.map((app) => (
                <th key={app.id} scope="col" className="px-4 py-5 text-center align-middle">
                  <a
                    href={`#${app.id}`}
                    className="text-[14px] font-semibold text-carbon underline-offset-4 transition-colors hover:text-signal hover:underline"
                    title={app.name}
                  >
                    {app.short}
                  </a>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {ROWS.map((row) => (
              <tr key={row.feature}>
                <th
                  scope="row"
                  className="sticky left-0 z-10 max-w-[300px] border-r border-t border-black/[0.06] bg-white px-6 py-5 font-normal md:px-8"
                >
                  <span className="block text-[15px] font-semibold leading-snug text-black">
                    {row.feature}
                  </span>
                  <span className="mt-1 block text-[13px] leading-snug text-steel">
                    {row.note}
                  </span>
                </th>
                <td className="border-t border-black/[0.06] bg-signal/[0.04] px-4 py-5 text-center">
                  <RaillyMark />
                </td>
                {row.cells.map((cell, i) => (
                  <td
                    key={APPS[i].id}
                    className="border-t border-black/[0.06] px-4 py-5 text-center"
                  >
                    <VerdictMark v={cell} />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Page                                                                */
/* ------------------------------------------------------------------ */

export default function ComparePage() {
  return (
    <PageShell>
      <JsonLd data={COMPARE_JSON_LD} />
      <PageHero
        eyebrow="COMPARE"
        title="Choose your train app with open eyes."
        dek={
          "Millions of Indian travellers already ride with NTES, Where Is My Train, RailYatri, or ixigo — and each earns its place. Here's an honest look at where each one shines, and what Railly is built around."
        }
      />

      {/* The table */}
      <section className="bg-linen px-4 py-20 md:py-28">
        <div className="mx-auto max-w-6xl">
          <Reveal from="zoom">
            <CompareTable />
          </Reveal>

          <Reveal delay={80}>
            <div className="mx-auto mt-6 max-w-4xl text-center">
              <p className="flex flex-wrap items-center justify-center gap-x-5 gap-y-2 text-[13px] leading-relaxed text-steel">
                <span className="inline-flex items-center gap-1.5">
                  <span className="inline-flex h-5 w-5 items-center justify-center rounded-full bg-go/15">
                    <Check size={11} strokeWidth={3} className="text-go" />
                  </span>
                  built into Railly
                </span>
                <span>
                  <span className="font-semibold text-carbon">Yes</span> —
                  offered
                </span>
                <span>
                  <span className="font-semibold text-carbon">Varies</span> —
                  offered in some form; depth and coverage differ
                </span>
                <span>
                  <span className="font-semibold text-carbon">&mdash;</span>{" "}
                  not offered, as far as we can tell
                </span>
              </p>
              <p className="mt-3 text-[13px] leading-relaxed text-steel">
                Feature comparison reflects our reading of publicly available
                apps as of July 2026; verify with each product.
              </p>
            </div>
          </Reveal>
        </div>
      </section>

      {/* The short version — one quotable line per row */}
      <section className="mx-auto max-w-6xl px-4 pt-20 md:pt-28">
        <Reveal className="mx-auto max-w-3xl text-center">
          <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
            The short version.
          </h2>
          <p className="mt-4 text-[17px] leading-relaxed text-carbon">
            Every row above, in one line — what Railly does, and the common
            alternative it&apos;s built to improve on.
          </p>
        </Reveal>

        <div className="mt-12 grid gap-3 md:grid-cols-2">
          {ROWS.map((row, i) => (
            <Reveal key={row.feature} delay={(i % 2) * 70}>
              <div className="flex h-full gap-3.5 rounded-2xl bg-linen p-5 ring-1 ring-black/[0.05]">
                <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-go/15">
                  <Check size={13} strokeWidth={3} className="text-go" />
                </span>
                <div>
                  <div className="text-[11px] font-bold uppercase tracking-[1px] text-steel">
                    {row.feature}
                  </div>
                  <p className="mt-1 text-[15px] leading-relaxed text-carbon">
                    {row.claim}
                  </p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* Per-app positioning */}
      <section className="mx-auto max-w-6xl px-4 py-20 md:py-28">
        <Reveal className="mx-auto max-w-3xl text-center">
          <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
            Where each app shines.
          </h2>
          <p className="mt-4 text-[17px] leading-relaxed text-carbon">
            These apps got India moving, and we use them ourselves. Railly
            isn&apos;t here to replace the ones that work — it&apos;s here for
            the parts of the journey none of them were built around.
          </p>
        </Reveal>

        <div className="mt-14 grid gap-4 md:grid-cols-2">
          {PROFILES.map((app, i) => (
            <Reveal key={app.id} delay={i * 70}>
              <div
                id={app.id}
                className="flex h-full scroll-mt-24 flex-col rounded-3xl bg-linen p-8 ring-1 ring-black/[0.05]"
              >
                <div className="flex items-center justify-between gap-3">
                  <h3 className="text-[22px] font-bold tracking-tight text-black">
                    {app.name}
                  </h3>
                  <span className="whitespace-nowrap rounded-full bg-white px-3 py-1 text-[11px] font-bold uppercase tracking-[1px] text-steel ring-1 ring-black/[0.06]">
                    {app.tag}
                  </span>
                </div>
                <p className="mt-4 pb-6 text-[15px] leading-relaxed text-carbon">
                  {app.about}
                </p>
                <div className="mt-auto border-t border-black/[0.06] pt-4">
                  <div className="text-[11px] font-bold uppercase tracking-[2px] text-signal">
                    Where Railly fits
                  </div>
                  <p className="mt-2 text-[15px] leading-relaxed text-carbon">
                    {app.fit}
                  </p>
                  <Link
                    href={`/compare/${app.slug}`}
                    className="mt-4 inline-flex items-center gap-1.5 text-[14px] font-semibold text-signal transition-colors hover:text-black"
                  >
                    Railly vs {app.name}, in detail
                    <ArrowRight size={15} strokeWidth={2.2} />
                  </Link>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>
    </PageShell>
  );
}
