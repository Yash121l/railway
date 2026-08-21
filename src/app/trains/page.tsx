import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { JsonLd } from "@/components/seo/JsonLd";
import {
  TRAINS,
  trainDisplayName,
  trainSlug,
  trainTypeLabel,
  type SeedTrain,
} from "./[slug]/page";

const TRAINS_TITLE =
  "Indian Railways Trains — Live Running Status, Routes & Schedules";
const TRAINS_DESCRIPTION =
  "Full routes and schedules for India's flagship trains — Rajdhani, Vande Bharat, Shatabdi and superfast expresses — with every stop, timing and platform. Track any of them live with Railly.";

export const metadata: Metadata = {
  title: { absolute: `${TRAINS_TITLE} | Railly` },
  description: TRAINS_DESCRIPTION,
  alternates: { canonical: "/trains" },
  openGraph: {
    type: "website",
    siteName: "Railly",
    locale: "en_IN",
    url: "/trains",
    title: TRAINS_TITLE,
    description: TRAINS_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: TRAINS_TITLE,
    description: TRAINS_DESCRIPTION,
  },
};

const CATEGORY_ORDER = ["rajdhani", "vande-bharat", "shatabdi", "superfast"];

function groups() {
  return CATEGORY_ORDER.map((cat) => ({
    label: trainTypeLabel(TRAINS.find((t) => t.category === cat) as SeedTrain),
    trains: TRAINS.filter((t) => t.category === cat),
  })).filter((g) => g.trains.length > 0);
}

const LIST_JSON_LD = {
  "@context": "https://schema.org",
  "@type": "ItemList",
  name: "Indian Railways trains on Railly",
  itemListElement: TRAINS.map((t, i) => ({
    "@type": "ListItem",
    position: i + 1,
    name: `${t.number} ${trainDisplayName(t)}`,
    url: `https://railly.app/trains/${trainSlug(t)}`,
  })),
};

function TrainCard({ t }: { t: SeedTrain }) {
  const origin = t.stops[0];
  const dest = t.stops[t.stops.length - 1];
  const runs = t.days.length === 7 ? "Daily" : `${t.days.length} days/week`;
  return (
    <Link
      href={`/trains/${trainSlug(t)}`}
      className="card-lift flex h-full flex-col rounded-2xl bg-linen p-5 ring-1 ring-black/[0.05]"
    >
      <div className="flex items-center justify-between gap-3">
        <span className="tnum text-[15px] font-extrabold tracking-tight text-black">
          {t.number}
        </span>
        <span className="rounded-full bg-white px-2.5 py-1 text-[11px] font-bold uppercase tracking-[0.5px] text-steel ring-1 ring-black/[0.06]">
          {runs}
        </span>
      </div>
      <div className="mt-2 text-[16px] font-bold leading-snug text-black">
        {trainDisplayName(t)}
      </div>
      <div className="mt-1 text-[13px] text-steel">
        {origin.name} → {dest.name}
      </div>
      <div className="mt-auto flex items-center justify-between gap-3 pt-4">
        <span className="tnum text-[12px] text-fog">
          {Math.round(t.distanceKm)} km · {t.stops.length} stops
        </span>
        <span className="inline-flex items-center gap-1 text-[13px] font-semibold text-signal">
          Schedule
          <ArrowRight size={14} strokeWidth={2.2} />
        </span>
      </div>
    </Link>
  );
}

export default function TrainsIndexPage() {
  return (
    <PageShell>
      <JsonLd data={LIST_JSON_LD} />
      <PageHero
        eyebrow="TRAINS"
        title="Every flagship train, route and schedule."
        dek="Rajdhanis, Vande Bharats, Shatabdis and the great superfast expresses — full stop-by-stop schedules, timings and platforms, each one trackable live in Railly. A sample of the 4,022 trains in the catalogue."
      />

      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        {groups().map((g, gi) => (
          <div key={g.label} className={gi > 0 ? "mt-16" : ""}>
            <Reveal>
              <h2 className="text-[22px] font-bold tracking-tight text-black md:text-[26px]">
                {g.label}
              </h2>
            </Reveal>
            <div className="mt-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {g.trains.map((t, i) => (
                <Reveal key={t.number} delay={(i % 3) * 60}>
                  <TrainCard t={t} />
                </Reveal>
              ))}
            </div>
          </div>
        ))}

        <Reveal delay={80}>
          <p className="mt-14 text-center text-[13px] text-fog">
            A curated sample — the app tracks all 4,022 trains and 9,109 stations
            across Indian Railways.
          </p>
        </Reveal>
      </div>
    </PageShell>
  );
}
