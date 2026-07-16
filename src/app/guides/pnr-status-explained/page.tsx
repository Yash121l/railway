import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight, Bell, ChevronDown } from "lucide-react";
import { APP_CTA_HREF } from "@/lib/cta";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { JsonLd } from "@/components/seo/JsonLd";

const TITLE =
  "PNR Status Explained — What Every Status Means and When It Clears | Railly";
const DESCRIPTION =
  "A plain-English guide to Indian Railways PNR status: confirmed (CNF), RAC, and the waitlist family — GNWL, PQWL, RLWL and TQWL — how each behaves, when the chart prepares, and what happens to a waitlisted e-ticket.";

export const metadata: Metadata = {
  title: { absolute: TITLE },
  description: DESCRIPTION,
  alternates: { canonical: "/guides/pnr-status-explained" },
  openGraph: {
    type: "article",
    siteName: "Railly",
    locale: "en_IN",
    url: "/guides/pnr-status-explained",
    title: TITLE,
    description: DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: TITLE,
    description: DESCRIPTION,
  },
};

const LADDER: { code: string; title: string; body: string }[] = [
  {
    code: "CNF",
    title: "Confirmed — a berth of your own",
    body: "CNF means your seat is booked. Your exact coach and berth are assigned when the reservation chart prepares, so a CNF ticket without a berth number simply hasn't been charted yet — it isn't a problem.",
  },
  {
    code: "RAC",
    title: "Reservation Against Cancellation — board, then upgrade",
    body: "With RAC you can board the train, but you begin on a shared side berth — two RAC passengers to one berth. As confirmed passengers cancel, RAC positions convert to full berths, so a low RAC number is close to a guaranteed berth.",
  },
  {
    code: "GNWL",
    title: "General Waiting List — the one most likely to clear",
    body: "GNWL is issued at or near a train's originating station, where the bulk of the quota lives. It has the healthiest supply of cancellations feeding it, so of all the waitlists it's the most likely to confirm.",
  },
  {
    code: "PQWL",
    title: "Pooled Quota Waiting List — shared, so slower",
    body: "PQWL is shared across several intermediate stations that draw on one small pooled quota. Because that quota is thin and spread out, PQWL generally clears more slowly than GNWL.",
  },
  {
    code: "RLWL",
    title: "Remote Location Waiting List — its own rhythm",
    body: "RLWL belongs to an intermediate station with a small quota of its own. It clears independently of the general list and on its own pattern, which makes its movement the hardest to predict.",
  },
  {
    code: "TQWL",
    title: "Tatkal Quota Waiting List — the long shot",
    body: "TQWL is the Tatkal waitlist. There is no separate quota of cancellations feeding it the way GNWL is fed, so it clears far less often. A high TQWL rarely confirms — plan a backup.",
  },
];

type FaqItem = { q: string; a: string };

