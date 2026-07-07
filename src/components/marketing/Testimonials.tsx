import { Star } from "lucide-react";
import { Reveal } from "./Reveal";

type Tweet = { kind: "tweet"; name: string; handle: string; body: string; date: string };
type Review = { kind: "review"; title: string; body: string; byline: string };

const CARDS: (Tweet | Review)[] = [
  {
    kind: "tweet",
    name: "Pooja Iyer",
    handle: "@poojaonrails",
    body: "Ever since the old tracker apps died on me, I've searched for the ultimate train-tracking app. Now I've found it: @Railly. Beautiful, clear, useful info (even tracks the INBOUND rake for your train). Often tells me about delays before the railway does!",
    date: "Mar 2026",
  },
  {
    kind: "review",
    title: "Favourite app on my phone",
    body: "It's like the old motto: it just works. Boarded 30+ trains with it this year. Literal perfection. No notes.",
    byline: "meetusatplatform4 · Apr 2026",
  },
  {
    kind: "tweet",
    name: "Arjun Kelkar",
    handle: "@ak_millionmiler",
    body: "The best train tracking app I have experienced in 15 years and 650k km of business travel. Railly alerts me before the platform announcer knows of a change.",
    date: "Jan 2026",
  },
  {
    kind: "review",
    title: "Saved me HOURS of time! 6 stars!",
    body: "Rescheduled my cab twice off Railly's prediction while everyone else stood staring at the board. It was right both times.",
    byline: "dailyMMCTcommuter · Jun 2026",
  },
  {
    kind: "tweet",
    name: "Rahul Menon",
    handle: "@rahul_onrails",
    body: "@Railly just saved Diwali! Mom's train got rescheduled and the 'bong bong bong' alerted me before the SMS from the railway did. Picked her up without a minute in the parking lot.",
    date: "Nov 2025",
  },
  {
    kind: "review",
    title: "Clearly built with care",
    body: "The green time means my train was on time or early! Tiny detail, but it's how the whole app feels. Sleek and genuinely useful.",
    byline: "windowseat32A · Feb 2026",
  },
  {
    kind: "tweet",
    name: "Sneha Deshpande",
    handle: "@sd_travels",
    body: "First-time train traveller with my toddler and Railly told me the platform, where coach C4 stops, and the exit gate at the other end. Zero stress.",
    date: "May 2026",
  },
  {
    kind: "review",
    title: "The Flighty of trains",
    body: "Everything I loved about tracking flights, for the 12951. The live map with the little glowing train is art.",
    byline: "vandebharatfan · Jun 2026",
  },
  {
    kind: "tweet",
    name: "Kabir Shah",
    handle: "@kabirsh",
    body: "Railly explained WHY we were held outside Ratlam before the TTE knew. I showed him the app. He downloaded it.",
    date: "Apr 2026",
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
        <h3 className="text-[28px] font-bold tracking-tight text-black md:text-[36px]">
          From first-time riders to million-milers, people love Railly.
        </h3>
      </Reveal>
      <div className="mx-auto mt-12 max-w-6xl columns-1 gap-4 md:columns-3">
        {CARDS.map((card, i) => (
          <Reveal key={i} delay={(i % 3) * 80} className="mb-4 break-inside-avoid">
            <div className="rounded-2xl bg-white p-5 shadow-float">
              {card.kind === "tweet" ? (
                <>
                  <div className="flex items-center gap-2.5">
                    <span className="flex h-9 w-9 items-center justify-center rounded-full bg-midnight text-[13px] font-bold text-white">
                      {card.name[0]}
                    </span>
                    <div>
                      <div className="text-[14px] font-bold text-black">
                        {card.name}
                      </div>
                      <div className="text-[12px] text-steel">{card.handle}</div>
                    </div>
                  </div>
                  <p className="mt-3 text-[14px] leading-relaxed text-carbon">
                    {card.body}
                  </p>
                  <div className="mt-3 text-[12px] text-fog">{card.date}</div>
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
                  <div className="mt-3 text-[12px] text-fog">{card.byline}</div>
                </>
              )}
            </div>
          </Reveal>
        ))}
      </div>
      <p className="mt-10 text-center text-[15px] font-semibold text-carbon">
        +3 million riders enjoy Railly
      </p>
    </section>
  );
}
