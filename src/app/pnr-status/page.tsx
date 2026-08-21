import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight, Bell, ChevronDown, Clock, Ticket } from "lucide-react";
import { APP_CTA_HREF } from "@/lib/cta";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { JsonLd } from "@/components/seo/JsonLd";
import { PnrLookup } from "@/components/rail/PnrLookup";

const PNR_TITLE =
  "PNR Status Check — Live Indian Railways PNR Enquiry | Railly";
const PNR_DESCRIPTION =
  "Check your Indian Railways PNR status live: per-passenger current status, coach and berth, chart status and coach position. Plus every code decoded — CNF, RAC, WL, GNWL, PQWL, RLWL and TQWL — and when the chart actually prepares.";

export const metadata: Metadata = {
  title: { absolute: PNR_TITLE },
  description: PNR_DESCRIPTION,
  alternates: { canonical: "/pnr-status" },
  openGraph: {
    type: "website",
    siteName: "Railly",
    locale: "en_IN",
    url: "/pnr-status",
    title: PNR_TITLE,
    description: PNR_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: PNR_TITLE,
    description: PNR_DESCRIPTION,
  },
};

/* Status decoder — one accurate row per common Indian Railways code. */
const CODES: { code: string; full: string; means: string; clears: string }[] = [
  {
    code: "CNF",
    full: "Confirmed",
    means:
      "You have a berth of your own. The exact coach and berth are assigned when the chart prepares.",
    clears: "Done",
  },
  {
    code: "RAC",
    full: "Reservation Against Cancellation",
    means:
      "You can board, but you start on a shared side berth. You usually get a full berth as confirmed passengers cancel.",
    clears: "Often upgrades",
  },
  {
    code: "GNWL",
    full: "General Waiting List",
    means:
      "The standard waitlist, issued at or near the originating station. Your position falls as people ahead cancel.",
    clears: "Most likely to clear",
  },
  {
    code: "PQWL",
    full: "Pooled Quota Waiting List",
    means:
      "A waitlist shared across several intermediate stations on the route, drawing on one small pooled quota.",
    clears: "Clears more slowly",
  },
  {
    code: "RLWL",
    full: "Remote Location Waiting List",
    means:
      "A waitlist for an intermediate station with its own small quota. It clears on its own pattern, independent of the general list.",
    clears: "Unpredictable",
  },
  {
    code: "TQWL",
    full: "Tatkal Quota Waiting List",
    means:
      "The Tatkal waitlist. There is no separate quota of cancellations feeding it, so it clears far less often than GNWL.",
    clears: "Least likely to clear",
  },
];

type FaqItem = { q: string; a: string };

