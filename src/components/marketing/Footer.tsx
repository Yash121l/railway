import Link from "next/link";
import { TrainFront } from "lucide-react";
import { APP_CTA_HREF, APP_CTA_LABEL } from "@/lib/cta";
import { Reveal } from "./Reveal";

export function ClosingCta() {
  return (
    <section className="bg-linen px-4 py-28 text-center md:py-36">
      <Reveal>
        <h3 className="text-headline text-black md:text-[44px]">
          Have a nice journey!
        </h3>
        <p className="mx-auto mt-4 max-w-md text-[17px] leading-relaxed text-carbon">
          We&apos;ll handle the details. You just enjoy the ride. Built for
          iPhone. Free to start.
        </p>
        <a
          href={APP_CTA_HREF}
          className="mt-8 inline-block rounded-full bg-sun px-8 py-4 text-[16px] font-semibold text-black transition-transform hover:scale-[1.03] active:scale-95"
        >
          {APP_CTA_LABEL}
        </a>
      </Reveal>
    </section>
  );
}

/** Every link resolves — a footer is a site map, not decoration. */
const COLUMNS: [string, [string, string][]][] = [
  [
    "Product",
    [
      ["Features", "/#features"],
      ["Pricing", "/pricing"],
      ["Trains", "/trains"],
      ["Passport", "/passport"],
      ["Stations", "/stations"],
      ["Network Intelligence", "/#network"],
      ["Gift Cards", "/gift-cards"],
    ],
  ],
  [
    "Compare",
    [
      ["vs. NTES", "/compare/railly-vs-ntes"],
      ["vs. Where Is My Train", "/compare/railly-vs-where-is-my-train"],
      ["vs. RailYatri", "/compare/railly-vs-railyatri"],
      ["vs. ixigo trains", "/compare/railly-vs-ixigo"],
      ["All comparisons", "/compare"],
    ],
  ],
  [
    "Support",
    [
      ["Help Center", "/help"],
      ["PNR Status", "/pnr-status"],
      ["Live tracking", "/guides/live-train-running-status"],
      ["Tatkal & seats", "/guides/tatkal-booking-time"],
      ["Contact us", "mailto:hello@railly.app"],
    ],
  ],
  [
    "Legal",
    [
      ["Privacy Policy", "/privacy"],
      ["Terms of Service", "/terms"],
      ["Data & privacy in the app", "/help#data"],
    ],
  ],
];

export function Footer() {
  return (
    <footer className="border-t border-black/[0.06] bg-white px-4 py-16">
      <div className="mx-auto grid max-w-6xl gap-10 sm:grid-cols-2 md:grid-cols-5">
        {/* brand block leads the grid on wide screens */}
        <div>
          <div className="flex items-center gap-2">
            <span className="flex h-8 w-8 items-center justify-center rounded-[10px] bg-midnight">
              <TrainFront size={16} className="text-white" />
            </span>
            <span className="text-[17px] font-bold tracking-tight text-black">
              Railly
            </span>
          </div>
          <p className="mt-4 max-w-[220px] text-[13px] leading-relaxed text-steel">
            Get the truth when you take the train. Live status, PNR watch,
            seat availability and coach position for Indian Railways. Built for
            iPhone.
          </p>
          <a
            href={APP_CTA_HREF}
            className="mt-5 inline-block rounded-full bg-black px-4 py-2 text-[13px] font-semibold text-white transition-transform hover:scale-[1.03] active:scale-95"
          >
            {APP_CTA_LABEL}
          </a>
        </div>

        {COLUMNS.map(([title, links]) => (
          <div key={title}>
            <div className="text-[13px] font-bold uppercase tracking-[1px] text-fog">
              {title}
            </div>
            <ul className="mt-4 space-y-2.5">
              {links.map(([label, href]) => (
                <li key={label}>
                  <Link
                    href={href}
                    className="text-[14px] text-carbon transition-colors hover:text-black"
                  >
                    {label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="mx-auto mt-14 flex max-w-6xl flex-col items-center justify-between gap-4 border-t border-black/[0.06] pt-8 sm:flex-row">
        <p className="text-[13px] text-steel">
          © {new Date().getFullYear()} Railly. Made with love in Mumbai, Delhi
          and Bengaluru. Not affiliated with Indian Railways or IRCTC.
        </p>
        <div className="flex flex-wrap items-center justify-center gap-x-5 gap-y-2 text-[13px] text-steel">
          <Link href="/about" className="transition-colors hover:text-black">
            About
          </Link>
          <Link href="/press" className="transition-colors hover:text-black">
            Press
          </Link>
          <Link href="/privacy" className="transition-colors hover:text-black">
            Privacy
          </Link>
          <Link href="/terms" className="transition-colors hover:text-black">
            Terms
          </Link>
          <a href="/sitemap.xml" className="transition-colors hover:text-black">
            Sitemap
          </a>
        </div>
      </div>
    </footer>
  );
}
