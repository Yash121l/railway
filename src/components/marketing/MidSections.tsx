import Link from "next/link";
import { CalendarDays, Mail, Ticket } from "lucide-react";
import { NotifCard } from "./NotifCard";
import { Reveal } from "./Reveal";

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
              className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white shadow-float"
            >
              <Icon size={19} className="text-carbon" />
            </span>
          ))}
        </div>
        <Link
          href="/app"
          className="mt-8 inline-block rounded-full bg-signal px-7 py-3.5 text-[15px] font-semibold text-white transition-transform hover:scale-[1.03]"
        >
          Give Railly a try
        </Link>
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
      <Reveal delay={120}>
        <div className="mt-14 grid items-center gap-10 md:grid-cols-3">
          <div className="space-y-3">
            <h3 className="text-[20px] font-bold tracking-tight text-black">
              Never hear, &ldquo;send me your train info?&rdquo; ever again.
            </h3>
            <p className="text-[15px] leading-relaxed text-carbon">
              Choose who you share your journeys with. They pick the
              notifications they want — boarding, delays, arrival.
            </p>
          </div>
          <div className="flex flex-col items-center gap-4">
            <NotifCard
              title="12951 to New Delhi departs in 4h"
              body="Dad's Rajdhani is on time so far."
              time="13:00"
              tilt={-2}
              drift
            />
            <NotifCard
              title="Dad left Mumbai Central"
              body="Arrives tomorrow 09:32 — 5m early."
              time="17:05"
              accent="go"
              tilt={2}
              drift
            />
          </div>
          <div className="space-y-3 md:text-right">
            <h3 className="text-[20px] font-bold tracking-tight text-black">
              Perfectly-timed notifications.
            </h3>
            <p className="text-[15px] leading-relaxed text-carbon">
              Know when to leave for the station, when they crossed the last
              junction, and exactly which exit gate to wait at.
            </p>
          </div>
        </div>
      </Reveal>
    </section>
  );
}

export function PassportTeaser() {
  const stats = [
    ["28,412", "kilometres"],
    ["47", "trips"],
    ["214h", "on rails"],
    ["+2h 05m", "worst delay"],
  ];
  return (
    <section id="passport" className="bg-linen px-4 py-24 md:py-32">
      <div className="mx-auto grid max-w-6xl items-center gap-12 md:grid-cols-2">
        <Reveal>
          <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
            Look back on your travels, near and far.
          </h2>
          <p className="mt-5 text-[18px] leading-relaxed text-carbon">
            Whether you ride once a year or once a day — how many times have you
            crossed the country? What was your worst delay? What&apos;s your
            most-ridden train? Your Railly Passport keeps the whole story.
          </p>
          <Link
            href="/app/logbook"
            className="mt-7 inline-block rounded-full bg-signal px-7 py-3.5 text-[15px] font-semibold text-white transition-transform hover:scale-[1.03]"
          >
            Open your Logbook
          </Link>
        </Reveal>
        <Reveal delay={120}>
          <div className="glow-violet rounded-3xl p-7 ring-1 ring-black/10">
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
        </Reveal>
      </div>
    </section>
  );
}

export function NetworkIntel() {
  return (
    <section className="bg-midnight px-4 py-24 text-white md:py-32">
      <Reveal className="mx-auto max-w-3xl text-center">
        <h2 className="text-headline md:text-[44px] md:leading-[1.05]">
          Know what&apos;s happening on any line. Right now.
        </h2>
        <p className="mt-5 text-[18px] leading-relaxed text-silver">
          Track the whole network with live runs, delays, and operational
          performance — all in real time. We synthesize thousands of control-room
          bulletins per minute: fog, line blocks, crew shortages, taxiway…
          sorry, <em>yard</em> congestion. Even rare anomalies like cattle on the
          track.
        </p>
      </Reveal>
      <Reveal delay={120}>
        <div className="mx-auto mt-12 max-w-3xl overflow-hidden rounded-3xl bg-ink ring-1 ring-white/[0.08]">
          <div className="flex items-center justify-between border-b border-white/[0.08] px-5 py-3.5">
            <span className="text-[13px] font-bold uppercase tracking-[1px] text-white/60">
              Network board · live
            </span>
            <span className="flex items-center gap-1.5 text-[12px] font-semibold text-go">
              <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-go" />
              8 trains watched
            </span>
          </div>
          {[
            ["12627", "Bengaluru → New Delhi", "DELAYED +20M", "text-sun bg-sun/15"],
            ["12841", "Kolkata → Chennai", "ON TIME", "text-go bg-go/15"],
            ["22436", "New Delhi → Varanasi", "ON TIME", "text-go bg-go/15"],
            ["12951", "Mumbai → New Delhi", "BOARDING", "text-[#4da3ff] bg-signal/15"],
          ].map(([no, route, status, cls]) => (
            <div
              key={no}
              className="flex items-center gap-3 border-b border-white/[0.06] px-5 py-3.5 last:border-0"
            >
              <span className="tnum text-[14px] font-bold">{no}</span>
              <span className="flex-1 truncate text-[14px] text-white/60">
                {route}
              </span>
              <span
                className={`rounded-full px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.5px] ${cls}`}
              >
                {status}
              </span>
            </div>
          ))}
        </div>
        <div className="mt-8 text-center">
          <Link
            href="/app/track"
            className="inline-block rounded-full bg-sun px-7 py-3.5 text-[15px] font-semibold text-black transition-transform hover:scale-[1.03]"
          >
            Go Live
          </Link>
        </div>
      </Reveal>
    </section>
  );
}

const MORE = [
  ["Family sharing.", "Share Railly with up to 5 family members at a time."],
  ["Privacy first.", "Your journeys and history are viewable only by you."],
  ["Live Activities.", "Your train on the Lock Screen, updating platform to platform."],
  ["24hr Where's-My-Rake.", "Track your inbound rake a full day before departure."],
  ["Weather radar.", "Fog, storms and heat waves along your exact route."],
  ["Calendar sync.", "Every journey lands in your calendar automatically."],
] as const;

export function MoreGrid() {
  return (
    <section className="mx-auto max-w-6xl px-4 py-24">
      <Reveal>
        <h3 className="text-center text-[28px] font-bold tracking-tight text-black md:text-[32px]">
          More reasons you&apos;ll want to take Railly on your next trip.
        </h3>
      </Reveal>
      <div className="mt-12 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {MORE.map(([title, body], i) => (
          <Reveal key={title} delay={i * 60}>
            <div className="h-full rounded-2xl bg-linen p-5 ring-1 ring-black/[0.05]">
              <span className="text-[15px] font-bold text-black">{title}</span>{" "}
              <span className="text-[15px] text-carbon">{body}</span>
            </div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
