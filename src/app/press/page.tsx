import type { Metadata } from "next";
import Image from "next/image";
import { Download, Mail } from "lucide-react";
import { MiniPhone } from "@/components/marketing/MidSections";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";

export const metadata: Metadata = {
  title: "Press",
  description:
    "Railly press kit — logo, real app screenshots, boilerplate, and fast facts. The Flighty of Indian Railways: live tracking, delay predictions, and a rail logbook, built for iPhone.",
};

const PRESS_EMAIL = "mailto:hello@railly.app?subject=Press%20enquiry";

const BOILERPLATE =
  "Railly is an independent, iPhone-first companion for Indian Railways — the Flighty of Indian Railways. It offers running status projected from the published timetable and labelled as an estimate, real PNR status, coach position from the reservation chart, a seat-availability model, and a Passport that logs every kilometre you ride. Its offline catalog covers 4,022 trains and 9,109 station codes. Railly is not affiliated with Indian Railways or IRCTC, sells no tickets, and shows no ads — when you're ready to book, it deep-links you straight to IRCTC.";

const SCREENS: { src: string; alt: string; label: string; file: string }[] = [
  {
    src: "/screens/hero-app.png",
    alt: "Railly home screen with live train tracking",
    label: "Home · live tracking",
    file: "railly-home.png",
  },
  {
    src: "/screens/my-trips.png",
    alt: "Railly My Trips screen with the live network map",
    label: "My Trips",
    file: "railly-my-trips.png",
  },
  {
    src: "/screens/trip-detail.png",
    alt: "Railly trip detail with the live route map and delay prediction",
    label: "Trip detail",
    file: "railly-trip-detail.png",
  },
  {
    src: "/screens/logbook.png",
    alt: "Railly Passport logbook of lifetime rail stats",
    label: "Passport logbook",
    file: "railly-passport.png",
  },
  {
    src: "/screens/pnr.png",
    alt: "Railly PNR status screen",
    label: "PNR status",
    file: "railly-pnr.png",
  },
];

const FACTS: [string, string][] = [
  ["Category", "Train tracking · travel companion"],
  ["Platform", "iPhone (iOS), native SwiftUI"],
  ["Coverage", "4,022 trains · 9,109 station codes · works offline"],
  ["Business model", "Free with an optional Pro subscription · no ads"],
  ["Independence", "Not affiliated with Indian Railways or IRCTC"],
  ["Status", "On the waitlist ahead of App Store launch"],
];

