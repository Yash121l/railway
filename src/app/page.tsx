import Link from "next/link";
import { Award, Medal } from "lucide-react";
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

function Hero() {
  return (
    <header className="px-4 pb-24 pt-16 text-center md:pt-20">
      <Reveal>
        <div className="flex flex-wrap items-center justify-center gap-2.5">
          <span className="flex items-center gap-1.5 rounded-full bg-white px-4 py-2 text-[13px] font-semibold text-black shadow-pill ring-1 ring-black/[0.06]">
            <Award size={14} />
            Design Award · Winner 2026
          </span>
          <span className="flex items-center gap-1.5 rounded-full bg-signal px-4 py-2 text-[13px] font-semibold text-white">
            <Medal size={14} />
            App of the Year · Finalist 2026
          </span>
        </div>
      </Reveal>

      <Reveal delay={80}>
        <h1 className="mx-auto mt-8 max-w-3xl text-[40px] font-bold leading-[1.02] tracking-[-1.4px] text-black md:text-display">
          Get the truth when you take the train.
        </h1>
      </Reveal>

      <Reveal delay={160}>
        <p className="mx-auto mt-6 max-w-2xl text-[17px] leading-relaxed text-carbon md:text-[19px]">
          The only app that tells you everything about your train. Real-time
          running status, the fastest alerts, and delay predictions so
          you&apos;re always the first to know and replan—all in a sleek,
          easy-to-use app. Perfect for million-milers and simple enough for
          everyone.
        </p>
      </Reveal>

      <Reveal delay={240}>
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
          <Link
            href="/app"
            className="rounded-full bg-signal px-8 py-4 text-[16px] font-semibold text-white transition-transform hover:scale-[1.03]"
          >
            Open Railly
          </Link>
          <Link
            href="/app/track"
            className="rounded-full border border-black/40 px-8 py-4 text-[16px] font-semibold text-black transition-colors hover:bg-black hover:text-white"
          >
            See it live →
          </Link>
        </div>
      </Reveal>

      <Reveal delay={320}>
        <div className="pb-8">
          <HeroOrbit />
        </div>
      </Reveal>
    </header>
  );
}

export default function Home() {
  return (
    <div className="bg-white">
      <AnnouncementBar />
      <Nav />
      <Hero />
      <PressWall />
      <FeatureJourney />
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
