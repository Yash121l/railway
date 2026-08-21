import type { Metadata } from "next";
import { PageHero, PageShell } from "@/components/marketing/PageShell";

const TERMS_DESCRIPTION =
  "The plain-English terms for using Railly: an unofficial Indian Railways companion app. What we promise, what we don't, and how to reach us.";

export const metadata: Metadata = {
  title: "Terms of Service",
  description: TERMS_DESCRIPTION,
  alternates: { canonical: "/terms" },
  openGraph: {
    type: "website",
    siteName: "Railly",
    locale: "en_IN",
    url: "/terms",
    title: "Terms of Service — Railly",
    description: TERMS_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: "Terms of Service — Railly",
    description: TERMS_DESCRIPTION,
  },
};

/*
 * Same quiet treatment as /privacy: no cards, no reveals — a legal page a
 * person can read on a platform bench before their train arrives.
 */
export default function TermsPage() {
  return (
    <PageShell closingCta={false}>
      <PageHero
        eyebrow="Terms"
        title="The fine print, minus the fine."
        dek="These are the terms for using Railly. We&rsquo;ve kept them short and in plain English, because terms you can&rsquo;t read aren&rsquo;t really terms."
      />

      <article className="mx-auto max-w-2xl px-4 pb-24">
        <p className="pt-6 text-[13px] text-steel">Last updated: July 2026</p>

        <h2 className="pt-10 text-[22px] font-bold text-black">The service</h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          Railly is an unofficial companion app for travelling on Indian
          Railways. We are not affiliated with, endorsed by, or connected to
          Indian Railways, IRCTC, or any government body. Railly doesn&apos;t
          sell tickets — it helps you track, understand, and remember the
          journeys you take.
        </p>

        <h2 className="pt-10 text-[22px] font-bold text-black">Accuracy</h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          We work hard to be right, but rail data is live and messy. Anything
          Railly predicts or estimates — delay forecasts, arrival times,
          confirmation chances — is labelled as a prediction or an estimate in
          the app. Treat it as a well-informed guess, not a guarantee. For
          anything that matters — catching a connection, a refund window, a
          cancelled train — always verify against official Indian Railways
          sources before you act.
        </p>

        <h2 className="pt-10 text-[22px] font-bold text-black">
          Acceptable use
        </h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          Use Railly for your own travel and the travel of people who&apos;ve
          chosen to share with you. Don&apos;t look up PNRs that aren&apos;t
          yours to look up, don&apos;t scrape or resell data obtained through
          the app, and don&apos;t use Railly in ways that break the law or
          overload the services we rely on.
        </p>

        <h2 className="pt-10 text-[22px] font-bold text-black">
          Payment
        </h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          Railly is free. There is no subscription, no paid tier, no gift card,
          and no in-app purchase, so there is nothing to bill or cancel. If a
          paid plan is ever introduced, these terms will be updated before it
          goes on sale.
        </p>

        <h2 className="pt-10 text-[22px] font-bold text-black">Liability</h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          Railly is provided as-is. To the fullest extent the law allows, we
          aren&apos;t liable for losses that come from relying on the app —
          including missed trains, missed connections, or decisions made on
          data that turned out to be wrong or late. Where liability can&apos;t
          be excluded, it&apos;s capped at what you paid us in the twelve
          months before the claim. Nothing here limits rights that consumer
          law gives you and doesn&apos;t let us take away.
        </p>

        <h2 className="pt-10 text-[22px] font-bold text-black">Changes</h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          We&apos;ll update these terms as the product evolves. When we do,
          we&apos;ll change the date at the top of this page, and for material
          changes we&apos;ll tell you in the app before they take effect.
          Continuing to use Railly after that means you accept the new terms.
        </p>

        <h2 className="pt-10 text-[22px] font-bold text-black">Contact</h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          Questions about these terms? Write to{" "}
          <a
            href="mailto:legal@railly.app"
            className="font-semibold text-signal hover:underline"
          >
            legal@railly.app
          </a>
          . We read everything.
        </p>
      </article>
    </PageShell>
  );
}
