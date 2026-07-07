import React from "react";
import { CloudFog, TrainFront } from "lucide-react";
import { MiniPhone } from "./MidSections";
import { NotifCard } from "./NotifCard";
import { Reveal } from "./Reveal";
import { Starfield } from "./Starfield";

function Vignette({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-[260px] items-center justify-center rounded-3xl bg-linen p-5 sm:p-8 ring-1 ring-black/[0.05]">
      <div className="space-y-4">{children}</div>
    </div>
  );
}

/** Mini "where's my rake" inbound tracker — the bar creeps closer, live */
function InboundRakeCard() {
  return (
    <div className="w-full max-w-[300px] rounded-[20px] bg-white p-4 shadow-float" style={{ rotate: "-2deg" }}>
      <div className="text-[11px] font-bold uppercase tracking-[1px] text-steel">
        Where&apos;s my rake
      </div>
      <div className="mt-2 flex items-center gap-2 text-[15px] font-semibold text-black">
        <TrainFront size={16} className="text-signal" />
        Arriving from Ahmedabad
      </div>
      <div className="relative mt-3 h-[3px] w-full rounded-full bg-black/10">
        <div className="h-full animate-creep rounded-full bg-signal motion-reduce:w-[78%] motion-reduce:animate-none" />
      </div>
      <p className="mt-2 text-[13px] text-steel">
        Running 12m late · your departure impact: <b className="text-black">+9m</b>
      </p>
    </div>
  );
}

