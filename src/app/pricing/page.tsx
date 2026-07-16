import type { Metadata } from "next";
import { Check, ChevronDown, Sparkles } from "lucide-react";
import { APP_CTA_HREF, APP_CTA_LABEL } from "@/lib/cta";
import { INCLUDED, PLANS } from "@/components/marketing/Pricing";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";

export const metadata: Metadata = {
  title: "Pricing",
  description:
    "Railly is free forever and ad-free — unlimited tracking, PNR status, coach position and your Passport. Pro adds push speed, PNR auto-watch, Live Activities, widgets and family sharing. Your first trip is full Pro.",
};

/* ------------------------------------------------------------------ */
/* Free vs Pro matrix                                                  */
/* ------------------------------------------------------------------ */

/** true → included, false → not in this tier (em-dash), string → qualified. */
type Cell = boolean | string;

const MATRIX: { feature: string; free: Cell; pro: Cell }[] = [
  { feature: "Unlimited trip tracking & live running status", free: true, pro: true },
  { feature: "Live route map & coach position", free: true, pro: true },
  { feature: "Seat availability grid & Tatkal reminders", free: true, pro: true },
  { feature: "Railly Passport — your rail logbook", free: true, pro: true },
  { feature: "Ad-free, forever", free: true, pro: true },
  { feature: "PNR status", free: "On demand", pro: "Auto-watched 24/7" },
  {
    feature: "Push alerts before the announcer",
    free: "First trip",
    pro: "Every trip, priority",
  },
  {
    feature: "Live Activities & Dynamic Island",
    free: "First trip",
    pro: "Every trip",
  },
  { feature: "Home & Lock Screen widgets", free: false, pro: true },
  {
    feature: "Passport Wrapped — your year in review",
    free: "Recap",
    pro: "Full Wrapped + extras",
  },
  { feature: "Family & friends auto-share", free: false, pro: "Up to 5 people" },
];

function CellMark({ value }: { value: Cell }) {
  if (value === true) {
    return (
      <span className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-go/15">
        <Check size={14} strokeWidth={3} className="text-go" />
        <span className="sr-only">Included</span>
      </span>
    );
  }
  if (value === false) {
    return (
      <span className="text-fog">
        <span aria-hidden>—</span>
        <span className="sr-only">Not included</span>
      </span>
    );
  }
  return <span className="text-[13px] font-medium text-carbon">{value}</span>;
}

