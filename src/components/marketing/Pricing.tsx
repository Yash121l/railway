import Link from "next/link";
import { Check } from "lucide-react";
import { Reveal } from "./Reveal";

const PLANS = [
  {
    name: "Free",
    price: "₹0",
    cadence: "Forever",
    note: "Limited trip history",
    popular: false,
  },
  {
    name: "Pay-As-You-Go",
    price: "₹49",
    cadence: "per week · billed weekly",
    note: "Email import and calendar sync not included",
    popular: false,
  },
  {
    name: "Unlimited Annual",
    price: "₹999",
    cadence: "per year · ₹83/month",
    note: "Everything, for every journey",
    popular: true,
  },
  {
    name: "Lifetime",
    price: "₹4,999",
    cadence: "one-time purchase",
    note: "No subscription. Ever.",
    popular: false,
  },
];

const INCLUDED = [
  "Unlimited trips",
  "Live loco-grade data",
  "Push alerts before the announcer",
  "Live Activities",
  "24hr Where's-My-Rake",
  "Predictive delays",
];

export function Pricing() {
  return (
    <section id="pricing" className="mx-auto max-w-6xl scroll-mt-24 px-4 py-24 md:py-32">
      <Reveal className="mx-auto max-w-2xl text-center">
        <h3 className="text-[28px] font-bold tracking-tight text-black md:text-[36px]">
          The world&apos;s most powerful train tracker.
        </h3>
        <p className="mt-4 text-[17px] text-carbon">
          Free to try on every journey. Pro when you never want to stare at a
          departure board again.
        </p>
      </Reveal>
      <div className="mt-12 grid gap-4 md:grid-cols-4">
        {PLANS.map((plan, i) => (
          <Reveal key={plan.name} delay={i * 70}>
            <div
              className={`relative flex h-full flex-col rounded-3xl p-6 ${
                plan.popular
                  ? "bg-midnight text-white ring-2 ring-signal"
                  : "bg-white shadow-float"
              }`}
            >
              {plan.popular && (
                <span className="absolute -top-3 left-1/2 -translate-x-1/2 whitespace-nowrap rounded-full bg-signal px-3 py-1 text-[11px] font-bold uppercase tracking-[0.5px] text-white">
                  Our most popular plan
                </span>
              )}
              <div
                className={`text-[13px] font-bold uppercase tracking-[1px] ${
                  plan.popular ? "text-white/60" : "text-steel"
                }`}
              >
                {plan.name}
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
              <Link
                href="/app"
                className={`mt-6 rounded-full py-2.5 text-center text-[14px] font-semibold transition-transform hover:scale-[1.03] ${
                  plan.popular
                    ? "bg-signal text-white"
                    : "border border-black/40 text-black hover:bg-black hover:text-white"
                }`}
              >
                {plan.popular ? "Get Railly Pro" : "Choose"}
              </Link>
            </div>
          </Reveal>
        ))}
      </div>
      <Reveal delay={150}>
        <div className="mx-auto mt-10 flex max-w-3xl flex-wrap justify-center gap-x-6 gap-y-2">
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
      </Reveal>
    </section>
  );
}
