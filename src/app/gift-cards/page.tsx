import type { Metadata } from "next";
import { Check, Gift, Info, Mail, Smartphone, TrainFront } from "lucide-react";
import { MiniPhone } from "@/components/marketing/MidSections";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";

const GIFT_DESCRIPTION =
  "Gift Railly Pro — three months, a year, or a family year of live train tracking, delay predictions, and perfectly-timed alerts for someone you love.";

export const metadata: Metadata = {
  title: "Gift Cards",
  description: GIFT_DESCRIPTION,
  alternates: { canonical: "/gift-cards" },
  openGraph: {
    type: "website",
    siteName: "Railly",
    locale: "en_IN",
    url: "/gift-cards",
    title: "Gift Railly Pro — Gift Cards",
    description: GIFT_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: "Gift Railly Pro — Gift Cards",
    description: GIFT_DESCRIPTION,
  },
};

const GIFT_MAILTO = "mailto:hello@railly.app?subject=Gift%20Railly";

/**
 * The gift itself, rendered as a boarding pass: main panel, perforated
 * stub, monospace code. Pure CSS — the notches are page-colored circles
 * punched over the perforation line.
 */
function GiftPass() {
  return (
    <div className="relative mx-auto w-full max-w-md rotate-[-2deg] rounded-2xl bg-midnight text-white shadow-deep ring-1 ring-white/10">
      <div className="flex">
        {/* main panel */}
        <div className="flex-1 p-6">
          <div className="flex items-center justify-between gap-3">
            <span className="text-[10px] font-bold uppercase tracking-[2px] text-sun">
              Railly Gift &middot; Pro
            </span>
            <TrainFront size={15} className="text-white/60" />
          </div>
          <div className="mt-6 flex items-end gap-3">
            <div>
              <div className="text-[9px] font-bold uppercase tracking-[1.5px] text-white/40">
                From
              </div>
              <div className="text-[16px] font-bold tracking-tight">YOU</div>
            </div>
            <div className="relative mb-2 flex-1">
              <div className="border-t border-dashed border-white/25" />
              <span className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 bg-midnight px-1.5">
                <TrainFront size={13} className="text-sun" />
              </span>
            </div>
            <div className="text-right">
              <div className="text-[9px] font-bold uppercase tracking-[1.5px] text-white/40">
                To
              </div>
              <div className="text-[16px] font-bold tracking-tight">THEM</div>
            </div>
          </div>
          <div className="mt-6 text-[10px] font-semibold uppercase tracking-[1px] text-white/40">
            Redeem in the app &middot; starts when they do
          </div>
        </div>

        {/* perforation with punched notches */}
        <div className="relative border-l border-dashed border-white/25">
          <span className="absolute -left-2.5 -top-2.5 h-5 w-5 rounded-full bg-white" />
          <span className="absolute -bottom-2.5 -left-2.5 h-5 w-5 rounded-full bg-white" />
        </div>

        {/* stub */}
        <div className="flex w-[148px] flex-col items-center justify-center gap-1.5 p-5 text-center">
          <div className="text-[9px] font-bold uppercase tracking-[1.5px] text-white/40">
            Gift code
          </div>
          <div className="font-mono text-[13px] font-bold tracking-[1px] text-sun">
            RLY-XXXX-XXXX
          </div>
          <div className="mt-1 text-[9px] font-semibold uppercase tracking-[1px] text-white/40">
            Admit one &middot; Pro
          </div>
        </div>
      </div>
    </div>
  );
}

