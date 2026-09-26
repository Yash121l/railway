import Image from "next/image";
import {
  AlarmClock,
  Armchair,
  BellRing,
  History,
  Lock,
  TrainFront,
} from "lucide-react";
import { APP_CTA_HREF, APP_CTA_LABEL } from "@/lib/cta";
import { CountUp } from "./CountUp";
import { LiveActivityMock } from "./LiveActivityMock";
import { LiveBoard } from "./LiveBoard";
import { NetworkCanvas } from "./NetworkCanvas";
import { NotifCard } from "./NotifCard";
import { DynamicIsland } from "./PhoneMock";
import { Reveal } from "./Reveal";
import { SCREEN_HEIGHT, SCREEN_WIDTH, SCREENS } from "./screens";
import { ScrollScrub } from "./ScrollStrip";
import { Starfield } from "./Starfield";

/** A slim device frame around a real app screenshot. */
export function MiniPhone({
  src,
  alt,
  className = "",
  size = "w-[228px] md:w-[250px]",
  sizes = "(min-width: 768px) 236px, 214px",
}: {
  src: string;
  alt: string;
  className?: string;
  /** width utilities for the frame; override instead of stacking w-* classes */
  size?: string;
  /** the image `sizes` hint matching `size`, minus the 7px bezel each side */
  sizes?: string;
}) {
  return (
    <div
      className={`rounded-[36px] bg-[#0c0d10] p-[7px] shadow-deep ring-1 ring-black/60 ${size} ${className}`}
    >
      <div className="@container relative overflow-hidden rounded-[29px] bg-black">
        <Image
          src={src}
          alt={alt}
          width={SCREEN_WIDTH}
          height={SCREEN_HEIGHT}
          sizes={sizes}
          className="block h-auto w-full"
        />
        <DynamicIsland />
      </div>
    </div>
  );
}

/** The trip share card from the app (ShareCards.swift), drawn for the web. Demo trip. */
function ShareCardMock() {
  return (
    <div className="w-full max-w-[300px] rotate-[2deg] rounded-[20px] bg-white p-4 shadow-float">
      <div className="flex items-center justify-between">
        <span className="text-[11px] font-bold tracking-[1.2px] text-steel">RAILLY</span>
        <span className="rounded-full bg-latered/10 px-2 py-0.5 text-[11px] font-bold text-latered">
          18m late
        </span>
      </div>
      <div className="mt-2 text-[12px] font-semibold text-steel">12951 · Mumbai Rajdhani</div>
      <div className="text-[18px] font-bold text-black">
        Mumbai <span className="font-semibold text-steel">to</span> New Delhi
      </div>
      <svg viewBox="0 0 260 110" className="mt-3 w-full rounded-xl bg-[#0f1424]" aria-hidden>
        <path
          d="M40 92 C 60 80, 58 64, 76 56 S 104 44, 118 36 S 150 22, 176 20 S 214 14, 226 12"
          fill="none"
          stroke="rgba(255,255,255,0.25)"
          strokeWidth="3"
          strokeLinecap="round"
        />
        <path
          d="M40 92 C 60 80, 58 64, 76 56 S 104 44, 118 36"
          fill="none"
          stroke="#FF453A"
          strokeWidth="3"
          strokeLinecap="round"
        />
        <circle cx="118" cy="36" r="9" fill="#FF453A" opacity="0.25" />
        <circle cx="118" cy="36" r="4.5" fill="#fff" />
        <text x="30" y="106" fill="rgba(255,255,255,0.85)" fontSize="10" fontWeight="700">MMCT</text>
        <text x="208" y="28" fill="rgba(255,255,255,0.85)" fontSize="10" fontWeight="700">NDLS</text>
      </svg>
      <div className="mt-3 flex items-end justify-between">
        <div>
          <div className="text-[10px] font-bold uppercase tracking-[1px] text-steel">Arrives</div>
          <div className="tnum text-[28px] font-bold leading-none text-latered">
            08:50<sup className="text-[12px]">+1</sup>
          </div>
        </div>
        <div className="tnum text-right text-[11px] text-steel">38% of 1,384 km</div>
      </div>
      <div className="mt-3 flex justify-between border-t border-black/[0.06] pt-2 text-[10px] text-steel">
        <span>Estimated from the timetable · Railly</span>
        <span>Sat 26 Sep</span>
      </div>
    </div>
  );
}

