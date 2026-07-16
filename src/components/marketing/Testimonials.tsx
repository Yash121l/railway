import Image from "next/image";
import { Star, TrainFront } from "lucide-react";
import { Reveal } from "./Reveal";

type Tweet = { kind: "tweet"; name: string; body: string };
type Review = { kind: "review"; title: string; body: string };
type Story = { kind: "story" };

/* Illustrative usage scenarios — not real reviews. See the caption above. */
const CARDS: (Tweet | Review | Story)[] = [
  {
    kind: "tweet",
    name: "The everyday commuter",
    body: "Ever since the old tracker apps died on me, I've searched for the ultimate train-tracking app. Now I've found it: Railly. Beautiful, clear, useful info (even tracks the INBOUND rake for your train). Often flags delays before the railway does.",
  },
  {
    kind: "review",
    title: "Favourite app on my phone",
    body: "It's like the old motto: it just works. Boarded 30+ trains with it this year. Literal perfection. No notes.",
  },
  {
    kind: "tweet",
    name: "The million-miler",
    body: "The kind of train-tracking app I've wanted for 15 years and 650k km of business travel. Railly flags a platform change before the announcer knows of it.",
  },
  {
    kind: "review",
    title: "Saved me HOURS of time",
    body: "Rescheduled my cab twice off Railly's prediction while everyone else stood staring at the board. It was right both times.",
  },
  { kind: "story" },
  {
    kind: "tweet",
    name: "The family trip-watcher",
    body: "Railly saved Diwali! Mom's train got rescheduled and the 'bong bong bong' alerted me before the SMS from the railway did. Picked her up without a minute in the parking lot.",
  },
  {
    kind: "review",
    title: "Clearly built with care",
    body: "The green time means my train was on time or early! Tiny detail, but it's how the whole app feels. Sleek and genuinely useful.",
  },
  {
    kind: "tweet",
    name: "The first-timer",
    body: "First-time train traveller with my toddler and Railly told me the platform, where coach C4 stops, and the exit gate at the other end. Zero stress.",
  },
  {
    kind: "review",
    title: "The Flighty of trains",
    body: "Everything I loved about tracking flights, for the 12951. The live map with the little glowing train is art.",
  },
  {
    kind: "tweet",
    name: "The Vande Bharat regular",
    body: "Railly explained WHY we were held outside Ratlam before the TTE knew. I showed him the app. He wanted it too.",
  },
];

function Stars() {
  return (
    <div className="flex gap-0.5 text-sun">
      {[...Array(5)].map((_, i) => (
        <Star key={i} size={13} fill="currentColor" strokeWidth={0} />
      ))}
    </div>
  );
}

export function Testimonials() {
  return (
    <section id="reviews" className="bg-linen px-4 py-24 md:py-32">
      <Reveal className="mx-auto max-w-3xl text-center">
        <h2 className="text-[28px] font-bold tracking-tight text-black md:text-[36px]">
          From first-time riders to million-milers.
        </h2>
        <p className="mx-auto mt-4 inline-flex items-center gap-1.5 rounded-full bg-black/[0.05] px-3 py-1 text-[12px] font-semibold text-steel">
          Illustrative — Railly is in early access
        </p>
      </Reveal>
      <div className="mx-auto mt-12 max-w-6xl columns-1 gap-4 md:columns-3">
        {CARDS.map((card, i) => (
          <Reveal key={i} delay={(i % 3) * 80} className="mb-4 break-inside-avoid">
            {card.kind === "story" ? (
              /* the share-to-Stories cell flighty drops into its wall */
              <div className="card-lift relative overflow-hidden rounded-2xl shadow-float">
                <Image
                  src="/screens/logbook.png"
                  alt="Railly Passport logbook screen shared as a story"
                  width={430}
                  height={932}
                  className="block h-auto w-full"
                />
                <div className="absolute inset-x-0 top-0 bg-gradient-to-b from-black/55 to-transparent px-4 pb-8 pt-3">
                  <div className="flex items-center gap-2">
                    <span className="flex h-7 w-7 items-center justify-center rounded-full bg-white text-[11px] font-bold text-black">
                      Y
                    </span>
                    <span className="text-[12px] font-semibold text-white">
                      yash.onrails · Shared from Railly
                    </span>
                  </div>
                </div>
                <div className="led-board absolute left-1/2 top-16 -translate-x-1/2 whitespace-nowrap rounded px-3 py-1.5 text-[12px] font-bold">
                  👋 BYE MUMBAI · NEXT: DELHI
                </div>
              </div>
            ) : (
            <div className="card-lift rounded-2xl bg-white p-5 shadow-float">
              {card.kind === "tweet" ? (
                <>
                  <div className="flex items-center gap-2.5">
                    <span className="flex h-9 w-9 items-center justify-center rounded-full bg-midnight text-[13px] font-bold text-white">
                      {card.name.replace(/^The /, "")[0].toUpperCase()}
                    </span>
                    <div className="text-[14px] font-bold text-black">
                      {card.name}
                    </div>
                  </div>
                  <p className="mt-3 text-[14px] leading-relaxed text-carbon">
                    {card.body}
                  </p>
                </>
              ) : (
                <>
                  <Stars />
                  <div className="mt-2.5 text-[15px] font-bold text-black">
                    {card.title}
                  </div>
                  <p className="mt-1.5 text-[14px] leading-relaxed text-carbon">
                    {card.body}
                  </p>
                </>
              )}
            </div>
            )}
          </Reveal>
        ))}
      </div>
      {/* flighty.com floats a stat over the wall as you scroll */}
      <div className="pointer-events-none sticky bottom-6 z-30 mt-10 flex justify-center">
        <div className="pointer-events-auto flex items-center gap-2.5 rounded-full bg-[#111318]/95 py-2 pl-2.5 pr-5 shadow-[0_10px_36px_rgba(0,0,0,0.35)] backdrop-blur">
          <span className="flex h-7 w-7 items-center justify-center rounded-full bg-signal ring-2 ring-[#111318]">
            <TrainFront size={14} className="text-white" />
          </span>
          <span className="tnum text-[14px] font-semibold text-white">
            4,022 trains · 9,161 stations tracked
          </span>
        </div>
      </div>
    </section>
  );
}
