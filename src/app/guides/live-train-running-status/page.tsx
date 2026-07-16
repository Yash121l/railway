import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight, ChevronDown, MapPin, Radio, TrendingUp } from "lucide-react";
import { APP_CTA_HREF } from "@/lib/cta";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { JsonLd } from "@/components/seo/JsonLd";

const TITLE =
  "Live Train Running Status — How Tracking & Delay Predictions Work | Railly";
const DESCRIPTION =
  "How live train running status works on Indian Railways: where the position comes from, why Railly labels live feeds and timetable estimates differently, how delay predictions are made, and how platform alerts reach you.";

export const metadata: Metadata = {
  title: { absolute: TITLE },
  description: DESCRIPTION,
  alternates: { canonical: "/guides/live-train-running-status" },
  openGraph: {
    type: "article",
    siteName: "Railly",
    locale: "en_IN",
    url: "/guides/live-train-running-status",
    title: TITLE,
    description: DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: TITLE,
    description: DESCRIPTION,
  },
};

type FaqItem = { q: string; a: string };

const FAQS: FaqItem[] = [
  {
    q: "Where does live running status come from?",
    a: "Wherever a live feed is available for your train, Railly uses it and marks the status Live. Where no feed exists, Railly falls back to timetable-based estimates built from the train's schedule and its recent running pattern — and labels them as estimates. You always know whether you're looking at a reported position or a projection; Railly never dresses one up as the other.",
  },
  {
    q: "How accurate is Railly's live status?",
    a: "It depends on the train, and Railly always tells you which you're looking at. Where a live feed is available, Railly reports the train's position and marks it Live. Where no feed exists, Railly shows a timetable-based estimate built from the schedule and recent running patterns, and labels it as an estimate rather than dressing it up as a live report. Delay figures for your station are shown as predictions, alongside the official running status — so you always know how much to trust a number before you rely on it.",
  },
  {
    q: "How do delay predictions work?",
    a: "A train that's 40 minutes late three hours away from you rarely arrives exactly 40 minutes late. Railly projects the delay at your station by looking at where the train typically loses or makes up time along the route and how the section ahead is flowing today, instead of just repeating the current figure. Predictions are always shown as predictions, alongside the official running status.",
  },
  {
    q: "What are platform alerts?",
    a: "Railly watches the platform assignment at your boarding and arrival stations and pushes a notification the moment it's published — or changes. Combined with coach position, you'll know not just which platform to stand on, but where along it your coach will halt, so a last-minute platform swap becomes a walk instead of a sprint.",
  },
];

const FAQ_JSON_LD = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: FAQS.map((f) => ({
    "@type": "Question",
    name: f.q,
    acceptedAnswer: { "@type": "Answer", text: f.a },
  })),
};

