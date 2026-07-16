import {
  AlarmClock,
  ArrowRight,
  ChevronDown,
  Info,
  Mail,
  Radio,
  ShieldCheck,
  Ticket,
} from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { JsonLd } from "@/components/seo/JsonLd";

const HELP_TITLE = "PNR Status, Chart Timing & Tatkal — Railly Help";
const HELP_DESCRIPTION =
  "Answers on PNR status and chart timing, live train tracking and delay predictions, Tatkal windows, the availability grid, and how Railly handles your data.";

export const metadata: Metadata = {
  title: { absolute: HELP_TITLE },
  description: HELP_DESCRIPTION,
  alternates: { canonical: "/help" },
  openGraph: {
    type: "website",
    siteName: "Railly",
    locale: "en_IN",
    url: "/help",
    title: HELP_TITLE,
    description: HELP_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: HELP_TITLE,
    description: HELP_DESCRIPTION,
  },
};

/* ------------------------------------------------------------------ */
/* Data — one source of truth for both the accordions and the         */
/* FAQPage structured data, so the markup can never drift from the     */
/* text a reader actually sees.                                        */
/* ------------------------------------------------------------------ */

type GroupId = "about" | "pnr" | "tracking" | "tatkal" | "data";

const GROUPS: {
  id: GroupId;
  icon: React.ReactNode;
  title: string;
  sub: string;
  guide?: { href: string; label: string };
}[] = [
  {
    id: "about",
    icon: <Info size={20} className="text-carbon" strokeWidth={1.8} />,
    title: "About Railly",
    sub: "What Railly is — and what it isn't.",
  },
  {
    id: "pnr",
    icon: <Ticket size={20} className="text-carbon" strokeWidth={1.8} />,
    title: "PNR & bookings",
    sub: "Statuses decoded, charts demystified.",
    guide: {
      href: "/guides/pnr-status-explained",
      label: "Read the full PNR status guide",
    },
  },
  {
    id: "tracking",
    icon: <Radio size={20} className="text-carbon" strokeWidth={1.8} />,
    title: "Live tracking",
    sub: "Where the numbers come from — and what they mean.",
    guide: {
      href: "/guides/live-train-running-status",
      label: "Read the live running status guide",
    },
  },
  {
    id: "tatkal",
    icon: <AlarmClock size={20} className="text-carbon" strokeWidth={1.8} />,
    title: "Tatkal & seats",
    sub: "The windows, the reminder, and reading the grid.",
    guide: {
      href: "/guides/tatkal-booking-time",
      label: "Read the Tatkal booking-time guide",
    },
  },
  {
    id: "data",
    icon: <ShieldCheck size={20} className="text-carbon" strokeWidth={1.8} />,
    title: "Data & privacy",
    sub: "What Railly stores, and where it comes from.",
  },
];