const TIERS: {
  name: string;
  price: string;
  period: string;
  features: string[];
  featured?: boolean;
}[] = [
  {
    name: "3 months",
    price: "₹399",
    period: "one-time · 3 months of Pro",
    features: [
      "Everything in Railly Pro",
      "Live running status with delay predictions",
      "Leave-for-the-station alerts, timed to traffic",
      "Coach position and platform details",
    ],
  },
  {
    name: "1 year",
    price: "₹1,299",
    period: "one-time · 12 months of Pro",
    featured: true,
    features: [
      "Everything in Railly Pro, all year",
      "Railly Passport — their whole year on rails",
      "Friends sharing for the people who worry",
      "₹297 less than four 3-month cards",
    ],
  },
  {
    name: "Family year",
    price: "₹2,499",
    period: "one-time · 12 months · up to 5 people",
    features: [
      "Railly Pro for up to 5 family members",
      "One code, five redemptions",
      "Everyone can follow everyone's journeys",
      "Each person gets their own Passport",
    ],
  },
];

function TierCard({ tier, delay }: { tier: (typeof TIERS)[number]; delay: number }) {
  return (
    <Reveal delay={delay} className="h-full">
      <div
        className={`relative flex h-full flex-col rounded-3xl p-8 ${
          tier.featured
            ? "bg-white shadow-float ring-1 ring-black/[0.08]"
            : "bg-linen ring-1 ring-black/[0.05]"
        }`}
      >
        {tier.featured && (
          <span className="absolute -top-3 left-1/2 -translate-x-1/2 whitespace-nowrap rounded-full bg-sun px-3.5 py-1 text-[11px] font-bold uppercase tracking-[1px] text-black">
            Most gifted
          </span>
        )}
        <div className="text-[13px] font-bold uppercase tracking-[1.5px] text-steel">
          {tier.name}
        </div>
        <div className="mt-3 flex items-baseline gap-2">
          <span className="tnum text-[40px] font-extrabold tracking-tight text-black">
            {tier.price}
          </span>
        </div>
        <div className="mt-1 text-[13px] text-steel">{tier.period}</div>
        <ul className="mt-6 flex flex-1 flex-col gap-3">
          {tier.features.map((f) => (
            <li key={f} className="flex items-start gap-2.5">
              <Check size={16} strokeWidth={2.5} className="mt-0.5 shrink-0 text-carbon" />
              <span className="text-[14px] leading-snug text-carbon">{f}</span>
            </li>
          ))}
        </ul>
        <a
          href={GIFT_MAILTO}
          className={`mt-8 rounded-full px-7 py-3.5 text-center text-[15px] font-semibold transition-transform hover:scale-[1.03] active:scale-95 ${
            tier.featured
              ? "bg-sun text-black"
              : "text-black ring-1 ring-black/10 hover:bg-black/[0.03]"
          }`}
        >
          Gift this
        </a>
      </div>
    </Reveal>
  );
}

const STEPS: [typeof Gift, string, string][] = [
  [
    Gift,
    "Pick a plan",
    "Three months to test the rails, a full year, or the family year for the whole household. Tell us who it's for and when it should arrive.",
  ],
  [
    Mail,
    "We email the boarding pass",
    "They get a boarding-pass-style gift code in their inbox, addressed from you — on the day you choose.",
  ],
  [
    Smartphone,
    "They redeem in the app",
    "One code entered in Railly and Pro switches on. No payment details needed from them, ever.",
  ],
];