function Faq({ q, a }: FaqItem) {
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

export default function LiveRunningStatusGuide() {
  return (
    <PageShell>
      <JsonLd data={FAQ_JSON_LD} />
      <PageHero
        eyebrow="GUIDE · LIVE TRACKING"
        title="Live running status, honestly labelled."
        dek="Where the numbers come from, what they mean, and the one rule Railly never breaks: you always know whether you're looking at a reported position or a projection."
      />

      {/* The labelled-estimates policy — verbatim */}
      <section className="mx-auto max-w-3xl px-4 pt-10">
        <Reveal from="zoom">
          <blockquote className="rounded-3xl bg-midnight p-8 text-white ring-1 ring-white/[0.06] md:p-10">
            <div className="flex items-center gap-2 text-[12px] font-bold uppercase tracking-[2px] text-sun">
              <Radio size={15} />
              Our labelling policy
            </div>
            <p className="mt-4 text-[18px] leading-relaxed text-silver">
              Wherever a live feed is available for your train, Railly uses it
              and marks the status <b className="font-semibold text-white">Live</b>.
              Where no feed exists, Railly falls back to timetable-based estimates
              built from the train&apos;s schedule and its recent running pattern
              — and labels them as{" "}
              <b className="font-semibold text-white">estimates</b>. You always
              know whether you&apos;re looking at a reported position or a
              projection; Railly never dresses one up as the other.
            </p>
          </blockquote>
        </Reveal>
      </section>

      {/* How it works */}
      <section className="mx-auto max-w-3xl px-4 py-20 md:py-24">
        <div className="flex flex-col gap-10">
          <Reveal>
            <div className="flex gap-4">
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-linen ring-1 ring-black/[0.05]">
                <Radio size={20} className="text-carbon" strokeWidth={1.8} />
              </span>
              <div>
                <h2 className="text-[20px] font-bold tracking-tight text-black">
                  Live feed vs. estimate
                </h2>
                <p className="mt-2 text-[16px] leading-relaxed text-carbon">
                  When a live feed exists for your train, Railly reports the
                  real position and marks it Live. When one doesn&apos;t, it
                  builds a timetable-based estimate from the schedule and the
                  train&apos;s recent running, and says so plainly. The label is
                  never hidden — a projection is always dressed as a projection.
                </p>
              </div>
            </div>
          </Reveal>
          <Reveal delay={60}>
            <div className="flex gap-4">
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-linen ring-1 ring-black/[0.05]">
                <TrendingUp size={20} className="text-carbon" strokeWidth={1.8} />
              </span>
              <div>
                <h2 className="text-[20px] font-bold tracking-tight text-black">
                  Predicting your delay
                </h2>
                <p className="mt-2 text-[16px] leading-relaxed text-carbon">
                  A train that&apos;s 40 minutes late three hours away rarely
                  arrives exactly 40 late. Railly projects the delay at your
                  station from where the train usually loses or makes up time and
                  how the section ahead is flowing today — not by repeating the
                  current figure. The prediction sits beside the official running
                  status, always marked as a prediction.
                </p>
              </div>
            </div>
          </Reveal>
          <Reveal delay={120}>
            <div className="flex gap-4">
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-linen ring-1 ring-black/[0.05]">
                <MapPin size={20} className="text-carbon" strokeWidth={1.8} />
              </span>
              <div>
                <h2 className="text-[20px] font-bold tracking-tight text-black">
                  Platform &amp; coach position
                </h2>
                <p className="mt-2 text-[16px] leading-relaxed text-carbon">
                  Railly watches the platform assignment at your boarding and
                  arrival stations and pushes a notification the moment it&apos;s
                  published or changes. Paired with coach position, you know not
                  just which platform to stand on but where along it your coach
                  will halt — a last-minute swap becomes a walk, not a sprint.
                </p>
              </div>
            </div>
          </Reveal>
        </div>
      </section>

      {/* CTA */}
      <section className="bg-linen px-4 py-20 md:py-24">
        <Reveal from="zoom" className="mx-auto max-w-3xl">
          <div className="flex flex-col items-center gap-5 rounded-3xl bg-white p-8 text-center shadow-float ring-1 ring-black/[0.05] md:p-12">
            <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-signal/10">
              <Radio size={22} className="text-signal" />
            </span>
            <h2 className="text-[26px] font-bold tracking-tight text-black md:text-[32px]">
              Track your train live.
            </h2>
            <p className="mx-auto max-w-md text-[16px] leading-relaxed text-carbon">
              Add a journey and Railly follows it on the real route — live
              position where there&apos;s a feed, a labelled estimate where there
              isn&apos;t, a predicted delay at your station, and a nudge the
              moment your platform is set.
            </p>
            <a
              href={APP_CTA_HREF}
              className="mt-1 rounded-full bg-sun px-7 py-3.5 text-[15px] font-semibold text-black transition-transform hover:scale-[1.03] active:scale-95"
            >
              Join the waitlist
            </a>
          </div>
        </Reveal>
      </section>

      {/* FAQ */}
      <section className="mx-auto max-w-3xl px-4 py-16 md:py-20">
        <Reveal>
          <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
            Frequently asked
          </h2>
        </Reveal>
        <div className="mt-6 flex flex-col gap-3">
          {FAQS.map((f) => (
            <Reveal key={f.q}>
              <Faq q={f.q} a={f.a} />
            </Reveal>
          ))}
        </div>
        <Reveal delay={60}>
          <p className="mt-6 text-[14px] leading-relaxed text-steel">
            Waiting on a berth too? The{" "}
            <Link
              href="/guides/pnr-status-explained"
              className="font-semibold text-signal underline-offset-4 hover:underline"
            >
              PNR status guide
            </Link>{" "}
            and{" "}
            <Link
              href="/pnr-status"
              className="inline-flex items-center gap-1 font-semibold text-signal underline-offset-4 hover:underline"
            >
              PNR status reference
              <ArrowRight size={13} strokeWidth={2.2} />
            </Link>{" "}
            cover the rest.
          </p>
        </Reveal>
      </section>
    </PageShell>
  );
}
