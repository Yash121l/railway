import { CloudFog, TrainFront, Zap } from "lucide-react";
import { NotifCard } from "./NotifCard";
import { Reveal } from "./Reveal";

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

function PredictionCard() {
  return (
    <div
      className="w-full max-w-[300px] rounded-[20px] border-l-[3px] border-l-sun bg-white p-4 shadow-float"
      style={{ rotate: "2deg" }}
    >
      <div className="flex items-center gap-2 text-[15px] font-semibold text-black">
        <Zap size={15} className="text-sun" />
        Delay expected · +40m
      </div>
      <p className="mt-1.5 text-[13px] text-steel">
        Predicted <b className="text-black">5h 12m</b> before the railway announced
        it. Machine learning on the inbound rake, not rumours.
      </p>
    </div>
  );
}

function AdvisoryCard() {
  return (
    <div
      className="w-full max-w-[310px] rounded-[20px] border-l-[3px] border-l-crit bg-white p-4 shadow-float"
      style={{ rotate: "-1.5deg" }}
    >
      <div className="text-[11px] font-bold uppercase tracking-[1px] text-crit">
        Advisory from section control
      </div>
      <div className="mt-1.5 flex items-center gap-2 text-[15px] font-semibold text-black">
        <CloudFog size={16} className="text-steel" />
        Trains through Itarsi held
      </div>
      <p className="mt-1 text-[13px] leading-snug text-steel">
        Fog speed restrictions for the next 40 min (not this train currently).
        Probability of extension is 30–60%.
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

const BLOCKS = [
  {
    id: "before-you-board",
    title: "See why you're delayed. Finally!",
    body: "Railways often keep delay information under wraps until the last minute. Railly doesn't. We track your inbound rake 24 hours before departure, so we can predict a new time long before the announcement crackles over the PA.",
    vignette: (
      <>
        <InboundRakeCard />
        <NotifCard
          title="12951 · new departure 17:22"
          body="Was 17:00 · inbound rake running late from Ahmedabad."
          time="12:40"
          accent="sun"
          tilt={1.5}
        />
      </>
    ),
  },
  {
    title: "Delay predictions. Long before the railway admits it.",
    body: "Late rakes are the #1 cause of delays. Railly uses machine learning to predict them — up to 6 hours before the railway says anything.",
    vignette: (
      <>
        <PredictionCard />
        <NotifCard
          title="Prediction confirmed"
          body="Railway announced +38m. Railly told you 5 hours ago."
          time="17:03"
          accent="go"
          tilt={-2}
        />
      </>
    ),
  },
  {
    id: "on-the-platform",
    title: "Direct from the control room.",
    body: "Section control mandates are the #2 cause of delays, and nobody tells you about them. Railly reads the network like a controller — fog blocks, crossings, line works — and explains what it means for your train.",
    vignette: <AdvisoryCard />,
  },
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

      <div className="mt-20 space-y-24">
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
