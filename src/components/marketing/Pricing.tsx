import Link from "next/link";
import { ArrowRight, Check } from "lucide-react";
import { APP_CTA_HREF, APP_CTA_LABEL } from "@/lib/cta";
import { Reveal } from "./Reveal";

/**
 * The Pro billing options. `amount` is the plain INR figure so structured
 * data (JSON-LD Offers on /pricing) can generate from the same source as
 * the cards — one price, one place to change it.
 */
export const PLANS = [
  {
    name: "Monthly",
    price: "₹99",
    amount: 99,
    cadence: "per month",
    note: "Pro, one month at a time.",
    popular: false,
  },
  {
    name: "Annual",
    price: "₹699",
    amount: 699,
    cadence: "per year · just ₹58/month",
    note: "Best value for a single rider.",
    popular: true,
  },
  {
    name: "Family",
    price: "₹1,199",
    amount: 1199,
    cadence: "per year · up to 5 people",
    note: "One plan for the whole household.",
    popular: false,
  },
  {
    name: "Lifetime",
    price: "₹2,999",
    amount: 2999,
    cadence: "one-time · yours forever",
    note: "Pay once. No subscription, ever.",
    popular: false,
  },
];

/** What every Pro plan unlocks on top of the free breadth. */
export const INCLUDED = [
  "Push alerts before the announcer",
  "PNR auto-watch, around the clock",
  "Live Activities on every trip",
  "Home & Lock Screen widgets",
  "Passport Wrapped extras",
  "Family auto-share",
];

export function Pricing() {
  return (
    <section id="pricing" className="mx-auto max-w-6xl scroll-mt-24 px-4 py-24 md:py-32">
      <Reveal className="mx-auto max-w-2xl text-center">
        <h3 className="text-[28px] font-bold tracking-tight text-black md:text-[36px]">
          The world&apos;s most powerful train tracker.
        </h3>
        <p className="mt-4 text-[17px] text-carbon">
          Everything you need to follow a journey is free, forever, and ad-free.
          Pro adds speed and reach — and your first tracked trip is full Pro, on
          us.
        </p>
      </Reveal>

      {/* Free is the headline, not the afterthought */}
      <Reveal delay={80}>
        <div className="mx-auto mt-10 flex max-w-3xl flex-col items-center gap-2.5 rounded-3xl bg-linen p-6 text-center ring-1 ring-black/[0.05] sm:flex-row sm:justify-center sm:gap-3.5 sm:text-left">
          <span className="whitespace-nowrap rounded-full bg-go/15 px-3 py-1 text-[12px] font-bold uppercase tracking-[1px] text-go">
            Free forever
          </span>
          <span className="text-[14px] leading-relaxed text-carbon">
            Unlimited trip tracking, PNR status, coach position and your Railly
            Passport — with no ads, ever.
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

      <Reveal delay={200}>
        <div className="mt-10 text-center">
          <Link
            href="/pricing"
            className="inline-flex items-center gap-1.5 text-[15px] font-semibold text-signal underline-offset-4 hover:underline"
          >
            Compare Free and Pro in full
            <ArrowRight size={16} />
          </Link>
        </div>
      </Reveal>
    </section>
  );
}
