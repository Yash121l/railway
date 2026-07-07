import Link from "next/link";
import { Award, LayoutGrid, TrainFront } from "lucide-react";
import { FeatureJourney } from "@/components/marketing/FeatureJourney";
import { ClosingCta, Footer } from "@/components/marketing/Footer";
import { HeroOrbit } from "@/components/marketing/HeroOrbit";
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
import { Reveal } from "@/components/marketing/Reveal";
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
    <header className="px-4 pb-10 pt-14 text-center md:pt-20">
      <Reveal>
        <h1 className="mx-auto max-w-4xl text-[44px] font-bold leading-[1.02] tracking-[-1.8px] text-black md:text-[74px]">
          Get the truth when you take the train
        </h1>
      </Reveal>

      <Reveal delay={80}>
        <p className="mx-auto mt-7 max-w-2xl text-[17px] leading-relaxed text-carbon md:text-[19px]">
          The only app that tells you everything about your train. Real-time
          running status, the fastest alerts, and delay predictions so
          you&apos;re always the first to know and replan—all in a sleek,
          easy-to-use app. Perfect for daily commuters and simple enough for
          everyone.
        </p>
      </Reveal>

      <Reveal delay={160}>
        <div className="mt-8 flex flex-wrap items-center justify-center gap-8">
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
      </Reveal>

      <Reveal delay={240}>
        <HeroOrbit />
      </Reveal>
    </header>
  );
}

/** flighty.com's signature: a dark segmented pill pinned to the viewport
 *  bottom while you scroll the hero and feature journey. */
function StickyJourneyBar() {
  return (
    <div className="pointer-events-none sticky bottom-6 z-40 flex justify-center px-4 pb-2">
      <div className="pointer-events-auto flex items-center gap-1 overflow-x-auto rounded-full bg-[#111318]/95 p-1.5 shadow-[0_10px_36px_rgba(0,0,0,0.35)] backdrop-blur no-scrollbar">
        <a
          href="#before-you-board"
          className="flex shrink-0 items-center gap-1.5 rounded-full bg-sun px-4 py-2 text-[14px] font-semibold text-black"
        >
          <TrainFront size={14} />
          Before you board
        </a>
        <a
          href="#on-the-platform"
          className="shrink-0 rounded-full px-4 py-2 text-[14px] font-medium text-white/85 hover:text-white"
        >
          On the platform
        </a>
        <a
          href="#after-arrival"
          className="shrink-0 rounded-full px-4 py-2 text-[14px] font-medium text-white/85 hover:text-white"
        >
          After arrival
        </a>
        <span className="mx-1 h-5 w-px shrink-0 bg-white/20" />
        <Link
          href="/app"
          className="flex shrink-0 items-center gap-1.5 rounded-full px-4 py-2 text-[14px] font-semibold text-white"
        >
          <LayoutGrid size={14} />
          Open App
        </Link>
      </div>
    </div>
  );
}

export default function Home() {
  return (
    <div className="bg-white">
      <AnnouncementBar />
      <Nav />
      {/* the sticky bar rides the viewport bottom through this whole span */}
      <div className="relative">
        <Hero />
        <PressWall />
        <FeatureJourney />
        <StickyJourneyBar />
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
