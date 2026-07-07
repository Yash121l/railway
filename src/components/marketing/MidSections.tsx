import Image from "next/image";
import {
  BellRing,
  CalendarDays,
  CloudSun,
  History,
  Lock,
  Mail,
  Ticket,
  Users,
} from "lucide-react";
import { CountUp } from "./CountUp";
import { LiveActivityMock } from "./LiveActivityMock";
import { LiveBoard } from "./LiveBoard";
import { NetworkCanvas } from "./NetworkCanvas";
import { NotifCard } from "./NotifCard";
import { Reveal } from "./Reveal";
import { ScrollScrub } from "./ScrollStrip";
import { Starfield } from "./Starfield";

/** A slim device frame around a real app screenshot. */
export function MiniPhone({
  src,
  alt,
  className = "",
}: {
  src: string;
  alt: string;
  className?: string;
}) {
  return (
    <div
      className={`w-[228px] rounded-[36px] bg-[#0c0d10] p-[7px] shadow-deep ring-1 ring-black/60 md:w-[250px] ${className}`}
    >
      <div className="overflow-hidden rounded-[29px] bg-black">
        <Image src={src} alt={alt} width={430} height={932} className="block h-auto w-full" />
      </div>
    </div>
  );
}

export function ImportStrip() {
  return (
    <section className="bg-linen px-4 py-24">
      <Reveal className="mx-auto max-w-2xl text-center">
        <h3 className="text-[28px] font-bold tracking-tight text-black md:text-[32px]">
          Add your trips in seconds.
        </h3>
        <p className="mt-4 text-[17px] leading-relaxed text-carbon">
          You can magically (read: extremely quickly) make your journeys appear on
          Railly from your PNR, calendar, or email. Get up &amp; running faster
          than you can say, &ldquo;have a nice journey&rdquo;.
        </p>
        <div className="mt-6 flex items-center justify-center gap-3">
          {[Ticket, CalendarDays, Mail].map((Icon, i) => (
            <span
              key={i}
              className="card-lift flex h-11 w-11 items-center justify-center rounded-2xl bg-white shadow-float"
            >
              <Icon size={19} className="text-carbon" />
            </span>
          ))}
        </div>
        <a
          href="#pricing"
          className="mt-8 inline-block rounded-full bg-signal px-7 py-3.5 text-[15px] font-semibold text-white transition-transform hover:scale-[1.03] active:scale-95"
        >
          Give Railly a try
        </a>
      </Reveal>
    </section>
  );
}