function CompareTable() {
  return (
    <div className="overflow-hidden rounded-3xl bg-white shadow-float ring-1 ring-black/[0.05]">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[560px] border-separate border-spacing-0 text-left">
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
                className="px-4 py-5 text-center align-middle text-[14px] font-bold text-black"
              >
                Free
              </th>
              <th
                scope="col"
                className="bg-pro/[0.06] px-4 py-5 text-center align-middle"
              >
                <span className="inline-flex items-center gap-1.5">
                  <Sparkles size={14} className="text-pro" />
                  <span className="text-[14px] font-bold text-black">Pro</span>
                </span>
              </th>
            </tr>
          </thead>
          <tbody>
            {MATRIX.map((row) => (
              <tr key={row.feature}>
                <th
                  scope="row"
                  className="sticky left-0 z-10 max-w-[320px] border-r border-t border-black/[0.06] bg-white px-6 py-4 font-normal md:px-8"
                >
                  <span className="block text-[15px] font-medium leading-snug text-black">
                    {row.feature}
                  </span>
                </th>
                <td className="border-t border-black/[0.06] px-4 py-4 text-center">
                  <CellMark value={row.free} />
                </td>
                <td className="border-t border-black/[0.06] bg-pro/[0.06] px-4 py-4 text-center">
                  <CellMark value={row.pro} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* FAQ                                                                 */
/* ------------------------------------------------------------------ */

function Faq({ q, children }: { q: string; children: React.ReactNode }) {
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
        {children}
      </div>
    </details>
  );
}

/* ------------------------------------------------------------------ */
/* Page                                                                */
/* ------------------------------------------------------------------ */

export default function PricingPage() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: "Railly Pro",
    description:
      "Pro adds push alerts before the announcer, around-the-clock PNR watch, Live Activities on every trip, widgets, Passport Wrapped extras, and family sharing.",
    brand: { "@type": "Brand", name: "Railly" },
    offers: PLANS.map((plan) => ({
      "@type": "Offer",
      name: `Railly Pro — ${plan.name}`,
      price: plan.amount,
      priceCurrency: "INR",
      url: "https://railly.app/pricing",
      availability: "https://schema.org/PreOrder",
    })),
  };

  return (
    <PageShell>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c"),
        }}
      />

      <PageHero
        eyebrow="PRICING"
        title="Free to ride. Pro to never miss a beat."
        dek="Everything you need to follow a journey — tracking, PNR, coach position and your Passport — is free forever, and there are never any ads. Pro turns up the speed and reach. Whichever you pick, your first tracked trip is full Pro, on us."
      />

      {/* the plans */}
      <section className="mx-auto max-w-6xl px-4 pb-4 pt-12">
        <Reveal delay={40}>
          <div className="mx-auto flex max-w-3xl flex-col items-center gap-2.5 rounded-3xl bg-linen p-6 text-center ring-1 ring-black/[0.05] sm:flex-row sm:justify-center sm:gap-3.5 sm:text-left">
            <span className="whitespace-nowrap rounded-full bg-go/15 px-3 py-1 text-[12px] font-bold uppercase tracking-[1px] text-go">
              Free forever
            </span>
            <span className="text-[14px] leading-relaxed text-carbon">
              Unlimited trip tracking, PNR status, coach position and your Railly
              Passport — with no ads, ever. No credit card, no catch.
            </span>
          </div>
        </Reveal>

        <div className="mt-8 grid gap-4 md:grid-cols-4">
          {PLANS.map((plan, i) => (
            <Reveal key={plan.name} delay={i * 70}>
              <div
                className={`card-lift relative flex h-full flex-col rounded-3xl p-6 ${
                  plan.popular
                    ? "bg-midnight text-white ring-2 ring-signal"
                    : "bg-white shadow-float"
                }`}
              >
                {plan.popular && (
                  <span className="absolute -top-3 left-1/2 -translate-x-1/2 whitespace-nowrap rounded-full bg-signal px-3 py-1 text-[11px] font-bold uppercase tracking-[0.5px] text-white">
                    Best value
                  </span>
                )}
                <div
                  className={`text-[13px] font-bold uppercase tracking-[1px] ${
                    plan.popular ? "text-white/60" : "text-steel"
                  }`}
                >
                  Railly Pro · {plan.name}
                </div>
                <div className="mt-3 text-[34px] font-extrabold tracking-tight">
                  {plan.price}
                </div>
                <div
                  className={`text-[13px] ${plan.popular ? "text-white/60" : "text-steel"}`}
                >
                  {plan.cadence}
                </div>
                <p
                  className={`mt-4 flex-1 text-[14px] ${
                    plan.popular ? "text-white/80" : "text-carbon"
                  }`}
                >
                  {plan.note}
                </p>
                <a
                  href={APP_CTA_HREF}
                  className={`mt-6 rounded-full py-2.5 text-center text-[14px] font-semibold transition-transform hover:scale-[1.03] active:scale-95 ${
                    plan.popular
                      ? "bg-signal text-white"
                      : "border border-black/40 text-black hover:bg-black hover:text-white"
                  }`}
                >
                  {APP_CTA_LABEL}
                </a>
              </div>
            </Reveal>
          ))}
        </div>

        <Reveal delay={150}>
          <div className="mx-auto mt-12 max-w-3xl">
            <div className="mb-4 text-center text-[13px] font-bold uppercase tracking-[1px] text-steel">
              Every Pro plan unlocks
            </div>
            <div className="flex flex-wrap justify-center gap-x-6 gap-y-2">
              {INCLUDED.map((feature) => (
                <span
                  key={feature}
                  className="flex items-center gap-1.5 text-[13px] text-carbon"
                >
                  <Check size={14} className="text-go" />
                  {feature}
                </span>
              ))}
            </div>
          </div>
        </Reveal>
      </section>

      {/* first trip is on us */}
      <section className="mx-auto max-w-6xl px-4 py-16 md:py-20">
        <Reveal from="zoom">
          <div className="glow-violet relative overflow-hidden rounded-3xl p-8 text-center ring-1 ring-black/10 md:p-12">
            <div className="relative">
              <span className="inline-flex items-center gap-1.5 rounded-full bg-white/10 px-3 py-1 text-[11px] font-bold uppercase tracking-[1.5px] text-sun ring-1 ring-white/15">
                <Sparkles size={13} /> On the house
              </span>
              <h2 className="mx-auto mt-5 max-w-2xl text-[26px] font-bold leading-tight tracking-tight text-white md:text-[34px]">
                Your first tracked trip is full Pro.
              </h2>
              <p className="mx-auto mt-4 max-w-xl text-[16px] leading-relaxed text-white/75">
                Every alert, Live Activities on your Lock Screen, PNR watched
                around the clock — the whole thing, free, on your very first
                journey. We&apos;d rather you feel the difference than read about
                it.
              </p>
            </div>
          </div>
        </Reveal>
      </section>

      {/* the comparison */}
      <section className="bg-linen px-4 py-20 md:py-28">
        <div className="mx-auto max-w-4xl">
          <Reveal className="mx-auto max-w-2xl text-center">
            <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
              Free vs Pro, line by line.
            </h2>
            <p className="mt-4 text-[17px] leading-relaxed text-carbon">
              Free is the whole picture of your journey. Pro is that picture,
              faster, on every screen, for everyone you travel with.
            </p>
          </Reveal>

          <Reveal delay={80} from="zoom" className="mt-12">
            <CompareTable />
          </Reveal>

          <Reveal delay={120}>
            <p className="mt-6 text-center text-[13px] leading-relaxed text-fog">
              Live Activities, widgets and PNR auto-watch ship in the app;
              friends &amp; family auto-share is on the roadmap — here&apos;s how
              it will work.
            </p>
          </Reveal>
        </div>
      </section>

      {/* FAQ */}
      <section className="mx-auto max-w-3xl px-4 py-20 md:py-28">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
            Questions about pricing.
          </h2>
        </Reveal>

        <div className="mt-12 flex flex-col gap-3">
          <Reveal>
            <Faq q="Is Railly really free?">
              <p>
                Yes. Unlimited trip tracking, live running status, PNR status,
                seat availability, coach position and your Railly Passport are
                free forever, with no ads and no credit card. Pro is an optional
                upgrade for speed and reach — it isn&apos;t a wall in front of
                the basics.
              </p>
            </Faq>
          </Reveal>
          <Reveal delay={40}>
            <Faq q="What do I get on my first trip?">
              <p>
                Full Pro, free. Your first tracked journey unlocks priority push
                alerts, Live Activities, around-the-clock PNR watch — everything
                — so you experience the difference before you ever decide to pay.
              </p>
            </Faq>
          </Reveal>
          <Reveal delay={80}>
            <Faq q="What does Pro add over Free?">
              <p>
                The fastest push alerts before the announcer, your PNR watched
                around the clock, Live Activities on every trip, Home and Lock
                Screen widgets, Passport Wrapped extras, and automatic sharing
                with your family and friends.
              </p>
            </Faq>
          </Reveal>
          <Reveal delay={120}>
            <Faq q="How does the Family plan work?">
              <p>
                One ₹1,199-a-year plan covers up to five people. Everyone gets
                their own Passport and their own trips, and you can follow each
                other&apos;s journeys without forwarding a single PNR. It works
                out cheaper than two individual annual plans.
              </p>
            </Faq>
          </Reveal>
          <Reveal delay={160}>
            <Faq q="Is there a plan without a subscription?">
              <p>
                Yes — Lifetime is a one-time ₹2,999 and never renews. Buy it once
                and Pro is yours for good, on every trip you ever take with
                Railly.
              </p>
            </Faq>
          </Reveal>
          <Reveal delay={200}>
            <Faq q="How and when do I pay?">
              <p>
                Railly is on the waitlist ahead of its App Store launch. When it
                ships, you&apos;ll subscribe through the App Store like any other
                app, and billing only ever starts if and when you choose a Pro
                plan — never automatically. Join the waitlist and we&apos;ll tell
                you the moment it&apos;s live.
              </p>
            </Faq>
          </Reveal>
        </div>
      </section>
    </PageShell>
  );
}