export default function PressPage() {
  return (
    <PageShell>
      <PageHero
        eyebrow="PRESS"
        title="Press kit"
        dek="Everything you need to write about Railly — the logo, real app screenshots, our boilerplate, and the fast facts. Grab what you need; if something's missing, just email us."
      />

      {/* the one-liner */}
      <section className="mx-auto max-w-3xl px-4 pb-4 pt-8">
        <Reveal from="zoom">
          <figure className="rounded-3xl bg-midnight p-8 text-center md:p-12">
            <blockquote className="text-[28px] font-bold leading-tight tracking-tight text-white md:text-[38px]">
              &ldquo;Railly is the Flighty of Indian Railways.&rdquo;
            </blockquote>
            <figcaption className="mt-4 text-[13px] font-semibold uppercase tracking-[1.5px] text-white/50">
              Our one-liner — quote it freely
            </figcaption>
          </figure>
        </Reveal>
      </section>

      {/* boilerplate */}
      <section className="mx-auto max-w-3xl px-4 py-16 md:py-20">
        <Reveal>
          <h2 className="text-[22px] font-bold tracking-tight text-black">
            Boilerplate
          </h2>
          <p className="mt-2 text-[14px] text-steel">
            Copy-and-paste description for articles and listings.
          </p>
          <div className="mt-6 rounded-3xl bg-linen p-7 ring-1 ring-black/[0.05] md:p-8">
            <p className="text-[16px] leading-relaxed text-carbon">
              {BOILERPLATE}
            </p>
          </div>
        </Reveal>
      </section>

      {/* logo */}
      <section className="bg-linen px-4 py-20 md:py-28">
        <div className="mx-auto max-w-4xl">
          <Reveal className="text-center">
            <h2 className="text-headline text-black md:text-[40px] md:leading-[1.05]">
              The mark.
            </h2>
            <p className="mx-auto mt-4 max-w-lg text-[16px] leading-relaxed text-carbon">
              The Railly icon on light and dark. Please keep the clear space and
              don&apos;t recolour it.
            </p>
          </Reveal>

          <div className="mt-12 grid gap-4 sm:grid-cols-2">
            <Reveal from="left">
              <div className="flex flex-col items-center gap-6 rounded-3xl bg-white p-10 ring-1 ring-black/[0.06]">
                <Image src="/logo.svg" alt="Railly logo" width={96} height={96} className="rounded-[22px]" />
                <span className="text-[12px] font-semibold uppercase tracking-[1.5px] text-steel">
                  On light
                </span>
              </div>
            </Reveal>
            <Reveal from="right">
              <div className="flex flex-col items-center gap-6 rounded-3xl bg-midnight p-10 ring-1 ring-white/10">
                <Image src="/logo.svg" alt="Railly logo on a dark background" width={96} height={96} className="rounded-[22px]" />
                <span className="text-[12px] font-semibold uppercase tracking-[1.5px] text-white/50">
                  On dark
                </span>
              </div>
            </Reveal>
          </div>

          <Reveal delay={80}>
            <div className="mt-8 text-center">
              <a
                href="/logo.svg"
                download="railly-logo.svg"
                className="inline-flex items-center gap-2 rounded-full bg-black px-6 py-3 text-[15px] font-semibold text-white transition-transform hover:scale-[1.03] active:scale-95"
              >
                <Download size={16} />
                Download logo (SVG)
              </a>
            </div>
          </Reveal>
        </div>
      </section>

      {/* screenshots */}
      <section className="mx-auto max-w-6xl px-4 py-20 md:py-28">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-headline text-black md:text-[40px] md:leading-[1.05]">
            Screenshots.
          </h2>
          <p className="mt-4 text-[16px] leading-relaxed text-carbon">
            Real screens from the app, straight off the device. Tap any shot to
            download the full-resolution PNG.
          </p>
        </Reveal>

        <div className="mt-14 grid grid-cols-2 gap-8 sm:grid-cols-3 lg:grid-cols-5">
          {SCREENS.map((shot, i) => (
            <Reveal key={shot.src} delay={i * 60} className="flex flex-col items-center gap-4">
              <a
                href={shot.src}
                download={shot.file}
                className="transition-transform hover:scale-[1.03] active:scale-95"
                aria-label={`Download ${shot.label} screenshot`}
              >
                <MiniPhone src={shot.src} alt={shot.alt} className="w-[150px] md:w-[168px]" />
              </a>
              <span className="inline-flex items-center gap-1.5 text-[12px] font-semibold text-steel">
                <Download size={12} />
                {shot.label}
              </span>
            </Reveal>
          ))}
        </div>
      </section>

      {/* fast facts */}
      <section className="bg-linen px-4 py-20 md:py-28">
        <div className="mx-auto max-w-3xl">
          <Reveal className="text-center">
            <h2 className="text-headline text-black md:text-[40px] md:leading-[1.05]">
              Fast facts.
            </h2>
          </Reveal>
          <Reveal delay={60}>
            <dl className="mt-12 divide-y divide-black/[0.06] overflow-hidden rounded-3xl bg-white ring-1 ring-black/[0.06]">
              {FACTS.map(([term, value]) => (
                <div
                  key={term}
                  className="flex flex-col gap-1 px-6 py-5 sm:flex-row sm:items-baseline sm:gap-6 md:px-8"
                >
                  <dt className="w-40 shrink-0 text-[12px] font-bold uppercase tracking-[1.5px] text-steel">
                    {term}
                  </dt>
                  <dd className="text-[15px] leading-relaxed text-carbon">
                    {value}
                  </dd>
                </div>
              ))}
            </dl>
          </Reveal>
        </div>
      </section>

      {/* contact */}
      <section className="mx-auto max-w-6xl px-4 py-20 md:py-28">
        <Reveal from="zoom">
          <div className="flex flex-col items-center gap-5 rounded-3xl bg-linen p-8 text-center ring-1 ring-black/[0.05] md:p-10">
            <span className="flex h-11 w-11 items-center justify-center rounded-full bg-white ring-1 ring-black/[0.05]">
              <Mail size={19} className="text-carbon" strokeWidth={1.8} />
            </span>
            <div>
              <h2 className="text-[22px] font-bold tracking-tight text-black">
                Press &amp; media
              </h2>
              <p className="mx-auto mt-2 max-w-md text-[15px] leading-relaxed text-carbon">
                Interviews, review builds, or an asset you can&apos;t find here —
                a real person who rides these trains reads every message, usually
                within a day.
              </p>
            </div>
            <a
              href={PRESS_EMAIL}
              className="rounded-full bg-signal px-7 py-3.5 text-[15px] font-semibold text-white transition-transform hover:scale-[1.03] active:scale-95"
            >
              hello@railly.app
            </a>
          </div>
        </Reveal>
      </section>
    </PageShell>
  );
}