export function Friends() {
  return (
    <section id="friends" className="mx-auto max-w-6xl scroll-mt-24 px-4 py-24 md:py-32">
      <Reveal className="mx-auto max-w-3xl text-center">
        <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
          Share your journeys with friends and family.
        </h2>
        <p className="mt-5 text-[18px] leading-relaxed text-carbon">
          Railly Friends lets you instantly share your travels with your loved
          ones. Add them just once, and you&apos;ll never have to manually forward
          a PNR again.
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
              <h3 className="max-w-[300px] text-[26px] font-bold leading-tight tracking-tight text-black md:text-[30px]">
                Never hear, &ldquo;send me your train info?&rdquo; ever again.
              </h3>
              <p className="mt-6 max-w-[320px] text-[15px] leading-relaxed text-carbon md:mt-0">
                Choose who you want to share your journeys with. They can then
                customize the notifications they get about your trip — boarding,
                delays, arrival, and more.
              </p>
            </div>
            <div className="relative h-[360px] md:h-auto">
              <div
                data-scrub-row
                className="absolute left-1/2 top-8 -translate-x-[96%] rotate-[-7deg] will-change-transform"
              >
                <MiniPhone
                  src="/screens/my-trips.png"
                  alt="Railly My Trips screen with the live network map"
                />
              </div>
              <div
                data-scrub-row
                className="absolute left-1/2 top-20 translate-x-[2%] rotate-[6deg] will-change-transform"
              >
                <MiniPhone
                  src="/screens/trip-detail.png"
                  alt="Railly trip detail screen with the live route map"
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
            <h3 className="max-w-[340px] text-[19px] font-bold leading-snug tracking-tight text-ontime">
              Get perfectly-timed notifications about your loved ones&apos;
              journeys.
            </h3>
            <div className="mt-8 flex flex-1 flex-col items-center justify-center gap-4">
              <NotifCard
                title="Dad is on rails today"
                body="12951 to New Delhi departs in 4h — on time so far."
                time="13:00"
                emoji="👨🏻‍🦳"
                tilt={-2}
                drift
              />
              <NotifCard
                title="Dad left Mumbai Central"
                body="Arrives tomorrow 09:32 — 5m early."
                time="17:05"
                accent="go"
                emoji="👨🏻‍🦳"
                tilt={2}
                drift
              />
            </div>
          </div>
        </Reveal>
        <Reveal delay={120}>
          <div className="flex h-full flex-col rounded-3xl bg-linen p-8 ring-1 ring-black/[0.05] md:p-10">
            <h3 className="max-w-[340px] text-[19px] font-bold leading-snug tracking-tight text-ontime">
              Know when to leave for the station — to the minute.
            </h3>
            <div className="mt-8 flex flex-1 flex-col items-center justify-center gap-4">
              <NotifCard
                title="Leave by 15:40 for MMCT"
                body="22 min to the station in current traffic. PF 2, near the stairs."
                time="15:12"
                accent="signal"
                mark="C4"
                markColor="#111318"
                tilt={2}
                drift
              />
              <NotifCard
                title="Crossed the last junction"
                body="Dad reaches in 18 min. Exit Gate 1 for pickup."
                time="09:14"
                accent="go"
                emoji="🚗"
                tilt={-2}
                drift
              />
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

export function PassportTeaser() {
  const stats: [React.ReactNode, string][] = [
    [<CountUp key="km" value={28412} />, "kilometres"],
    [<CountUp key="trips" value={47} />, "trips"],
    [<CountUp key="hours" value={214} suffix="h" />, "on rails"],
    ["+2h 05m", "worst delay"],
  ];
  return (
    <section id="passport" className="bg-linen px-4 py-24 md:py-32">
      <div className="mx-auto grid max-w-6xl items-center gap-12 md:grid-cols-2">
        <Reveal from="left">
          <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
            Look back on your travels, near and far.
          </h2>
          <p className="mt-5 text-[18px] leading-relaxed text-carbon">
            Whether you ride once a year or once a day — how many times have you
            crossed the country? What was your worst delay? What&apos;s your
            most-ridden train? Your Railly Passport keeps the whole story.
          </p>
          <a
            href="#pricing"
            className="mt-7 inline-block rounded-full bg-signal px-7 py-3.5 text-[15px] font-semibold text-white transition-transform hover:scale-[1.03] active:scale-95"
          >
            Get your Passport
          </a>
        </Reveal>
        <Reveal delay={120} from="right">
          <div className="glow-violet relative overflow-hidden rounded-3xl p-7 ring-1 ring-black/10">
            <Starfield className="opacity-70" />
            <div className="relative">
              <div className="text-[11px] font-bold uppercase tracking-[2px] text-sun">
                Railly Passport
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
                A hall of fame for your riding history.
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
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
          <h2 className="text-headline md:text-[44px] md:leading-[1.05]">
            Know what&apos;s happening on any line. Right now.
          </h2>
          <p className="mt-5 text-[18px] leading-relaxed text-silver">
            Track the whole network with live runs, delays, and operational
            performance — all in real time. We synthesize thousands of
            control-room bulletins per minute: fog, line blocks, crew shortages,
            taxiway… sorry, <em>yard</em> congestion. Even rare anomalies like
            cattle on the track.
          </p>
        </Reveal>
        <Reveal delay={100} from="zoom">
          {/* the actual simulation, live on canvas — every dot is a train
              the app is tracking at this exact second */}
          <div className="mx-auto mt-12 max-w-4xl overflow-hidden rounded-3xl bg-ink/80 ring-1 ring-white/[0.08]">
            <div className="flex items-center justify-between px-5 pt-4">
              <span className="text-[13px] font-bold uppercase tracking-[1px] text-white/60">
                The network · this second
              </span>
              <span className="flex items-center gap-1.5 text-[12px] font-semibold text-arc">
                <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-arc" />
                Live positions
              </span>
            </div>
            <NetworkCanvas className="h-[300px] w-full md:h-[380px]" />
          </div>
        </Reveal>
        <Reveal delay={140} from="zoom">
          <LiveBoard />
          <div className="mt-8 text-center">
            <a
              href="#pricing"
              className="inline-block rounded-full bg-sun px-7 py-3.5 text-[15px] font-semibold text-black transition-transform hover:scale-[1.03] active:scale-95"
            >
              Get Railly
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

const MORE = [
  [Users, "Family sharing.", "Share Railly with up to 5 family members at a time."],
  [Lock, "Privacy first.", "Your journeys and history are viewable only by you."],
  [History, "24hr Where's-My-Rake.", "Track your inbound rake a full day before departure."],
  [CloudSun, "Weather radar.", "Fog, storms and heat waves along your exact route."],
  [CalendarDays, "Calendar sync.", "Every journey lands in your calendar automatically."],
  [BellRing, "Fastest alerts.", "Push arrives before the announcer clears her throat."],
] as const;

export function MoreGrid() {
  return (
    <section className="mx-auto max-w-6xl px-4 py-24">
      <Reveal>
        <h3 className="text-center text-[28px] font-bold tracking-tight text-black md:text-[32px]">
          More reasons you&apos;ll want to take Railly on your next trip.
        </h3>
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