export function Friends() {
  return (
    <section id="friends" className="mx-auto max-w-6xl scroll-mt-24 px-4 py-24 md:py-32">
      <Reveal className="mx-auto max-w-3xl text-center">
        <h2 className="text-headline text-black md:text-[52px] md:leading-[1.03] md:tracking-[-0.5px]">
          Share your journeys with friends and family.
        </h2>
        <p className="mt-5 text-[18px] leading-relaxed text-carbon">
          Railly Friends will let you share your travels with the people you
          pick. Add them once, and you won&apos;t have to forward a PNR again.
        </p>
        <p className="mt-4 inline-flex items-center gap-1.5 rounded-full bg-sun/20 px-3 py-1 text-[12px] font-bold text-[#7a5a00]">
          Railly Friends is on the roadmap, not in the app yet. Here&apos;s the
          plan, and what you can share today.
        </p>
      </Reveal>

      {/* flighty's Friends card: the headline lives INSIDE the big panel,
          tilted devices on the right, slight scroll parallax */}
      <Reveal delay={80} from="zoom">
        <ScrollScrub
          amplitude={54}
          className="relative mt-14 overflow-hidden rounded-3xl bg-linen ring-1 ring-black/[0.05]"
        >
          <div className="grid md:grid-cols-2">
            <div className="flex flex-col justify-between p-8 md:min-h-[460px] md:p-10">
              <div>
              <span className="inline-flex w-fit items-center gap-1.5 rounded-full bg-sun/20 px-2.5 py-1 text-[11px] font-bold uppercase tracking-[1px] text-[#7a5a00]">
                Coming later
              </span>
              <h3 className="mt-4 max-w-[300px] text-[26px] font-bold leading-tight tracking-tight text-black md:text-[30px]">
                Never hear, &ldquo;send me your train info?&rdquo; ever again.
              </h3>
              </div>
              <p className="mt-6 max-w-[320px] text-[15px] leading-relaxed text-carbon md:mt-0">
                The plan: choose who you share your journeys with, and they
                pick the updates they get about your trip. The phones show
                today&apos;s app, not Friends.
              </p>
            </div>
            <div className="relative h-[360px] md:h-auto">
              <div
                data-scrub-row
                className="absolute left-1/2 top-8 -translate-x-[96%] rotate-[-7deg] will-change-transform"
              >
                <MiniPhone
                  src={SCREENS.globe}
                  alt="Railly's satellite globe with every trip drawn on its real track and the sheet pulled down"
                />
              </div>
              <div
                data-scrub-row
                className="absolute left-1/2 top-20 translate-x-[2%] rotate-[6deg] will-change-transform"
              >
                <MiniPhone
                  src={SCREENS.tripDetail}
                  alt="Railly trip detail: Mumbai to New Delhi over the focused route, arriving 18 minutes late, labelled Estimated"
                />
              </div>
            </div>
          </div>
          <div className="pointer-events-none absolute inset-x-0 bottom-0 h-20 bg-gradient-to-t from-linen to-transparent" />
        </ScrollScrub>
      </Reveal>

      {/* the two follow-up cards get flighty's green section headings */}
      <div className="mt-4 grid gap-4 md:grid-cols-2">
        <Reveal delay={60}>
          <div className="flex h-full flex-col rounded-3xl bg-linen p-8 ring-1 ring-black/[0.05] md:p-10">
            <span className="inline-flex w-fit items-center gap-1.5 rounded-full bg-sun/20 px-2.5 py-1 text-[11px] font-bold uppercase tracking-[1px] text-[#7a5a00]">
                Coming later
            </span>
            <h3 className="mt-4 max-w-[340px] text-[19px] font-bold leading-snug tracking-tight text-ontime">
              Updates about your loved ones&apos; journeys.
            </h3>
            <div className="mt-8 flex flex-1 flex-col items-center justify-center gap-4">
              <NotifCard
                title="Dad is on rails today"
                body="12951 to New Delhi departs in 4h, on time so far."
                time="13:00"
                emoji="👨🏻‍🦳"
                tilt={-2}
                drift
              />
              <NotifCard
                title="Dad left Mumbai Central"
                body="Arrives tomorrow at 09:32, 5m early."
                time="17:05"
                accent="go"
                emoji="👨🏻‍🦳"
                tilt={2}
                drift
              />
              <p className="text-[12px] text-steel">A sketch of the plan.</p>
            </div>
          </div>
        </Reveal>
        <Reveal delay={120}>
          <div className="flex h-full flex-col rounded-3xl bg-linen p-8 ring-1 ring-black/[0.05] md:p-10">
            <span className="inline-flex w-fit items-center gap-1.5 rounded-full bg-go/15 px-2.5 py-1 text-[11px] font-bold uppercase tracking-[1px] text-ontime">
              In the app today
            </span>
            <h3 className="mt-4 max-w-[340px] text-[19px] font-bold leading-snug tracking-tight text-ontime">
              Share a trip as a picture, ready for WhatsApp.
            </h3>
            <p className="mt-2 max-w-[380px] text-[14px] leading-relaxed text-carbon">
              Tap Share on any trip for a card with the route on its real
              track, where the train is, and when it arrives. Or send it as
              one line of text.
            </p>
            <div className="mt-8 flex flex-1 items-center justify-center">
              <ShareCardMock />
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

export function PassportTeaser() {
  const stats: [React.ReactNode, string][] = [
    [<CountUp key="km" value={16418} />, "kilometres"],
    [<CountUp key="trips" value={12} />, "trips"],
    [<CountUp key="hours" value={231} suffix="h" />, "on rails"],
    ["+2h 05m", "worst delay"],
  ];
  return (
    <section id="passport" className="bg-linen px-4 py-24 md:py-32">
      <div className="mx-auto grid max-w-6xl items-center gap-12 md:grid-cols-2">
        <Reveal from="left">
          <h2 className="text-headline text-black md:text-[52px] md:leading-[1.03] md:tracking-[-0.5px]">
            Look back on your travels, near and far.
          </h2>
          <p className="mt-5 text-[18px] leading-relaxed text-carbon">
            How far have you ridden? How many hours have delays cost you? Tap
            your avatar and the Railly Passport has the answer: distance in real
            track kilometres, trips, rail time and stations. The Delay Report
            next to it adds up the hours lost to delays, estimated from the
            timetable.
          </p>
          <a
            href={APP_CTA_HREF}
            className="mt-7 inline-block rounded-full bg-signal px-7 py-3.5 text-[15px] font-semibold text-white transition-transform hover:scale-[1.03] active:scale-95"
          >
            {APP_CTA_LABEL}
          </a>
        </Reveal>
        <Reveal delay={120} from="right">
          <div className="glow-violet relative overflow-hidden rounded-3xl p-7 ring-1 ring-black/10">
            <Starfield className="opacity-70" />
            <div className="relative">
              <div className="text-[11px] font-bold uppercase tracking-[2px] text-sun">
                Railly Passport · sample
              </div>
              <div className="mt-5 grid grid-cols-2 gap-5">
                {stats.map(([value, label]) => (
                  <div key={label}>
                    <div className="tnum text-[30px] font-extrabold tracking-tight text-white">
                      {value}
                    </div>
                    <div className="mt-1 text-[11px] font-bold uppercase tracking-[1px] text-white/50">
                      {label}
                    </div>
                  </div>
                ))}
              </div>
              <div className="mt-6 border-t border-white/15 pt-4 text-[13px] text-white/60">
                Example figures from a sample passport. Yours is computed from
                the trips you actually track.
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

/**
 * flighty's Airport Intelligence pills, translated to stations: every code
 * color-coded by current operations — green flowing, amber strained, red
 * melting down. A static, deterministic sample so SSR stays stable.
 */
const STATION_STATUS: [string, "go" | "sun" | "crit"][] = [
  ["NDLS", "sun"], ["MMCT", "go"], ["HWH", "go"], ["SBC", "go"],
  ["MAS", "go"], ["CSMT", "go"], ["ADI", "go"], ["BSB", "sun"],
  ["PUNE", "go"], ["JP", "go"], ["LKO", "crit"], ["PNBE", "sun"],
  ["BPL", "go"], ["NGP", "go"], ["SC", "go"], ["TVC", "go"],
  ["GHY", "sun"], ["CDG", "go"], ["RTM", "crit"], ["KOTA", "go"],
];

const STATUS_DOT = { go: "bg-go", sun: "bg-sun", crit: "bg-crit" } as const;
const STATUS_RING = {
  go: "ring-go/30 text-go",
  sun: "ring-sun/30 text-sun",
  crit: "ring-crit/40 text-[#ff8d7f]",
} as const;

function StationPills() {
  return (
    <div className="mx-auto mt-12 max-w-4xl">
      <div className="flex flex-wrap justify-center gap-2.5">
        {STATION_STATUS.map(([code, status]) => (
          <span
            key={code}
            className={`flex items-center gap-2 rounded-full bg-white/[0.04] py-2 pl-3 pr-4 text-[14px] font-bold tracking-[0.03em] ring-1 ${STATUS_RING[status]}`}
          >
            <span className={`h-2 w-2 rounded-full ${STATUS_DOT[status]} ${status !== "go" ? "animate-pulse-dot" : ""}`} />
            {code}
          </span>
        ))}
      </div>
      <div className="mt-6 grid gap-4 text-center sm:grid-cols-3">
        {[
          ["Live station conditions", "Arrivals, departures, delays and why — for every major junction."],
          ["What could disrupt you", "Fog banks, rake shortages, yard congestion. Even cattle on the track."],
          ["Platform Regulars", "Railly ranks you and your friends by station activity, so you can flex — or ask which stall has the best chai."],
        ].map(([title, body]) => (
          <div key={title}>
            <div className="text-[15px] font-bold text-white">{title}</div>
            <p className="mt-1 text-[13px] leading-relaxed text-white/55">{body}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

/** flighty's TV Mode teaser: broadcast the meltdown — marked coming soon. */
function TvModeTeaser() {
  return (
    <div className="mx-auto mt-14 max-w-4xl overflow-hidden rounded-3xl bg-ink/80 ring-1 ring-white/[0.08]">
      <div className="grid items-center md:grid-cols-[1fr_auto]">
        <div className="p-7 md:p-9">
          <div className="flex items-center gap-2 text-[11px] font-bold uppercase tracking-[2px] text-sun">
            <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-crit" />
            TV Mode · Coming soon
          </div>
          <h3 className="mt-3 text-[24px] font-bold leading-tight tracking-tight text-white md:text-[28px]">
            Broadcast any station meltdown live.
          </h3>
          <p className="mt-3 max-w-md text-[15px] leading-relaxed text-white/60">
            The plan: stream the live status of the whole network — or just your
            home station — on any screen. Perfect for the office, the waiting
            room, or dramatic effect.
          </p>
          <span className="mt-6 inline-block rounded-full bg-white/[0.08] px-6 py-3 text-[14px] font-semibold text-white/70 ring-1 ring-white/[0.12]">
            Coming soon
          </span>
        </div>
        {/* a mini "broadcast" board */}
        <div className="hidden p-9 md:block">
          <div className="w-[290px] rounded-2xl bg-black/60 p-4 ring-1 ring-white/[0.1]">
            <div className="flex items-center justify-between text-[10px] font-bold tracking-[1.5px] text-white/50">
              <span>NEW DELHI · NDLS</span>
              <span className="flex items-center gap-1 text-[#ff8d7f]">
                <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-crit" />
                ON AIR
              </span>
            </div>
            <div className="led-board mt-3 rounded-lg px-3 py-2 text-[11px]">
              12951 RAJDHANI · ARR 09:14 · PF 3
            </div>
            <div className="led-board mt-1.5 rounded-lg px-3 py-2 text-[11px]">
              22436 V.BHARAT · DEP 06:12 · OT
            </div>
            <div className="led-board mt-1.5 rounded-lg px-3 py-2 text-[11px]">
              12627 KARNATAKA · +42 MIN
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export function NetworkIntel() {
  return (
    <section id="network" className="relative scroll-mt-16 overflow-hidden bg-midnight px-4 py-24 text-white md:py-32">
      <Starfield className="opacity-60" />
      {/* control-room radar: a blue sweep slowly circling behind the board */}
      <div
        aria-hidden
        className="absolute left-1/2 top-1/2 h-[880px] w-[880px] -translate-x-1/2 -translate-y-1/2"
      >
        <div
          className="h-full w-full animate-radar rounded-full motion-reduce:animate-none"
          style={{
            background:
              "conic-gradient(from 0deg, rgba(0,123,255,0) 0deg, rgba(0,123,255,0) 300deg, rgba(0,123,255,0.14) 352deg, rgba(77,159,255,0.32) 360deg)",
            maskImage:
              "radial-gradient(circle, rgba(0,0,0,0.9) 0%, rgba(0,0,0,0.35) 55%, transparent 72%)",
            WebkitMaskImage:
              "radial-gradient(circle, rgba(0,0,0,0.9) 0%, rgba(0,0,0,0.35) 55%, transparent 72%)",
          }}
        />
      </div>
      <div className="relative">
        <Reveal className="mx-auto max-w-3xl text-center">
          <h2 className="text-headline md:text-[52px] md:leading-[1.03] md:tracking-[-0.5px]">
            Know what&apos;s happening on any line.
          </h2>
          <p className="mt-5 text-[18px] leading-relaxed text-silver">
            See the whole network at once: every run in progress, how late it
            is, and how each section is holding up. Positions and delays are
            projected from the published timetable, not a live feed, and every
            screen that shows one says so. Reading control-room bulletins for
            fog, line blocks and yard congestion is on the roadmap.
          </p>
        </Reveal>
        <Reveal delay={100} from="zoom">
          {/* the actual simulation, live on canvas — every dot is a train
              the app is tracking at this exact second */}
          <div className="mx-auto mt-12 max-w-4xl overflow-hidden rounded-3xl bg-ink/80 ring-1 ring-white/[0.08]">
            <div className="flex items-center justify-between px-5 pt-4">
              <span className="text-[13px] font-bold uppercase tracking-[1px] text-white/60">
                The network, simulated
              </span>
              <span className="flex items-center gap-1.5 text-[12px] font-semibold text-arc">
                <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-arc" />
                Live simulation
              </span>
            </div>
            <NetworkCanvas className="h-[300px] w-full md:h-[380px]" />
            <p className="px-5 pb-4 pt-3 text-[12px] leading-relaxed text-white/60">
              A living simulation of the network — the app tracks all 4,022
              trains.
            </p>
          </div>
        </Reveal>
        <Reveal delay={120}>
          <StationPills />
        </Reveal>
        <Reveal delay={140} from="zoom">
          <LiveBoard />
          <TvModeTeaser />
          <div className="mt-8 text-center">
            <a
              href={APP_CTA_HREF}
              className="inline-block rounded-full bg-sun px-7 py-3.5 text-[15px] font-semibold text-black transition-transform hover:scale-[1.03] active:scale-95"
            >
              {APP_CTA_LABEL}
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

const MORE = [
  [Lock, "Privacy first.", "No account. Your trips stay on your device, and Railly keeps no copy."],
  [Armchair, "Coach position.", "\"B8 is coach 9 from the engine.\" From the chart's formation once it's out, marked indicative before that."],
  [History, "Where's My Rake.", "Finds the paired service whose rake becomes your train, and projects a late start from it."],
  [AlarmClock, "Tatkal alarm.", "Set it on a train and Railly nudges you 15 minutes before the window opens."],
  [TrainFront, "Real track, not chords.", "Routes follow OpenStreetMap rail where we have it, and say so where we don't."],
  [BellRing, "PNR auto-watch.", "Checks your waitlist in the background and tells you when it moves."],
] as const;

export function MoreGrid() {
  return (
    <section className="mx-auto max-w-6xl px-4 py-24">
      <Reveal>
        <h2 className="text-center text-[28px] font-bold tracking-tight text-black md:text-[32px]">
          More reasons you&apos;ll want to take Railly on your next trip.
        </h2>
      </Reveal>
      {/* bento: the Live Activity runs live in the tall cell, features wrap it */}
      <div className="mt-12 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        <Reveal from="zoom" className="sm:row-span-3 lg:row-span-3">
          <LiveActivityMock />
        </Reveal>
        {MORE.map(([Icon, title, body], i) => (
          <Reveal key={title} delay={i * 60}>
            <div className="card-lift flex h-full flex-col gap-2.5 rounded-2xl bg-linen p-5 ring-1 ring-black/[0.05]">
              <Icon size={20} className="text-carbon" strokeWidth={1.8} />
              <p>
                <span className="text-[15px] font-bold text-black">{title}</span>{" "}
                <span className="text-[15px] text-carbon">{body}</span>
              </p>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