function ProDataCard() {
  const cells = [
    ["Platform", "PF 5"],
    ["Coach", "C4 · front"],
    ["Seat", "32A window"],
    ["Exit", "Gate 2"],
  ];
  return (
    <div className="w-full max-w-[300px] rounded-[20px] bg-white p-4 shadow-float" style={{ rotate: "1.5deg" }}>
      <div className="grid grid-cols-2 gap-3">
        {cells.map(([label, value]) => (
          <div key={label}>
            <div className="text-[10px] font-bold uppercase tracking-[1px] text-fog">
              {label}
            </div>
            <div className="mt-0.5 text-[17px] font-bold text-black">{value}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

/** Minimal side-view rake silhouette — the night card's "hero photo". */
function RakeSilhouette() {
  return (
    <svg viewBox="0 0 320 64" className="w-full" aria-hidden>
      {/* loco with sloped nose */}
      <path
        d="M12 50 L12 26 Q12 18 22 17 L96 14 Q104 14 106 20 L110 50 Z"
        fill="#e8eaf0"
      />
      <rect x="22" y="22" width="70" height="10" rx="4" fill="#20293f" />
      {/* coaches */}
      <rect x="116" y="16" width="92" height="34" rx="7" fill="#dfe3ec" />
      <rect x="124" y="23" width="76" height="9" rx="3.5" fill="#20293f" />
      <rect x="214" y="16" width="92" height="34" rx="7" fill="#dfe3ec" />
      <rect x="222" y="23" width="76" height="9" rx="3.5" fill="#20293f" />
      {/* wheels */}
      {[34, 78, 136, 186, 234, 284].map((x) => (
        <circle key={x} cx={x} cy="54" r="6" fill="#39435c" />
      ))}
      {/* headlight beam */}
      <circle cx="17" cy="38" r="3" fill="#f6c445" />
    </svg>
  );
}

/** Signal gantry silhouette against the dusk — the control-room card. */
function GantrySilhouette() {
  return (
    <svg viewBox="0 0 360 150" className="w-full" aria-hidden>
      <g fill="#150a2e">
        {/* masts */}
        <rect x="36" y="10" width="9" height="140" />
        <rect x="315" y="10" width="9" height="140" />
        {/* truss */}
        <rect x="36" y="18" width="288" height="8" />
        <rect x="36" y="34" width="288" height="4" />
        {/* hangers + signal heads */}
        <rect x="105" y="38" width="4" height="18" />
        <rect x="96" y="54" width="22" height="44" rx="8" />
        <rect x="215" y="38" width="4" height="18" />
        <rect x="206" y="54" width="22" height="44" rx="8" />
      </g>
      {/* lit aspects */}
      <circle cx="107" cy="68" r="6" fill="#30d158" opacity="0.95" />
      <circle cx="107" cy="84" r="6" fill="#0b0620" />
      <circle cx="217" cy="68" r="6" fill="#0b0620" />
      <circle cx="217" cy="84" r="6" fill="#f6c445" opacity="0.95" />
    </svg>
  );
}

/**
 * flighty opens its feature run with a huge dark card: copy on the left,
 * the real product cropped at the card edge on the right. Same here —
 * the screenshot is our actual trip-detail screen, with the live
 * inbound-rake card floating over it.
 */
function DarkIntroCard() {
  return (
    <Reveal from="zoom">
      <div
        id="before-you-board"
        className="relative scroll-mt-28 overflow-hidden rounded-3xl bg-gradient-to-b from-[#161028] to-[#0b081a] ring-1 ring-white/[0.06]"
      >
        <Starfield className="opacity-40" />
        <div className="relative grid items-center md:grid-cols-2">
          <div className="p-8 md:p-12">
            <h3 className="text-[26px] font-bold leading-tight tracking-tight text-white md:text-[30px]">
              See why you&apos;re delayed. Finally!
            </h3>
            <p className="mt-4 max-w-md text-[15px] leading-relaxed text-white/65">
              Railways often keep delay information under wraps until the last
              minute. Railly doesn&apos;t. We track your inbound rake 24 hours
              before departure, so we can predict a new time long before the
              announcement crackles over the PA.
            </p>
          </div>
          <div className="relative h-[340px] md:h-[430px]">
            <div className="absolute left-1/2 top-10 -translate-x-1/2 rotate-[4deg] md:left-auto md:right-14 md:translate-x-0">
              <MiniPhone
                src="/screens/trip-detail.png"
                alt="Railly trip detail with delay prediction and live map"
              />
            </div>
            <div className="absolute bottom-8 left-4 w-[300px] md:left-10" style={{ rotate: "-3deg" }}>
              <InboundRakeCard />
            </div>
          </div>
        </div>
      </div>
    </Reveal>
  );
}

/** The two flighty-style graphic cards: night sky + dusk control room. */
function DarkFeaturePair() {
  return (
    <div id="on-the-platform" className="grid scroll-mt-28 gap-4 md:grid-cols-2">
      <Reveal from="left" className="h-full">
        <div className="night-sky card-lift relative h-full overflow-hidden rounded-3xl p-7 ring-1 ring-white/[0.06]">
          <Starfield className="opacity-80" />
          <div className="relative flex h-full flex-col">
            <h3 className="text-[22px] font-bold leading-snug tracking-tight text-white">
              Delay predictions.{" "}
              <span className="text-white/60">
                Long before the railway admits it.
              </span>
            </h3>
            <p className="mt-3 text-[14px] leading-relaxed text-white/60">
              Late rakes are the #1 cause of delays. Railly uses machine
              learning to predict them — up to 6 hours before the railway says
              anything.
            </p>
            <div className="mt-6 rounded-2xl bg-white/[0.06] p-5 ring-1 ring-white/[0.08]">
              <div className="text-[17px] font-bold text-white">
                Where&apos;s My Rake?
              </div>
              <div className="mt-0.5 text-[12px] text-white/50">
                WAP-7 hauled · 22 LHB coaches · inbound from Ahmedabad
              </div>
              <div className="mt-5">
                <RakeSilhouette />
              </div>
              <span className="mt-4 inline-block rounded-md bg-crit px-2.5 py-1 text-[11px] font-bold uppercase tracking-[0.5px] text-white">
                ⚠ Running late
              </span>
              <div className="mt-2 text-[13px] font-medium text-white/85">
                40m delay predicted due to the late arriving rake
              </div>
              <div className="mt-4 space-y-2.5 border-t border-white/10 pt-3">
                <div className="flex items-center justify-between text-[13px]">
                  <span className="font-semibold text-white">My Train</span>
                  <span className="font-semibold text-[#e58fff]">
                    ✦ 40m Delay Predicted
                  </span>
                </div>
                <div className="flex items-center justify-between text-[13px]">
                  <span className="text-white/55">
                    Ahmedabad to Mumbai · arriving in 1h 10m
                  </span>
                  <span className="font-semibold text-[#ff7b6e]">
                    52m Late
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Reveal>

      <Reveal from="right" delay={90} className="h-full">
        <div className="dusk-sky card-lift relative h-full overflow-hidden rounded-3xl p-7 ring-1 ring-white/[0.06]">
          <div className="relative flex h-full flex-col">
            <h3 className="text-[22px] font-bold leading-snug tracking-tight text-white">
              Direct from the control room.{" "}
              <span className="text-white/70">
                Section mandates are the #2 cause of delays.
              </span>
            </h3>
            <p className="mt-3 text-[14px] leading-relaxed text-white/70">
              Railly sifts through control-room bulletins and tells you what
              might impact your train: fog blocks, crossings, line works, yard
              congestion.
            </p>
            <div className="mt-auto pt-6">
              <GantrySilhouette />
              <div className="-mt-3 overflow-hidden rounded-2xl bg-[#170d2c]/90 ring-1 ring-white/[0.09] backdrop-blur">
                <div className="flex items-center justify-between border-b border-white/[0.08] px-4 py-2.5">
                  <span className="text-[13px] font-bold text-white">
                    Itarsi Section
                  </span>
                  <span className="text-[12px] font-semibold text-[#ff8d7f]">
                    ⌁ 40m delays
                  </span>
                </div>
                <div className="space-y-3 px-4 py-3.5">
                  <div className="flex gap-2.5">
                    <span className="mt-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-crit/25 text-[11px] text-[#ff8d7f]">
                      !
                    </span>
                    <div>
                      <div className="text-[13px] font-semibold text-[#ff8d7f]">
                        Trains through Itarsi held
                      </div>
                      <div className="mt-0.5 text-[12px] leading-snug text-white/60">
                        Fog speed restrictions for the next 40 min (not this
                        train currently). Probability of extension is 30–60%.
                      </div>
                    </div>
                  </div>
                  <div className="flex gap-2.5">
                    <CloudFog size={16} className="mt-0.5 text-white/50" />
                    <div>
                      <div className="text-[13px] font-semibold text-white">
                        Dense fog
                      </div>
                      <div className="mt-0.5 text-[12px] text-white/60">
                        Advisory from section control
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Reveal>
    </div>
  );
}

const BLOCKS: {
  id?: string;
  title: string;
  body: string;
  vignette: React.ReactNode;
}[] = [
  {
    title: "First to know. First to go.",
    body: "Hear about delays and platform changes before anyone else, even the announcer. Railly's alerts are instant, clear, and unfiltered, giving you the earliest heads-up to replan and skip the scrum on the footbridge.",
    vignette: (
      <>
        <NotifCard
          title="Platform changed at Kota"
          body="PF 1 → PF 3 · announced 38 min before arrival."
          time="4:12"
          accent="crit"
          tilt={-2}
        />
        <NotifCard
          title="Boarding now"
          body="Your coach C4 stops near the PF 3 stairs."
          time="4:48"
          accent="signal"
          tilt={2}
        />
      </>
    ),
  },
  {
    id: "after-arrival",
    title: "Putting the 'Pro' in approachable.",
    body: "Powerful, loco-grade data that you can actually understand. Platform, coach position, seat, PNR and exit gate — all at a glance. Never stop and stare at a departure board again.",
    vignette: <ProDataCard />,
  },
];

export function FeatureJourney() {
  return (
    <section id="features" className="mx-auto max-w-6xl px-4 py-24 md:py-32">
      <Reveal className="mx-auto max-w-3xl text-center">
        <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
          Everything you&apos;ve ever wanted to know about your train—and more.
        </h2>
        <p className="mt-5 text-[18px] leading-relaxed text-carbon">
          Railly keeps you informed by tracking more information about your train
          than any other app—like the #1 and #2 biggest causes of delays. Know
          exactly what&apos;s happening and how it affects your journey, so you can
          finally just enjoy the ride.
        </p>
        <div className="mt-7 inline-flex gap-2 rounded-full bg-black/[0.04] p-1.5">
          {[
            ["Before you board", "#before-you-board"],
            ["On the platform", "#on-the-platform"],
            ["After arrival", "#after-arrival"],
          ].map(([label, href]) => (
            <a
              key={href}
              href={href}
              className="rounded-full px-4 py-2 text-[14px] font-semibold text-black transition-colors hover:bg-white hover:shadow-pill"
            >
              {label}
            </a>
          ))}
        </div>
      </Reveal>

      <div className="mt-20 space-y-6">
        {/* flighty's dark-card cluster: the big intro card + the pair */}
        <DarkIntroCard />
        <DarkFeaturePair />
      </div>

      <div className="mt-24 space-y-24">
        {BLOCKS.map((block, i) => {
          const flip = i % 2 === 1;
          return (
            <div
              key={block.title}
              id={block.id}
              className="grid scroll-mt-28 items-center gap-10 overflow-x-clip md:grid-cols-2 md:gap-16"
            >
              <Reveal
                from={flip ? "right" : "left"}
                className={flip ? "md:order-2" : ""}
              >
                <h3 className="text-[28px] font-bold leading-tight tracking-tight text-black md:text-[32px]">
                  {block.title}
                </h3>
                <p className="mt-4 text-[17px] leading-relaxed text-carbon">
                  {block.body}
                </p>
              </Reveal>
              <Reveal
                from={flip ? "left" : "right"}
                delay={90}
                className={flip ? "md:order-1" : ""}
              >
                <Vignette>{block.vignette}</Vignette>
              </Reveal>
            </div>
          );
        })}
      </div>
    </section>
  );
}