export default function GiftCardsPage() {
  return (
    <PageShell>
      <PageHero
        eyebrow="GIFT CARDS"
        title="Give the gift of never missing a train"
        dek="For the parent who calls from the platform, the friend who lives out of a duffel bag, the family scattered across three time zones of one country. Railly Pro is the rare gift that shows up every single journey."
      />

      {/* the gift itself — a boarding pass with their name on it */}
      <section className="mx-auto max-w-6xl px-4 pb-4 pt-12">
        <Reveal from="zoom">
          <GiftPass />
        </Reveal>
        <Reveal delay={120}>
          <p className="mx-auto mt-8 max-w-md text-center text-[14px] leading-relaxed text-steel">
            Every gift arrives as a pass like this one — code on the stub,
            your name on the manifest.
          </p>
        </Reveal>
      </section>

      {/* tiers */}
      <section className="mx-auto max-w-6xl px-4 py-20 md:py-28">
        <Reveal className="mx-auto max-w-3xl text-center">
          <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
            Three ways to put someone on time.
          </h2>
          <p className="mt-4 text-[17px] leading-relaxed text-carbon">
            Every card unlocks full Railly Pro — live tracking, delay
            predictions, perfectly-timed alerts, and the Passport. The only
            question is for how long, and for how many.
          </p>
        </Reveal>
        <div className="mt-14 grid items-stretch gap-4 md:grid-cols-3">
          {TIERS.map((tier, i) => (
            <TierCard key={tier.name} tier={tier} delay={i * 80} />
          ))}
        </div>
      </section>

      {/* how it works */}
      <section className="bg-linen">
        <div className="mx-auto max-w-6xl px-4 py-20 md:py-28">
          <Reveal className="mx-auto max-w-3xl text-center">
            <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
              How it works.
            </h2>
            <p className="mt-4 text-[17px] leading-relaxed text-carbon">
              Three stops between you and a very good gift.
            </p>
          </Reveal>

          <div className="mt-14 grid gap-4 md:grid-cols-3">
            {STEPS.map(([Icon, title, body], i) => (
              <Reveal key={title} delay={i * 90}>
                <div className="flex h-full flex-col rounded-3xl bg-white p-8 ring-1 ring-black/[0.06]">
                  <div className="flex items-center gap-3">
                    <span className="tnum flex h-10 w-10 items-center justify-center rounded-full bg-linen text-[15px] font-bold text-black ring-1 ring-black/[0.06]">
                      {i + 1}
                    </span>
                    <Icon size={20} className="text-carbon" strokeWidth={1.8} />
                  </div>
                  <h3 className="mt-5 text-[18px] font-bold tracking-tight text-black">
                    {title}
                  </h3>
                  <p className="mt-2 text-[14px] leading-relaxed text-carbon">
                    {body}
                  </p>
                </div>
              </Reveal>
            ))}
          </div>

          {/* the honest bit */}
          <Reveal delay={120}>
            <div className="mx-auto mt-12 flex max-w-3xl items-start gap-4 rounded-3xl bg-white p-6 ring-1 ring-black/[0.06] md:p-8">
              <Info size={20} className="mt-0.5 shrink-0 text-steel" strokeWidth={1.8} />
              <p className="text-[14px] leading-relaxed text-carbon">
                <span className="font-bold text-black">An honest note:</span>{" "}
                we&apos;re still finishing self-serve gift checkout. For now,
                you order by email and a real person sends your gift card —
                usually within a day, always with the boarding pass attached.
                If timing is tight, say so in your email and we&apos;ll
                prioritize it.
              </p>
            </div>
          </Reveal>
        </div>
      </section>

      {/* what they actually get */}
      <section className="mx-auto max-w-6xl px-4 py-20 md:py-28">
        <div className="grid items-center gap-12 md:grid-cols-2">
          <Reveal from="left">
            <h2 className="text-headline text-black md:text-[44px] md:leading-[1.05]">
              A gift they&apos;ll open every trip.
            </h2>
            <p className="mt-5 text-[17px] leading-relaxed text-carbon">
              Most gifts get used once. This one boards the 6 a.m. Shatabdi,
              waits out the fog at Kanpur, and knows which end of the platform
              coach B4 stops at. Every journey they take, your gift is the
              calmest thing on the platform.
            </p>
            <a
              href={GIFT_MAILTO}
              className="mt-7 inline-block rounded-full bg-sun px-7 py-3.5 text-[15px] font-semibold text-black transition-transform hover:scale-[1.03] active:scale-95"
            >
              Gift Railly Pro
            </a>
          </Reveal>
          <Reveal delay={120} from="right" className="flex justify-center">
            <MiniPhone
              src="/screens/trip-detail.png"
              alt="Railly trip detail screen with live route map and delay prediction"
            />
          </Reveal>
        </div>
      </section>
    </PageShell>
  );
}