const FAQS: { group: GroupId; q: string; a: string }[] = [
  {
    group: "about",
    q: "Is Railly the official Indian Railways app?",
    a: "No. Railly is an independent app and is not affiliated with, endorsed by, or operated by Indian Railways or IRCTC. It reads publicly available railway data to track trains, watch your PNR, and predict delays — but it isn't a booking app, and it isn't the official enquiry system. For the railway's own word we keep NTES installed too, and when you're ready to buy a ticket Railly deep-links you straight to IRCTC.",
  },
  {
    group: "about",
    q: "Is Railly available on Android?",
    a: "Not yet. Railly is built for iPhone first — a native iOS app, designed and polished for the platform rather than ported across from something else. There's no Android version today. If you'd like one, write to us at hello@railly.app so we can see the demand.",
  },
  {
    group: "pnr",
    q: "What do CNF, RAC, GNWL, and TQWL actually mean?",
    a: "CNF means confirmed — you have a berth of your own. RAC (Reservation Against Cancellation) means you can board, but you start with a shared berth and usually get a full one as confirmed passengers cancel. GNWL is the general waitlist and the most likely kind to clear; TQWL is the Tatkal waitlist, which clears far less often because Tatkal bookings have no separate quota of cancellations feeding it. Railly shows the plain-English meaning next to every status, so you never have to decode the string yourself.",
  },
  {
    group: "pnr",
    q: "When does the chart prepare?",
    a: "The reservation chart is drawn up about 8 hours before your train's departure from its origin station. For morning trains, that means the chart prepares around 9 PM the previous night — so a waitlisted ticket for a 7 AM departure is decided the evening before, not at dawn. Railly notifies you the moment your chart prepares, with your final status and, if you cleared, your coach and berth.",
  },
  {
    group: "pnr",
    q: "How does PNR import work?",
    a: "Add a trip with its 10-digit PNR and Railly resolves the whole journey — train, date, class, boarding and destination stations, and the current status of every passenger — and files it under My Trips. From then on Railly re-checks the PNR automatically, stepping up the frequency as chart time approaches, and pushes a notification whenever your status moves. No more refreshing an enquiry page every hour.",
  },
  {
    group: "pnr",
    q: "Why did my PNR stop resolving?",
    a: "Indian Railways flushes PNR records from its live enquiry system a few days after the journey ends, or after a full cancellation. A flushed PNR returns nothing from any app or website — it's gone at the source, not just in Railly. Your trip itself isn't lost: everything Railly already fetched stays in your logbook on your device. Only fresh status lookups stop working.",
  },
  {
    group: "tracking",
    q: "Where does live running status come from?",
    a: "Wherever a live feed is available for your train, Railly uses it and marks the status Live. Where no feed exists, Railly falls back to timetable-based estimates built from the train's schedule and its recent running pattern — and labels them as estimates. You always know whether you're looking at a reported position or a projection; Railly never dresses one up as the other.",
  },
  {
    group: "tracking",
    q: "How accurate is Railly's live status?",
    a: "It depends on the train, and Railly always tells you which you're looking at. Where a live feed is available, Railly reports the train's position and marks it Live. Where no feed exists, Railly shows a timetable-based estimate built from the schedule and recent running patterns, and labels it as an estimate rather than dressing it up as a live report. Delay figures for your station are shown as predictions, alongside the official running status — so you always know how much to trust a number before you rely on it.",
  },
  {
    group: "tracking",
    q: "How do delay predictions work?",
    a: "A train that's 40 minutes late three hours away from you rarely arrives exactly 40 minutes late. Railly projects the delay at your station by looking at where the train typically loses or makes up time along the route and how the section ahead is flowing today, instead of just repeating the current figure. Predictions are always shown as predictions, alongside the official running status.",
  },
  {
    group: "tracking",
    q: "What are platform alerts?",
    a: "Railly watches the platform assignment at your boarding and arrival stations and pushes a notification the moment it's published — or changes. Combined with coach position, you'll know not just which platform to stand on, but where along it your coach will halt, so a last-minute platform swap becomes a walk instead of a sprint.",
  },
  {
    group: "tatkal",
    q: "When does Tatkal booking open?",
    a: "Tatkal opens one day before the journey date, counted from the train's origin station: 10 AM for AC classes and 11 AM for non-AC (Sleeper and Second Sitting). On busy routes the quota can be gone within minutes, so being logged in and ready at the opening bell matters more than anything else you can do.",
  },
  {
    group: "tatkal",
    q: "What is the 9:55 reminder?",
    a: "If a journey you're watching is still waitlisted, Railly nudges you at 9:55 AM the day before travel — five minutes ahead of the AC Tatkal window — and again before the 11 AM non-AC window when that's the one you need. That's enough time to log in to IRCTC, load your saved passenger list, and be sitting on the booking screen when the quota opens.",
  },
  {
    group: "tatkal",
    q: "How do I read the availability grid?",
    a: "Each cell shows the railway's own status string for a date and class. AVAILABLE-0042 means 42 berths can be booked and confirmed right now. RAC 12 means you'd board with a shared berth, twelfth in the RAC queue. GNWL21/WL9 means you'd join the general waitlist — 21 people entered it before you, and 9 are still ahead today. Railly colors the grid so you can scan a whole week at a glance instead of parsing each string.",
  },
  {
    group: "data",
    q: "Where do my journeys live?",
    a: "On your device. Your trips, logbook, and travel stats are stored locally in the app — your travel history is viewable only by you and isn't uploaded to our servers. If you choose to share a journey with a friend, only that journey's status is shared, only with the people you picked.",
  },
  {
    group: "data",
    q: "How do I export or delete my data?",
    a: "Both live in Settings. Export produces a file with every journey Railly has recorded so your history is never locked in; Delete wipes the logbook and all stored PNRs from the device in one step. Because your data lives on the device, removing the app removes the data with it.",
  },
  {
    group: "data",
    q: "What data sources does Railly use?",
    a: "Train schedules, routes, and station data come from Indian Railways, accessed via erail.in. PNR status is resolved through live public feeds. In the app, every status is labelled with whether it's live or estimated, so the provenance of what you're reading is never a mystery.",
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

/* ------------------------------------------------------------------ */
/* Pieces                                                              */
/* ------------------------------------------------------------------ */

/** One accordion row — native <details>, styled to the system. */
function Faq({ q, a }: { q: string; a: string }) {
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

/** A titled cluster of FAQs with a deep-linkable anchor. */
function FaqGroup({
  id,
  icon,
  title,
  sub,
  guide,
  children,
}: {
  id: string;
  icon: React.ReactNode;
  title: string;
  sub: string;
  guide?: { href: string; label: string };
  children: React.ReactNode;
}) {
  return (
    <section id={id} className="scroll-mt-24">
      <Reveal>
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-3.5">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-linen ring-1 ring-black/[0.05]">
              {icon}
            </span>
            <div>
              <h2 className="text-[22px] font-bold tracking-tight text-black">
                {title}
              </h2>
              <p className="text-[13px] text-steel">{sub}</p>
            </div>
          </div>
          {guide && (
            <Link
              href={guide.href}
              className="inline-flex items-center gap-1.5 text-[14px] font-semibold text-signal transition-colors hover:text-black"
            >
              {guide.label}
              <ArrowRight size={15} strokeWidth={2.2} />
            </Link>
          )}
        </div>
        <div className="mt-5 flex flex-col gap-3">{children}</div>
      </Reveal>
    </section>
  );
}

export default function HelpPage() {
  return (
    <PageShell>
      <JsonLd data={FAQ_JSON_LD} />
      <PageHero
        eyebrow="HELP CENTER"
        title="Answers, before you have to ask the TTE."
        dek="Everything about PNR statuses, chart timing, live tracking, Tatkal windows, and how Railly treats your data — in plain language, with the railway jargon decoded."
      />

      {/* jump pills — deep links into each group */}
      <nav className="mx-auto flex max-w-3xl flex-wrap justify-center gap-2.5 px-4 pt-6">
        {GROUPS.map((group) => (
          <a
            key={group.id}
            href={`#${group.id}`}
            className="rounded-full bg-linen px-4 py-2 text-[13px] font-semibold text-carbon ring-1 ring-black/[0.05] transition-colors hover:text-black"
          >
            {group.title}
          </a>
        ))}
      </nav>

      <div className="mx-auto flex max-w-3xl flex-col gap-16 px-4 py-20 md:py-28">
        {GROUPS.map((group) => (
          <FaqGroup
            key={group.id}
            id={group.id}
            icon={group.icon}
            title={group.title}
            sub={group.sub}
            guide={group.guide}
          >
            {FAQS.filter((f) => f.group === group.id).map((f) => (
              <Faq key={f.q} q={f.q} a={f.a} />
            ))}
          </FaqGroup>
        ))}

        {/* contact strip */}
        <Reveal from="zoom">
          <div className="flex flex-col items-center gap-5 rounded-3xl bg-linen p-8 text-center ring-1 ring-black/[0.05] md:p-10">
            <span className="flex h-11 w-11 items-center justify-center rounded-full bg-white ring-1 ring-black/[0.05]">
              <Mail size={19} className="text-carbon" strokeWidth={1.8} />
            </span>
            <div>
              <h2 className="text-[22px] font-bold tracking-tight text-black">
                Still stuck?
              </h2>
              <p className="mx-auto mt-2 max-w-md text-[15px] leading-relaxed text-carbon">
                Write to us — a human who rides these trains reads every
                message, usually within a day.
              </p>
            </div>
            <a
              href="mailto:hello@railly.app"
              className="rounded-full bg-signal px-7 py-3.5 text-[15px] font-semibold text-white transition-transform hover:scale-[1.03] active:scale-95"
            >
              hello@railly.app
            </a>
          </div>
        </Reveal>
      </div>
    </PageShell>
  );
}
