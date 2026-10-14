import type { Metadata } from "next";
import { PageHero, PageShell } from "@/components/marketing/PageShell";

const PRIVACY_DESCRIPTION =
  "How Railly handles your data: trips stay on your device, PNR queries are never stored by us, and analytics are anonymous product counts you can switch off in the app.";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: PRIVACY_DESCRIPTION,
  alternates: { canonical: "/privacy" },
  openGraph: {
    type: "website",
    siteName: "Railly",
    locale: "en_IN",
    url: "/privacy",
    title: "Privacy Policy — Railly",
    description: PRIVACY_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: "Privacy Policy — Railly",
    description: PRIVACY_DESCRIPTION,
  },
};

/*
 * Legal pages stay deliberately quiet: no Reveal choreography, no cards —
 * just the PageHero voice and a readable single-column stack.
 */
export default function PrivacyPage() {
  return (
    <PageShell closingCta={false}>
      <PageHero
        eyebrow="Privacy"
        title="Your journeys are yours."
        dek="This is the whole policy — short enough to actually read. The one-line version: your trips live on your phone, and we don&rsquo;t want data we don&rsquo;t need."
      />

      <article className="mx-auto max-w-2xl px-4 pb-24">
        <p className="pt-6 text-[13px] text-steel">Last updated: October 2026</p>

        <h2 className="pt-10 text-[22px] font-bold text-black">
          What we collect
        </h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          The trips you add to Railly — trains, dates, seats, notes — are
          stored on your device. They are not uploaded to our servers, and we
          can&apos;t see them.
        </p>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          When you check a PNR or a train&apos;s running status, the number you
          entered is sent to the live status services that answer the query.
          That&apos;s what a lookup is. We pass it through to get your answer
          and we do not store it — there is no server-side history of your PNR
          numbers with us.
        </p>

        <h2 className="pt-10 text-[22px] font-bold text-black">Data sources</h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          Railly&apos;s Indian Railways schedule data — trains, routes, timings
          — comes via erail.in. Live PNR and running-status answers come from
          live PNR feeds. Those services receive only what&apos;s needed to
          answer the specific query you made, and each has its own privacy
          practices that we don&apos;t control.
        </p>

        <h2 className="pt-10 text-[22px] font-bold text-black">Analytics</h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          Railly uses PostHog for product analytics, on this website and in
          the iOS app. It counts page views, which features get used (a PNR
          check, a train opened on RailLens, a trip added in the app), errors
          and crashes, and how fast pages load. It never receives your PNR
          number, passenger statuses, or your saved trips, and there is no
          account, so nothing is tied to your name or email. Website session
          recordings mask everything you type and leave the PNR result out
          entirely; app recordings mask every text field. In the app you can
          turn analytics off at any time in{" "}
          <span className="font-semibold text-black">
            Settings&nbsp;&rarr;&nbsp;Privacy
          </span>
          . Still no ad trackers, no fingerprinting, and nothing is sold or
          shared.
        </p>

        <h2 className="pt-10 text-[22px] font-bold text-black">
          Your controls
        </h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          Everything Railly knows about your travels can be exported or deleted
          by you, whenever you like, in{" "}
          <span className="font-semibold text-black">
            Settings&nbsp;&rarr;&nbsp;Account Data
          </span>
          . Export gives you your full trip history in a portable format;
          delete removes it from your device immediately. Because your trips
          never left your device, deleting them there is deleting them,
          period.
        </p>

        <h2 className="pt-10 text-[22px] font-bold text-black">Contact</h2>
        <p className="mt-3 text-[15px] leading-relaxed text-carbon">
          Questions about any of this — or something that reads differently
          from how the app behaves? Write to{" "}
          <a
            href="mailto:privacy@railly.app"
            className="font-semibold text-signal hover:underline"
          >
            privacy@railly.app
          </a>{" "}
          and a human will answer.
        </p>
      </article>
    </PageShell>
  );
}
