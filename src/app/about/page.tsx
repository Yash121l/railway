import type { Metadata } from "next";
import { Ban, Building2, Compass, Lock, Radio } from "lucide-react";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";

export const metadata: Metadata = {
  title: "About",
  description:
    "Why trains deserve Flighty-grade software — the story behind Railly, our honesty manifesto, and why we stay independent of Indian Railways and IRCTC.",
};

const FACTS: [string, string][] = [
  ["4,022", "trains in the offline catalog"],
  ["9,109", "stations, coast to coast"],
  ["100%", "of your history stays on your device"],
];

/** The manifesto — the /compare voice, turned into first principles. */
const MANIFESTO: [typeof Radio, string, string][] = [
  [
    Radio,
    "We label every number.",
    "Live is live; an estimate says so. When a figure is a projection built from a train's schedule and how the section is running, we tell you — and we never dress a guess up as the railway's word. If we don't know, we say we don't know.",
  ],
  [
    Ban,
    "No ads, and no dark patterns.",
    "Nothing sits between you and your train. We killed the pay-by-the-week pricing that pressures you at exactly the wrong moment. Free stays genuinely free, the subscription is honest, and cancelling is one tap in the App Store.",
  ],
  [
    Compass,
    "We do less, obsessively.",
    "Railly is not a booking app, a marketplace, or a super-app. It tracks, predicts, and remembers your journey — and when it's time to buy, it deep-links you straight to IRCTC. Fewer things, done to a standard.",
  ],
  [
    Lock,
    "Your journeys are yours.",
    "Your trips, logbook and travel stats live on your device, not our servers. Share a journey and only that journey goes out, only to the people you picked. Delete the app and the data goes with it.",
  ],
  [
    Building2,
    "We recommend our rivals.",
    "NTES, Where Is My Train, RailYatri and ixigo got India moving, and we still keep them installed. We wrote an honest comparison that tells you where each one wins. The best train app for you might not be ours, and that's fine.",
  ],
];

export default function AboutPage() {
  return (
    <PageShell>
      <PageHero
        eyebrow="ABOUT"
        title="Why trains deserve Flighty-grade software."
        dek="Flying got a beautiful, calm, honest companion app. The train — which carries far more of India, every single day — got enquiry pages and banner ads. We thought the most important journeys deserved the most careful software. So we built it."
      />

      {/* founder story */}
      <section className="mx-auto max-w-3xl px-4 py-16 md:py-20">
        <Reveal className="space-y-6 text-[17px] leading-relaxed text-carbon">
          <p>
            Railly started on a delayed platform at Kanpur, refreshing an
            enquiry page that hadn&apos;t updated in forty minutes, wondering why
            the app on the phone knew less than the announcer we couldn&apos;t
            hear. We were people who track flights on Flighty and rebook before
            the gate agent finishes the sentence — and then we&apos;d get on a
            train and travel blind.
          </p>
          <p>
            That gap never made sense. Indian Railways moves a country: Vande
            Bharat corridors, overnight Rajdhanis, the Shatabdi that a whole city
            plans its morning around. Families wait up for a train they
            can&apos;t see. NRIs follow a parent&apos;s journey home from eight
            time zones away. The data to make all of that calm mostly exists — it
            was just trapped behind slow pages and buried under ads.
          </p>
          <p>
            So we built the companion we wanted: native, quiet, obsessively
            polished, and honest about what it knows. Live running status and
            delay estimates projected from the timetable. PNR watched
            around the clock. Coach position so you stand where your door will
            stop. And a Passport that quietly remembers every kilometre you ride.
            Not a booking engine — the thing that rides <em>with</em> you.
          </p>
        </Reveal>

        <Reveal delay={80}>
          <div className="mt-14 grid grid-cols-3 gap-4">
            {FACTS.map(([value, label]) => (
              <div
                key={label}
                className="rounded-3xl bg-linen p-6 text-center ring-1 ring-black/[0.05]"
              >
                <div className="tnum text-[30px] font-extrabold tracking-tight text-black md:text-[36px]">
                  {value}
                </div>
                <div className="mt-2 text-[12px] font-semibold leading-snug text-steel md:text-[13px]">
                  {label}
                </div>
              </div>
            ))}
          </div>
        </Reveal>
      </section>

      {/* honesty manifesto */}
      <section className="bg-linen px-4 py-20 md:py-28">
        <div className="mx-auto max-w-3xl">
          <Reveal className="text-center">
            <div className="text-[12px] font-bold uppercase tracking-[2px] text-signal">
              The honesty manifesto
            </div>
            <h2 className="mt-4 text-headline text-black md:text-[44px] md:leading-[1.05]">
              What we promise the platform.
            </h2>
            <p className="mx-auto mt-4 max-w-xl text-[17px] leading-relaxed text-carbon">
              A train app earns trust one honest number at a time. These are the
              rules we hold ourselves to, whether or not anyone&apos;s checking.
            </p>
          </Reveal>

          <div className="mt-14 flex flex-col gap-4">
            {MANIFESTO.map(([Icon, title, body], i) => (
              <Reveal key={title} delay={i * 60}>
                <div className="flex gap-5 rounded-3xl bg-white p-7 ring-1 ring-black/[0.05] md:p-8">
                  <div className="flex flex-col items-center gap-3">
                    <span className="tnum text-[13px] font-bold tracking-[1px] text-fog">
                      {String(i + 1).padStart(2, "0")}
                    </span>
                    <span className="flex h-11 w-11 items-center justify-center rounded-full bg-signal/10">
                      <Icon size={20} className="text-signal" strokeWidth={1.8} />
                    </span>
                  </div>
                  <div>
                    <h3 className="text-[19px] font-bold tracking-tight text-black">
                      {title}
                    </h3>
                    <p className="mt-2 text-[15px] leading-relaxed text-carbon">
                      {body}
                    </p>
                  </div>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* independence */}
      <section className="mx-auto max-w-3xl px-4 py-20 md:py-28">
        <Reveal from="zoom">
          <div className="rounded-3xl bg-midnight p-8 text-center text-white md:p-12">
            <div className="text-[12px] font-bold uppercase tracking-[2px] text-sun">
              Independent
            </div>
            <h2 className="mx-auto mt-4 max-w-xl text-[26px] font-bold leading-tight tracking-tight md:text-[32px]">
              Railly is not affiliated with Indian Railways or IRCTC.
            </h2>
            <p className="mx-auto mt-5 max-w-xl text-[16px] leading-relaxed text-white/75">
              We&apos;re an independent app made by a small team who ride these
              trains. Schedules, routes and station data come from Indian
              Railways, accessed through public sources; PNR status is resolved
              through live public feeds. We don&apos;t sell tickets and we take
              no cut of your fare — when you&apos;re ready to book, we hand you
              to IRCTC and get out of the way. No ads, no data brokering, no
              agenda beyond a calmer journey.
            </p>
          </div>
        </Reveal>
      </section>
    </PageShell>
  );
}
