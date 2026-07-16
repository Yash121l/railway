import type { Metadata } from "next";
import { Smartphone } from "lucide-react";
import { APP_CTA_HREF, APP_CTA_LABEL } from "@/lib/cta";
import { FeatureJourney } from "@/components/marketing/FeatureJourney";
import { ClosingCta, Footer } from "@/components/marketing/Footer";
import { HeroOrbit } from "@/components/marketing/HeroOrbit";
import { JourneyBar } from "@/components/marketing/JourneyBar";
import {
  Friends,
  MoreGrid,
  NetworkIntel,
  PassportTeaser,
} from "@/components/marketing/MidSections";
import { AnnouncementBar, Nav } from "@/components/marketing/Nav";
import { Pricing } from "@/components/marketing/Pricing";
import { ScrollScrub } from "@/components/marketing/ScrollStrip";
import { Testimonials } from "@/components/marketing/Testimonials";
import { WhatIsRailly } from "@/components/marketing/WhatIsRailly";

const HOME_TITLE =
  "Live Train Status, PNR Status & Delay Predictions for Indian Railways — Railly";
const HOME_DESCRIPTION =
  "Track any Indian Railways train live — running status, PNR status, seat availability, coach position, and delay predictions before the railway announces them. Built for iPhone. 4,022 trains, 9,161 stations, works offline.";

export const metadata: Metadata = {
  title: { absolute: HOME_TITLE },
  description: HOME_DESCRIPTION,
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    siteName: "Railly",
    locale: "en_IN",
    url: "/",
    title: HOME_TITLE,
    description: HOME_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: HOME_TITLE,
    description: HOME_DESCRIPTION,
  },
};

function Hero() {
  return (
    <header className="px-4 pt-14 text-center md:pt-20">
      {/* flighty's H1 spec: 65px / 700 / −1px, system stack */}
      <h1
        className="hero-rise mx-auto max-w-3xl text-[44px] font-bold leading-[1.04] tracking-[-1px] text-black [text-wrap:balance] md:text-[65px]"
        style={{ "--stagger": "0ms" } as React.CSSProperties}
      >
        Get the truth when you take the train
      </h1>

      <p
        className="hero-rise mx-auto mt-7 max-w-2xl text-[17px] leading-relaxed text-carbon md:text-[19px]"
        style={{ "--stagger": "110ms" } as React.CSSProperties}
      >
        Railly is the Flighty of Indian Railways — built for iPhone. Live
        running status, PNR confirmations, seat availability, coach position,
        and delay predictions before the railway announces them. For Vande
        Bharat and AC-corridor commuters, families watching a loved one&apos;s
        train, and NRIs following the journey home from abroad.
      </p>

      <p
        className="hero-rise mx-auto mt-4 max-w-xl text-[15px] leading-relaxed text-steel"
        style={{ "--stagger": "150ms" } as React.CSSProperties}
      >
        Not a booking app. No ads, no upsells — when you&apos;re ready to buy,
        Railly deep-links you straight to IRCTC.
      </p>

      <div
        className="hero-rise mt-6 flex flex-wrap items-center justify-center gap-x-3 gap-y-1 text-[14px] font-semibold text-steel"
        style={{ "--stagger": "185ms" } as React.CSSProperties}
      >
        <span className="tnum">
          <b className="text-black">4,022</b> trains
        </span>
        <span className="text-fog">·</span>
        <span className="tnum">
          <b className="text-black">9,161</b> stations
        </span>
        <span className="text-fog">·</span>
        <span>works offline</span>
      </div>

      <div
        className="hero-rise mt-8 flex justify-center"
        style={{ "--stagger": "220ms" } as React.CSSProperties}
      >
        <a
          href={APP_CTA_HREF}
          className="inline-flex items-center gap-2 rounded-full bg-black px-7 py-3.5 text-[16px] font-semibold text-white transition-transform hover:scale-[1.03] active:scale-95"
        >
          {APP_CTA_LABEL}
          <Smartphone size={17} />
        </a>
      </div>

      {/* the phone bridges into the dark feature band below — flighty's
          white-to-midnight handoff happens behind the device */}
      <div
        className="hero-rise relative z-10 -mb-32 md:-mb-44"
        style={{ "--stagger": "270ms" } as React.CSSProperties}
      >
        <HeroOrbit />
      </div>
    </header>
  );
}

/** Live routes drifting past as you scroll — the network never stops moving. */
const PULSE_ROWS: [string, string, "go" | "sun" | "signal"][][] = [
  [
    ["12951", "Mumbai Rajdhani", "go"],
    ["22436", "Vande Bharat", "go"],
    ["12627", "Karnataka Exp", "sun"],
    ["12301", "Howrah Rajdhani", "go"],
    ["12009", "Shatabdi Exp", "signal"],
    ["12841", "Coromandel Exp", "sun"],
  ],
  [
    ["20901", "Vande Bharat", "go"],
    ["12259", "Sealdah Duronto", "go"],
    ["12952", "New Delhi Rajdhani", "signal"],
    ["12628", "Karnataka Exp", "go"],
    ["12302", "Kolkata Rajdhani", "sun"],
    ["12010", "Shatabdi Exp", "go"],
  ],
];

const PULSE_DOT = {
  go: "bg-go",
  sun: "bg-sun",
  signal: "bg-signal",
} as const;

function NetworkPulse() {
  return (
    <ScrollScrub
      amplitude={150}
      className="overflow-x-clip border-y border-black/[0.05] bg-white py-10"
    >
      <div className="flex flex-col gap-3">
        {PULSE_ROWS.map((row, r) => (
          <div
            key={r}
            data-scrub-row
            className="flex w-max gap-3 self-center will-change-transform"
          >
            {row.map(([no, name, tone]) => (
              <span
                key={no}
                className="flex shrink-0 items-center gap-2 rounded-full bg-linen py-2 pl-3 pr-4 text-[13px] ring-1 ring-black/[0.05]"
              >
                <span className={`h-1.5 w-1.5 rounded-full ${PULSE_DOT[tone]}`} />
                <span className="tnum font-bold text-black">{no}</span>
                <span className="text-carbon">{name}</span>
              </span>
            ))}
          </div>
        ))}
      </div>
    </ScrollScrub>
  );
}

export default function Home() {
  return (
    // overflow-x-clip (not hidden: that would break the sticky bars) so
    // directional reveals and the scrub strips never widen the page
    <div className="overflow-x-clip bg-white">
      <AnnouncementBar />
      <Nav />
      <main id="main-content">
        {/* the sticky bar rides the viewport bottom through this whole span */}
        <div className="relative">
          <Hero />
          <FeatureJourney />
          <JourneyBar />
        </div>
        <Friends />
        <PassportTeaser />
        {/* the live strip tees up the Network Intelligence section */}
        <NetworkPulse />
        <NetworkIntel />
        <MoreGrid />
        <Testimonials />
        <WhatIsRailly />
        <Pricing />
        <ClosingCta />
      </main>
      <Footer />
    </div>
  );
}