const FAQS: FaqItem[] = [
  {
    q: "What do CNF, RAC, GNWL, and TQWL actually mean?",
    a: "CNF means confirmed — you have a berth of your own. RAC (Reservation Against Cancellation) means you can board, but you start with a shared berth and usually get a full one as confirmed passengers cancel. GNWL is the general waitlist and the most likely kind to clear; TQWL is the Tatkal waitlist, which clears far less often because Tatkal bookings have no separate quota of cancellations feeding it. Railly shows the plain-English meaning next to every status, so you never have to decode the string yourself.",
  },
  {
    q: "When does the chart prepare?",
    a: "The reservation chart is drawn up about 8 hours before your train's departure from its origin station. For morning trains, that means the chart prepares around 9 PM the previous night — so a waitlisted ticket for a 7 AM departure is decided the evening before, not at dawn. A second chart is often prepared about 30 minutes before departure. Railly notifies you the moment your chart prepares, with your final status and, if you cleared, your coach and berth.",
  },
  {
    q: "How do I read a status like GNWL21/WL9?",
    a: "The first number is where you entered the waitlist and the second is your position today. GNWL21/WL9 means 21 people were on the general waitlist ahead of you when you booked, and 9 are still ahead now — so the list has already moved twelve places in your favour. RAC 12 means you'd board with a shared berth, twelfth in the RAC queue. Railly tracks these numbers over time so you can see the trend, not just today's figure.",
  },
  {
    q: "How does PNR import work?",
    a: "Add a trip with its 10-digit PNR and Railly resolves the whole journey — train, date, class, boarding and destination stations, and the current status of every passenger — and files it under My Trips. From then on Railly re-checks the PNR automatically, stepping up the frequency as chart time approaches, and pushes a notification whenever your status moves. No more refreshing an enquiry page every hour.",
  },
  {
    q: "Why did my PNR stop resolving?",
    a: "Indian Railways flushes PNR records from its live enquiry system a few days after the journey ends, or after a full cancellation. A flushed PNR returns nothing from any app or website — it's gone at the source, not just in Railly. Your trip itself isn't lost: everything Railly already fetched stays in your logbook on your device. Only fresh status lookups stop working.",
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

export default function PnrStatusPage() {
  return (
    <PageShell>
      <JsonLd data={FAQ_JSON_LD} />
      <PageHero
        eyebrow="PNR STATUS"
        title="Check your PNR. Then understand it."
        dek="Enter a 10-digit PNR for the live per-passenger status, coach and berth, and where your coach sits on the train. Below that, every status code decoded and when the chart actually prepares."
      />

      <section className="mx-auto max-w-4xl px-4 pt-8">
        <PnrLookup />
      </section>

      {/* Decoder table */}
      <section className="mx-auto max-w-4xl px-4 pt-10">
        <Reveal from="zoom">
          <div className="overflow-hidden rounded-3xl bg-white shadow-float ring-1 ring-black/[0.05]">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[640px] border-separate border-spacing-0 text-left">
                <thead>
                  <tr className="text-[11px] font-bold uppercase tracking-[1px] text-steel">
                    <th scope="col" className="px-5 py-4 md:px-6">
                      Code
                    </th>
                    <th scope="col" className="px-5 py-4">
                      Full form
                    </th>
                    <th scope="col" className="px-5 py-4">
                      What it means for you
                    </th>
                    <th scope="col" className="px-5 py-4">
                      Odds
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {CODES.map((c) => (
                    <tr key={c.code}>
                      <th
                        scope="row"
                        className="border-t border-black/[0.06] px-5 py-5 text-left align-top md:px-6"
                      >
                        <span className="tnum text-[15px] font-extrabold tracking-tight text-black">
                          {c.code}
                        </span>
                      </th>
                      <td className="border-t border-black/[0.06] px-5 py-5 align-top text-[14px] font-semibold text-carbon">
                        {c.full}
                      </td>
                      <td className="border-t border-black/[0.06] px-5 py-5 align-top text-[14px] leading-relaxed text-carbon">
                        {c.means}
                      </td>
                      <td className="border-t border-black/[0.06] px-5 py-5 align-top text-[13px] font-semibold text-steel">
                        {c.clears}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </Reveal>
        <Reveal delay={60}>
          <p className="mt-4 text-[13px] leading-relaxed text-fog">
            Likelihoods are relative and route-dependent, not guarantees. Railly
            shows the plain-English meaning beside every status inside the app,
            so you never decode a string by hand.
          </p>
        </Reveal>
      </section>

      {/* Chart timing */}
      <section className="mx-auto max-w-3xl px-4 py-20 md:py-24">
        <Reveal>
          <div className="flex items-center gap-3.5">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-linen ring-1 ring-black/[0.05]">
              <Clock size={20} className="text-carbon" strokeWidth={1.8} />
            </span>
            <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
              When the chart prepares
            </h2>
          </div>
          <div className="mt-5 space-y-4 text-[16px] leading-relaxed text-carbon">
            <p>
              The reservation chart is drawn up about{" "}
              <b className="font-semibold text-black">
                8 hours before your train&apos;s departure
              </b>{" "}
              from its origin station. For morning trains, that means the chart
              prepares around 9 PM the previous night — so a waitlisted ticket
              for a 7 AM departure is decided the evening before, not at dawn.
            </p>
            <p>
              A second chart is often prepared about 30 minutes before
              departure, picking up last-minute cancellations. Until the first
              chart prepares, a waitlisted or RAC ticket can still move. Railly
              steps up how often it checks as chart time approaches, and pushes a
              notification the moment your status is finalised — with your coach
              and berth if you cleared.
            </p>
          </div>
        </Reveal>
      </section>

      {/* Flushing */}
      <section className="bg-linen px-4 py-20 md:py-24">
        <Reveal className="mx-auto max-w-3xl">
          <div className="flex items-center gap-3.5">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white ring-1 ring-black/[0.05]">
              <Ticket size={20} className="text-carbon" strokeWidth={1.8} />
            </span>
            <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
              Why a PNR stops resolving
            </h2>
          </div>
          <div className="mt-5 space-y-4 text-[16px] leading-relaxed text-carbon">
            <p>
              Indian Railways flushes PNR records from its live enquiry system a
              few days after the journey ends, or after a full cancellation. A
              flushed PNR returns nothing from any app or website — it&apos;s
              gone at the source, not just in Railly.
            </p>
            <p>
              Your trip itself isn&apos;t lost: everything Railly already fetched
              stays in your logbook on your device. Only fresh status lookups
              stop working once the record is flushed.
            </p>
          </div>
        </Reveal>
      </section>

      {/* CTA — alerts when the PNR moves */}
      <section className="mx-auto max-w-3xl px-4 py-20 md:py-24">
        <Reveal from="zoom">
          <div className="flex flex-col items-center gap-5 rounded-3xl bg-midnight p-8 text-center text-white md:p-12">
            <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/[0.08] ring-1 ring-white/[0.12]">
              <Bell size={22} className="text-sun" />
            </span>
            <h2 className="text-[26px] font-bold tracking-tight md:text-[32px]">
              Get alerts when your PNR moves.
            </h2>
            <p className="mx-auto max-w-md text-[16px] leading-relaxed text-silver">
              Add your 10-digit PNR to Railly and stop refreshing. We watch it
              around the clock, step up the checks as chart time nears, and
              notify you the instant your status changes.
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
            PNR status, answered
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
            Go deeper in the{" "}
            <Link
              href="/guides/pnr-status-explained"
              className="font-semibold text-signal underline-offset-4 hover:underline"
            >
              PNR status guide
            </Link>
            , the{" "}
            <Link
              href="/guides/tatkal-booking-time"
              className="font-semibold text-signal underline-offset-4 hover:underline"
            >
              Tatkal timing guide
            </Link>
            , or read how{" "}
            <Link
              href="/guides/live-train-running-status"
              className="font-semibold text-signal underline-offset-4 hover:underline"
            >
              live running status
            </Link>{" "}
            works.
            <span className="ml-1 inline-flex items-center gap-1">
              <ArrowRight size={13} strokeWidth={2.2} className="text-signal" />
            </span>
          </p>
        </Reveal>
      </section>
    </PageShell>
  );
}
