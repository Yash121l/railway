import { Award, TrainFront } from "lucide-react";
import { FeatureJourney } from "@/components/marketing/FeatureJourney";
import { ClosingCta, Footer } from "@/components/marketing/Footer";
import { HeroOrbit } from "@/components/marketing/HeroOrbit";
import { JourneyBar } from "@/components/marketing/JourneyBar";
import {
  Friends,
  ImportStrip,
  MoreGrid,
  NetworkIntel,
  PassportTeaser,
} from "@/components/marketing/MidSections";
import { AnnouncementBar, Nav } from "@/components/marketing/Nav";
import { PressWall } from "@/components/marketing/PressWall";
import { Pricing } from "@/components/marketing/Pricing";
import { ScrollScrub } from "@/components/marketing/ScrollStrip";
import { Testimonials } from "@/components/marketing/Testimonials";

function Laurel({
  icon,
  title,
  sub,
}: {
  icon: React.ReactNode;
  title: string;
  sub: string;
}) {
  return (
    <span className="flex items-center gap-2.5">
      {icon}
      <span className="text-left leading-tight">
        <span className="block text-[14px] font-bold text-black">{title}</span>
        <span className="block text-[13px] text-steel">⟨ {sub} ⟩</span>
      </span>
    </span>
  );
}

function Hero() {
  return (
    <header className="px-4 pt-14 text-center md:pt-20">
      <h1
        className="hero-rise mx-auto max-w-4xl text-[44px] font-bold leading-[1.02] tracking-[-1.8px] text-black md:text-[74px]"
        style={{ "--stagger": "0ms" } as React.CSSProperties}
      >
        Get the truth when you take the train
      </h1>

      <p
        className="hero-rise mx-auto mt-7 max-w-2xl text-[17px] leading-relaxed text-carbon md:text-[19px]"
        style={{ "--stagger": "110ms" } as React.CSSProperties}
      >
        The only app that tells you everything about your train. Real-time
        running status, the fastest alerts, and delay predictions so
        you&apos;re always the first to know and replan—all in a sleek,
        easy-to-use app. Perfect for daily commuters and simple enough for
        everyone.
      </p>

      <div
        className="hero-rise mt-8 flex flex-wrap items-center justify-center gap-8"
        style={{ "--stagger": "220ms" } as React.CSSProperties}
      >
        <Laurel
          icon={<Award size={30} className="text-[#8e8e93]" strokeWidth={1.6} />}
          title="Design Award"
          sub="Winner 2026"
        />
        <Laurel
          icon={
            <span className="flex h-8 w-8 items-center justify-center rounded-[9px] bg-signal">
              <TrainFront size={17} className="text-white" />
            </span>
          }
          title="App of the Year"
          sub="Finalist 2026"
        />
      </div>

      {/* the phone bridges into the dark press wall below — flighty's
          white-to-midnight handoff happens behind the device */}
      <div
        className="hero-rise relative z-10 -mb-24 md:-mb-32"
        style={{ "--stagger": "330ms" } as React.CSSProperties}
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
      {/* the sticky bar rides the viewport bottom through this whole span */}
      <div className="relative">
        <Hero />
        <PressWall />
        <NetworkPulse />
        <FeatureJourney />
        <JourneyBar />
      </div>
      <ImportStrip />
      <Friends />
      <PassportTeaser />
      <NetworkIntel />
      <MoreGrid />
      <Testimonials />
      <Pricing />
      <ClosingCta />
      <Footer />
    </div>
  );
}