const FAQS: FaqItem[] = [
  {
    q: "What is the difference between RAC and a waitlisted ticket?",
    a: "RAC lets you board the train — you start on a shared side berth and usually get a full berth as confirmed passengers cancel. A waitlisted (WL) ticket does not yet have any berth. On IRCTC e-tickets, a ticket that is still fully waitlisted at chart preparation is automatically cancelled and refunded, and you cannot board on it; an RAC e-ticket stays valid to travel.",
  },
  {
    q: "Is GNWL or PQWL more likely to confirm?",
    a: "GNWL — the general waiting list — is generally the most likely to clear, because it sits at or near the originating station where the largest share of the quota and its cancellations live. PQWL is pooled across several intermediate stations drawing on one small quota, so it usually moves more slowly. RLWL and TQWL are less predictable still.",
  },
  {
    q: "When does the reservation chart prepare?",
    a: "About 8 hours before the train departs its origin station. For morning trains that means around 9 PM the night before, so a waitlisted ticket for a 7 AM departure is decided the previous evening. A second chart is often prepared roughly 30 minutes before departure to pick up last-minute cancellations.",
  },
  {
    q: "Does a fully waitlisted e-ticket get cancelled automatically?",
    a: "Yes. For IRCTC online e-tickets, any passenger still fully waitlisted when the chart prepares is dropped automatically and the fare refunded — you can't board on a WL e-ticket. This is different from a counter (PRS) ticket, where a waitlisted passenger may still travel. Railly watches your PNR up to chart time so you know the outcome the moment it's decided.",
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

export default function PnrStatusExplainedGuide() {
  return (
    <PageShell>
      <JsonLd data={FAQ_JSON_LD} />
      <PageHero
        eyebrow="GUIDE · PNR"
        title="PNR status, explained."
        dek="From confirmed to the bottom of the Tatkal waitlist — what each Indian Railways status really means, how likely it is to clear, and when the chart decides your fate."
      />

      {/* Intro */}
      <section className="mx-auto max-w-3xl px-4 pt-10">
        <Reveal>
          <p className="text-[17px] leading-relaxed text-carbon">
            A PNR — Passenger Name Record — is the ten-digit number that tracks
            your booking. Its status is a short code that tells you whether you
            have a berth, might get one, or are waiting. The codes look cryptic,
            but they follow a simple logic once you know what feeds each list.
            Here is the whole ladder, from best to longest odds.
          </p>
        </Reveal>
      </section>

      {/* The ladder */}
      <section className="mx-auto max-w-3xl px-4 py-16 md:py-20">
        <div className="flex flex-col gap-3">
          {LADDER.map((s, i) => (
            <Reveal key={s.code} delay={(i % 2) * 60}>
              <div className="flex gap-4 rounded-2xl bg-white p-6 ring-1 ring-black/[0.06]">
                <span className="tnum shrink-0 rounded-xl bg-linen px-3 py-1.5 text-[13px] font-extrabold tracking-tight text-black ring-1 ring-black/[0.05]">
                  {s.code}
                </span>
                <div>
                  <h2 className="text-[17px] font-bold text-black">
                    {s.title}
                  </h2>
                  <p className="mt-1.5 text-[15px] leading-relaxed text-carbon">
                    {s.body}
                  </p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* Chart timing + reading positions */}
      <section className="bg-linen px-4 py-20 md:py-24">
        <Reveal className="mx-auto max-w-3xl">
          <h2 className="text-[24px] font-bold tracking-tight text-black md:text-[30px]">
            When the chart decides
          </h2>
          <div className="mt-5 space-y-4 text-[16px] leading-relaxed text-carbon">
            <p>
              The reservation chart is drawn up about{" "}
              <b className="font-semibold text-black">
                8 hours before departure
              </b>{" "}
              from the origin station. For morning trains, that means around 9
              PM the previous night — a waitlisted ticket for a 7 AM departure is
              settled the evening before, not at dawn. A second chart is often
              prepared roughly 30 minutes before departure.
            </p>
            <p>
              Reading a position like{" "}
              <b className="font-semibold text-black">GNWL21/WL9</b>: the first
              number is where you entered the list, the second is where you sit
              today. So GNWL21/WL9 means you started 21st and nine people are
              still ahead — the list has already moved twelve places your way.{" "}
              <b className="font-semibold text-black">RAC 12</b> means you would
              board on a shared berth, twelfth in the RAC queue.
            </p>
          </div>
        </Reveal>
      </section>

      {/* CTA */}
      <section className="mx-auto max-w-3xl px-4 py-20 md:py-24">
        <Reveal from="zoom">
          <div className="flex flex-col items-center gap-5 rounded-3xl bg-midnight p-8 text-center text-white md:p-12">
            <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/[0.08] ring-1 ring-white/[0.12]">
              <Bell size={22} className="text-sun" />
            </span>
            <h2 className="text-[26px] font-bold tracking-tight md:text-[32px]">
              Let Railly decode and watch it.
            </h2>
            <p className="mx-auto max-w-md text-[16px] leading-relaxed text-silver">
              Add your PNR once. Railly shows the plain-English meaning of every
              status, tracks the waitlist trend, and alerts you the moment it
              moves — right up to chart time.
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
            See the quick reference on the{" "}
            <Link
              href="/pnr-status"
              className="font-semibold text-signal underline-offset-4 hover:underline"
            >
              PNR status page
            </Link>
            , or read the{" "}
            <Link
              href="/guides/tatkal-booking-time"
              className="inline-flex items-center gap-1 font-semibold text-signal underline-offset-4 hover:underline"
            >
              Tatkal timing guide
              <ArrowRight size={13} strokeWidth={2.2} />
            </Link>
            .
          </p>
        </Reveal>
      </section>
    </PageShell>
  );
}
