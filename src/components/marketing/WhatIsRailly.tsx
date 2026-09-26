import { JsonLd } from "@/components/seo/JsonLd";
import { Reveal } from "./Reveal";

/**
 * A quiet, plain-language definition of Railly for the homepage — the kind of
 * clean, extractable sentence an answer engine can lift wholesale.
 *
 * `featureList` is machine-readable and gets quoted back at us, so it lists
 * only what ships today. No `offers` node: nothing can be bought, and an Offer
 * without an availability field reads to Google as in stock.
 */
const FEATURES = [
  "Real PNR status with per-passenger current status",
  "Coach position read from the reservation chart",
  "One screen: a satellite globe of your trips with a sheet over it",
  "Routes drawn on real OpenStreetMap track across 120 corridors",
  "One search field for a train, a station or a 10-digit PNR",
  "Live Activities on the lock screen and Dynamic Island",
  "Passport logbook of every kilometre ridden, with a Delay Report",
  "Offline catalogue of 4,022 trains and 9,109 station codes",
  "No account, no ads, no trackers",
];

const DESCRIPTION = `Railly is a train-tracking app for Indian Railways, built for iPhone. It opens on one screen, a satellite globe with your trips drawn on real OpenStreetMap track and a sheet over it for your trips and search. It covers 4,022 trains and 9,109 station codes offline, reads a real PNR with per-passenger status and coach position, and keeps a Passport logbook of every kilometre. Running positions are projected from the published timetable and labelled as estimates. It is free, needs no account, and is independent and not affiliated with Indian Railways or IRCTC.`;

const APP_JSON_LD = {
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  "@id": "https://railly.app/#app",
  name: "Railly",
  applicationCategory: "TravelApplication",
  operatingSystem: "iOS",
  url: "https://railly.app",
  description: DESCRIPTION,
  featureList: FEATURES,
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
