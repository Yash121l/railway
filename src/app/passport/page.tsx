import type { Metadata } from "next";
import { Clock3, History, Route } from "lucide-react";
import { APP_CTA_HREF, APP_CTA_LABEL } from "@/lib/cta";
import { CountUp } from "@/components/marketing/CountUp";
import { MiniPhone } from "@/components/marketing/MidSections";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { SCREENS } from "@/components/marketing/screens";
import { Starfield } from "@/components/marketing/Starfield";

const PASSPORT_DESCRIPTION =
  "The Railly Passport is your Indian Railways trip logbook: every kilometre, delay, platform, and coach, filed automatically while you ride — cut by year or all-time.";

export const metadata: Metadata = {
  title: "Passport",
  description: PASSPORT_DESCRIPTION,
  alternates: { canonical: "/passport" },
  openGraph: {
    type: "website",
    siteName: "Railly",
    locale: "en_IN",
    url: "/passport",
    title: "Railly Passport — Your rail trip logbook",
    description: PASSPORT_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: "Railly Passport — Your rail trip logbook",
    description: PASSPORT_DESCRIPTION,
  },
};

/** The violet all-time card — the PassportTeaser recipe, at full richness. */
function PassportCard() {
  return (
    <div className="glow-violet relative overflow-hidden rounded-3xl p-7 ring-1 ring-black/10">
      <Starfield className="opacity-70" />
      <div className="relative">
        <div className="flex items-center justify-between">
          <div className="text-[11px] font-bold uppercase tracking-[2px] text-sun">
            Railly Passport
          </div>
          <span className="rounded-full px-2.5 py-1 text-[10px] font-bold uppercase tracking-[1.5px] text-white/60 ring-1 ring-white/15">
            All-time
          </span>
        </div>

        {/* headline stat — distance, with the around-the-world meter */}
        <div className="mt-6">
          <div className="tnum text-[40px] font-extrabold leading-none tracking-tight text-white">
            <CountUp value={16418} /> km
          </div>
          <div className="mt-2 text-[11px] font-bold uppercase tracking-[1px] text-white/50">
            Distance · 0.41x around the world
          </div>
          <div className="mt-2 h-1 w-full overflow-hidden rounded-full bg-white/10">
            <div className="h-full w-[41%] rounded-full bg-sun" />
          </div>
        </div>

        <div className="mt-6 grid grid-cols-2 gap-5">
          <div>
            <div className="tnum text-[28px] font-extrabold tracking-tight text-white">
              <CountUp value={12} />
            </div>
            <div className="mt-1 text-[11px] font-bold uppercase tracking-[1px] text-white/50">
              Trips · 8 overnight
            </div>
          </div>
          <div>
            <div className="tnum text-[28px] font-extrabold tracking-tight text-white">
              <CountUp value={231} suffix="h" />
            </div>
            <div className="mt-1 text-[11px] font-bold uppercase tracking-[1px] text-white/50">
              Rail time
            </div>
          </div>
        </div>

        <div className="mt-5 grid grid-cols-3 gap-5">
          <div>
            <div className="tnum text-[24px] font-extrabold tracking-tight text-white">
              <CountUp value={14} />
            </div>
            <div className="mt-1 text-[11px] font-bold uppercase tracking-[1px] text-white/50">
              Stations
            </div>
          </div>
          <div>
            <div className="tnum text-[24px] font-extrabold tracking-tight text-white">
              <CountUp value={12} />
            </div>
            <div className="mt-1 text-[11px] font-bold uppercase tracking-[1px] text-white/50">
              Trains
            </div>
          </div>
          <div>
            <div className="tnum text-[24px] font-extrabold tracking-tight text-white">
              +2h 05m
            </div>
            <div className="mt-1 text-[11px] font-bold uppercase tracking-[1px] text-white/50">
              Worst delay
            </div>
          </div>
        </div>

        {/* machine-readable zone — because it's a passport */}
        <div className="mt-6 overflow-hidden whitespace-nowrap border-t border-white/15 pt-4 font-mono text-[11px] tracking-[1.5px] text-white/60 md:text-[13px]">
          {"ALLTIME<<YASH<L<<MEMBER<<RAILLY<<<<<<"}
        </div>
      </div>
    </div>
  );
}

const LOGGED = [
  [
    Route,
    "Every kilometre, on the real line.",
    "Distance is measured along actual route geometry — the loop through the ghats, the long curve into the junction — not straight lines between dots on a map.",
  ],
  [
    Clock3,
    "Every delay, platform, and coach.",
    "The +2h 05m you sat through, the platform you arrived on, the coach you rode in — filed the moment they happen, while you're busy looking out the window.",
  ],
  [
    History,
    "Yearly cuts and the all-time book.",
    "Flip between this year and everything ever. Watch 2026 chase down your best year, or open the all-time page and settle who in the family really rides the most.",
  ],
] as const;

