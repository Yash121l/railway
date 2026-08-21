import { JsonLd } from "@/components/seo/JsonLd";
import { INCLUDED, PLANS } from "./Pricing";
import { Reveal } from "./Reveal";

/**
 * A quiet, plain-language definition of Railly for the homepage — the kind of
 * clean, extractable sentence an answer engine can lift wholesale. The Pro
 * price and the app's MobileApplication offers/featureList all draw from the
 * PLANS and INCLUDED arrays in Pricing.tsx, so there is one number to change.
 */
const ANNUAL_PRICE = PLANS.find((plan) => plan.name === "Annual")?.price ?? "₹699";

const DESCRIPTION = `Railly is a train-tracking app for Indian Railways, built for iPhone. It tracks live running status for 4,022 trains across 9,109 stations, watches your PNR and alerts you when your waitlist moves, works offline, and is free to track any journey. Pro from ${ANNUAL_PRICE}/year. Railly is independent and not affiliated with Indian Railways or IRCTC.`;

const APP_JSON_LD = {
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  "@id": "https://railly.app/#app",
  name: "Railly",
  applicationCategory: "TravelApplication",
  operatingSystem: "iOS",
  url: "https://railly.app",
  description: DESCRIPTION,
  featureList: INCLUDED,
  offers: PLANS.map((plan) => ({
    "@type": "Offer",
    name: `Railly Pro · ${plan.name}`,
    price: plan.amount,
    priceCurrency: "INR",
  })),
  publisher: { "@id": "https://railly.app/#org" },
};

export function WhatIsRailly() {
  return (
    <section
      id="what-is-railly"
      className="mx-auto max-w-3xl scroll-mt-24 px-4 py-16 text-center md:py-20"
    >
      <JsonLd data={APP_JSON_LD} />
      <Reveal>
        <h2 className="text-[22px] font-bold tracking-tight text-black md:text-[26px]">
          What is Railly?
        </h2>
        <p className="mx-auto mt-4 max-w-2xl text-[16px] leading-relaxed text-carbon">
          {DESCRIPTION}
        </p>
      </Reveal>
    </section>
  );
}
