import type { Metadata } from "next";
import Link from "next/link";
import { AlarmClock, ArrowRight, ChevronDown, Snowflake, Sun } from "lucide-react";
import { APP_CTA_HREF } from "@/lib/cta";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { JsonLd } from "@/components/seo/JsonLd";

const TITLE =
  "Tatkal Booking Time — 10 AM AC & 11 AM Non-AC, Aadhaar Rules | Railly";
const DESCRIPTION =
  "When Tatkal booking opens on Indian Railways: 10 AM for AC classes, 11 AM for non-AC, one day before travel from the train's origin. Plus the Aadhaar-authentication rules for online Tatkal, and how to be ready at the opening bell.";

export const metadata: Metadata = {
  title: { absolute: TITLE },
  description: DESCRIPTION,
  alternates: { canonical: "/guides/tatkal-booking-time" },
  openGraph: {
    type: "article",
    siteName: "Railly",
    locale: "en_IN",
    url: "/guides/tatkal-booking-time",
    title: TITLE,
    description: DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: TITLE,
    description: DESCRIPTION,
  },
};

type FaqItem = { q: string; a: string };

const FAQS: FaqItem[] = [
  {
    q: "What time does Tatkal booking open?",
    a: "Tatkal opens one day before the journey date, counted from the train's origin station: 10 AM for AC classes and 11 AM for non-AC (Sleeper and Second Sitting). On busy routes the quota can be gone within minutes, so being logged in and ready at the opening bell matters more than anything else you can do.",
  },
  {
    q: "Is Tatkal 10 AM or 11 AM?",
    a: "Both, depending on class. AC Tatkal — First AC, 2A, 3A, Chair Car and Executive Chair Car — opens at 10 AM. Non-AC Tatkal — Sleeper and Second Sitting — opens at 11 AM. Both windows open exactly one day before the date of journey from the originating station, not from your boarding station.",
  },
  {
    q: "Do I need Aadhaar to book Tatkal online?",
    a: "As of the 2025 IRCTC rules, booking Tatkal on the IRCTC website or app requires an Aadhaar-authenticated account, and an Aadhaar-linked mobile OTP is verified at the time of booking. Authorised travel agents are also barred from booking Tatkal during the first 30 minutes of each window. Rules change, so confirm the current requirement on IRCTC before you rely on it. Railly doesn't book tickets — it reminds you and deep-links you to IRCTC.",
  },
  {
    q: "How does the 9:55 reminder work?",
    a: "If a journey you're watching is still waitlisted, Railly nudges you at 9:55 AM the day before travel — five minutes ahead of the AC Tatkal window — and again before the 11 AM non-AC window when that's the one you need. That's enough time to log in to IRCTC, load your saved passenger list, and be on the booking screen when the quota opens.",
  },
];

const FAQ_JSON_LD = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: FAQS.map((f) => ({
    "@type": "Question",
    name: f.q,
    acceptedAnswer: { "@type": "Answer", text: f.a },
  })),
};

function Faq({ q, a }: FaqItem) {
  return (
    <details className="group rounded-2xl bg-linen ring-1 ring-black/[0.05]">
      <summary className="flex cursor-pointer list-none items-center justify-between gap-4 px-6 py-5 marker:content-none [&::-webkit-details-marker]:hidden">
        <span className="text-[16px] font-semibold leading-snug text-black">
          {q}
        </span>
        <ChevronDown
          size={18}
          strokeWidth={2}
          className="shrink-0 text-steel transition-transform duration-300 group-open:rotate-180"
        />
      </summary>
      <div className="px-6 pb-6 text-[15px] leading-relaxed text-carbon">
        <p>{a}</p>
      </div>
    </details>
  );
}