const SAMPLE_STATS: [React.ReactNode, string][] = [
  [<CountUp key="km" value={16418} suffix=" km" />, "logged along real track"],
  [<CountUp key="h" value={231} suffix="h" />, "of rail time banked"],
  [<CountUp key="st" value={14} />, "stations stamped in"],
  ["+2h 05m", "worst delay, on record"],
];

export default function PassportPage() {
  return (
    <PageShell>
      <PageHero
        eyebrow="PASSPORT"
        title="Every journey you've ever taken, on one page."
        dek="The Railly Passport is your rail logbook, one tap away behind your avatar. Distance in real track kilometres, trips, rail time and stations, with a Delay Report of the time you lost. You take the trips. It keeps the receipts."
      />

      {/* the Passport screen and the all-time card, side by side */}
      <section className="mx-auto max-w-6xl px-4 py-20 md:py-28">
        <div className="grid items-center gap-12 md:grid-cols-2">
          <Reveal from="left" className="flex justify-center">
            <MiniPhone
              src={SCREENS.passport}
              alt="Railly Passport: 16,418 km, 12 trips, 231h 2m of rail time and 14 stations, above the Delay Report. Demo data."
            />
          </Reveal>
          <Reveal delay={120} from="right">
            <PassportCard />
            <p className="mt-4 text-[13px] leading-relaxed text-steel">
              A sample passport, from the same demo trips as the screenshot.
              Yours starts at zero and fills in from the trips you track.
            </p>
          </Reveal>
        </div>
      </section>

      {/* what gets logged, without you lifting a finger */}
      <section className="bg-linen px-4 py-20 md:py-28">
        <div className="mx-auto max-w-6xl">
          <Reveal className="mx-auto max-w-3xl text-center">
            <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
              You ride. It writes.
            </h2>
            <p className="mt-5 text-[18px] leading-relaxed text-carbon">
              No forms, no manual entries, no &ldquo;add trip to diary.&rdquo;
              Track a journey once and the Passport does the bookkeeping.
            </p>
          </Reveal>
          <div className="mt-12 grid gap-4 md:grid-cols-3">
            {LOGGED.map(([Icon, title, body], i) => (
              <Reveal key={title} delay={i * 80}>
                <div className="card-lift flex h-full flex-col gap-3 rounded-3xl bg-white p-8 ring-1 ring-black/[0.05]">
                  <span className="flex h-11 w-11 items-center justify-center rounded-full bg-signal/10">
                    <Icon size={20} className="text-signal" strokeWidth={1.8} />
                  </span>
                  <h3 className="text-[18px] font-bold tracking-tight text-black">
                    {title}
                  </h3>
                  <p className="text-[15px] leading-relaxed text-carbon">
                    {body}
                  </p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* the brag sheet — clearly labelled as a sample */}
      <section className="mx-auto max-w-6xl px-4 py-20 md:py-28">
        <Reveal className="mx-auto max-w-3xl text-center">
          <div className="text-[12px] font-bold uppercase tracking-[2px] text-signal">
            Sample passport
          </div>
          <h2 className="mt-4 text-headline text-black md:text-[44px] md:leading-[1.05]">
            Numbers you&apos;ll actually brag about.
          </h2>
          <p className="mt-5 text-[18px] leading-relaxed text-carbon">
            Here&apos;s the kind of ledger a year of riding builds. These are
            example figures from a sample passport — the point is what Railly
            computes for you, not what anyone else logged.
          </p>
        </Reveal>
        <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {SAMPLE_STATS.map(([value, label], i) => (
            <Reveal key={label} delay={i * 70} from="zoom">
              <div className="card-lift h-full rounded-3xl bg-linen p-8 ring-1 ring-black/[0.05]">
                <div className="tnum text-[38px] font-extrabold leading-none tracking-tight text-black">
                  {value}
                </div>
                <div className="mt-3 text-[13px] font-semibold uppercase tracking-[1px] text-steel">
                  {label}
                </div>
              </div>
            </Reveal>
          ))}
        </div>
        <Reveal delay={120}>
          <div className="mt-12 text-center">
            <a
              href={APP_CTA_HREF}
              className="rounded-full bg-sun px-7 py-3.5 text-[15px] font-semibold text-black transition-transform hover:scale-[1.03] active:scale-95"
            >
              {APP_CTA_LABEL}
            </a>
            <p className="mt-4 text-[13px] text-steel">
              Page one is blank until your first tracked trip. That&apos;s the
              fun part.
            </p>
          </div>
        </Reveal>
      </section>
    </PageShell>
  );
}