export default function TatkalBookingTimeGuide() {
  return (
    <PageShell>
      <JsonLd data={FAQ_JSON_LD} />
      <PageHero
        eyebrow="GUIDE · TATKAL"
        title="Tatkal booking time, without the panic."
        dek="Two windows, one day before you travel — 10 AM for AC and 11 AM for non-AC, timed to your train's origin. Here's exactly when they open, the Aadhaar rules for online booking, and how to be on the screen when the quota does."
      />

      {/* Two windows */}
      <section className="mx-auto max-w-4xl px-4 pt-10">
        <div className="grid gap-4 md:grid-cols-2">
          <Reveal>
            <div className="flex h-full flex-col rounded-3xl bg-white p-8 shadow-float ring-1 ring-black/[0.05]">
              <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-signal/10">
                <Snowflake size={20} className="text-signal" strokeWidth={1.8} />
              </span>
              <div className="mt-4 text-[13px] font-bold uppercase tracking-[1px] text-steel">
                AC classes
              </div>
              <div className="mt-1 text-[40px] font-extrabold leading-none tracking-tight text-black">
                10:00 AM
              </div>
              <p className="mt-3 text-[15px] leading-relaxed text-carbon">
                First AC, 2A, 3A, Chair Car and Executive Chair Car. The window
                opens one day before the journey date, counted from the train&apos;s
                originating station.
              </p>
            </div>
          </Reveal>
          <Reveal delay={70}>
            <div className="flex h-full flex-col rounded-3xl bg-white p-8 shadow-float ring-1 ring-black/[0.05]">
              <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-sun/15">
                <Sun size={20} className="text-[#B58900]" strokeWidth={1.8} />
              </span>
              <div className="mt-4 text-[13px] font-bold uppercase tracking-[1px] text-steel">
                Non-AC classes
              </div>
              <div className="mt-1 text-[40px] font-extrabold leading-none tracking-tight text-black">
                11:00 AM
              </div>
              <p className="mt-3 text-[15px] leading-relaxed text-carbon">
                Sleeper and Second Sitting. Same rule — one day before the date
                of journey from the origin, so a boarding point down the line
                doesn&apos;t change the clock.
              </p>
            </div>
          </Reveal>
        </div>
        <Reveal delay={100}>
          <p className="mt-4 text-[13px] leading-relaxed text-fog">
            &ldquo;One day before&rdquo; is counted from the train&apos;s
            originating station, not your boarding station — a detail that trips
            up a lot of first-time Tatkal bookers.
          </p>
        </Reveal>
      </section>

      {/* Aadhaar rules */}
      <section className="mx-auto max-w-3xl px-4 py-20 md:py-24">
        <Reveal>
          <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
            The Aadhaar rules for online Tatkal
          </h2>
          <div className="mt-5 space-y-4 text-[16px] leading-relaxed text-carbon">
            <p>
              Since the 2025 IRCTC changes, online Tatkal has tightened around
              identity. Booking Tatkal on the IRCTC website or app requires an{" "}
              <b className="font-semibold text-black">
                Aadhaar-authenticated account
              </b>
              , and an Aadhaar-linked mobile{" "}
              <b className="font-semibold text-black">OTP</b> is verified at the
              moment of booking.
            </p>
            <p>
              Authorised travel agents are also barred from booking Tatkal during
              the first 30 minutes of each window — 10:00 to 10:30 for AC, 11:00
              to 11:30 for non-AC — to give individual travellers a clean run at
              the quota.
            </p>
            <p className="text-[14px] text-steel">
              These rules have changed more than once, so confirm the current
              requirement on IRCTC before you rely on it. Railly doesn&apos;t
              book tickets — it reminds you and deep-links you straight to IRCTC.
            </p>
          </div>
        </Reveal>
      </section>

      {/* Reading the grid */}
      <section className="bg-linen px-4 py-20 md:py-24">
        <Reveal className="mx-auto max-w-3xl">
          <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
            Reading the availability grid
          </h2>
          <p className="mt-4 text-[16px] leading-relaxed text-carbon">
            Each cell shows the railway&apos;s own status string for a date and
            class.{" "}
            <b className="font-semibold text-black">AVAILABLE-0042</b> means 42
            berths can be booked and confirmed right now.{" "}
            <b className="font-semibold text-black">RAC 12</b> means you&apos;d
            board with a shared berth, twelfth in the RAC queue.{" "}
            <b className="font-semibold text-black">GNWL21/WL9</b> means
            you&apos;d join the general waitlist — 21 people entered it before
            you, and 9 are still ahead today. Railly colours the grid so you can
            scan a whole week at a glance instead of parsing each string.
          </p>
        </Reveal>
      </section>

      {/* CTA */}
      <section className="mx-auto max-w-3xl px-4 py-20 md:py-24">
        <Reveal from="zoom">
          <div className="flex flex-col items-center gap-5 rounded-3xl bg-midnight p-8 text-center text-white md:p-12">
            <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/[0.08] ring-1 ring-white/[0.12]">
              <AlarmClock size={22} className="text-sun" />
            </span>
            <h2 className="text-[26px] font-bold tracking-tight md:text-[32px]">
              Get the 9:55 Tatkal reminder.
            </h2>
            <p className="mx-auto max-w-md text-[16px] leading-relaxed text-silver">
              Watch a waitlisted journey in Railly and we&apos;ll nudge you five
              minutes before the right window opens — so you&apos;re logged in,
              passengers loaded, and on the booking screen when the quota does.
            </p>
            <a
              href={APP_CTA_HREF}
              className="mt-1 rounded-full bg-sun px-7 py-3.5 text-[15px] font-semibold text-black transition-transform hover:scale-[1.03] active:scale-95"
            >
              Join the waitlist
            </a>
          </div>
        </Reveal>
      </section>

      {/* FAQ */}
      <section className="mx-auto max-w-3xl px-4 pb-16">
        <Reveal>
          <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
            Frequently asked
          </h2>
        </Reveal>
        <div className="mt-6 flex flex-col gap-3">
          {FAQS.map((f) => (
            <Reveal key={f.q}>
              <Faq q={f.q} a={f.a} />
            </Reveal>
          ))}
        </div>
        <Reveal delay={60}>
          <p className="mt-6 text-[14px] leading-relaxed text-steel">
            If your ticket is waitlisted, the{" "}
            <Link
              href="/guides/pnr-status-explained"
              className="font-semibold text-signal underline-offset-4 hover:underline"
            >
              PNR status guide
            </Link>{" "}
            explains what your code means, and the{" "}
            <Link
              href="/guides/live-train-running-status"
              className="inline-flex items-center gap-1 font-semibold text-signal underline-offset-4 hover:underline"
            >
              live tracking guide
              <ArrowRight size={13} strokeWidth={2.2} />
            </Link>{" "}
            covers running status.
          </p>
        </Reveal>
      </section>
    </PageShell>
  );
}
