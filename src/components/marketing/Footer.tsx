import Link from "next/link";
import { TrainFront } from "lucide-react";
import { Reveal } from "./Reveal";

export function ClosingCta() {
  return (
    <section className="bg-linen px-4 py-28 text-center md:py-36">
      <Reveal>
        <h3 className="text-headline text-black md:text-[44px]">
          Have a nice journey!
        </h3>
        <p className="mx-auto mt-4 max-w-md text-[17px] leading-relaxed text-carbon">
          We&apos;ll handle the details. You just enjoy the ride. Works in any
          browser, on any device. Free to start.
        </p>
        <Link
          href="/app"
          className="mt-8 inline-block rounded-full bg-sun px-8 py-4 text-[16px] font-semibold text-black transition-transform hover:scale-[1.03] active:scale-95"
        >
          Get Railly
        </Link>
      </Reveal>
    </section>
  );
}

const COLUMNS: [string, [string, string][]][] = [
  [
    "Product",
    [
      ["My Trips", "/app"],
      ["Track", "/app/track"],
      ["Logbook", "/app/logbook"],
      ["Pricing", "#pricing"],
      ["Railly Insiders", "#"],
    ],
  ],
  [
    "Compare",
    [
      ["vs. NTES", "#"],
      ["vs. Where Is My Train", "#"],
      ["vs. RailYatri", "#"],
      ["vs. ixigo trains", "#"],
    ],
  ],
  [
    "Company",
    [
      ["About", "#"],
      ["Press", "#"],
      ["Careers", "#"],
      ["Privacy Policy", "#"],
      ["Terms of Service", "#"],
    ],
  ],
  [
    "Support",
    [
      ["Help Center", "#"],
      ["Business", "#"],
    ],
  ],
];

export function Footer() {
  return (
    <footer className="border-t border-black/[0.06] bg-white px-4 py-16">
      <div className="mx-auto grid max-w-6xl gap-10 sm:grid-cols-2 md:grid-cols-4">
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
        <div className="flex items-center gap-2">
          <span className="flex h-7 w-7 items-center justify-center rounded-[9px] bg-midnight">
            <TrainFront size={15} className="text-white" />
          </span>
          <span className="text-[16px] font-bold tracking-tight text-black">
            Railly
          </span>
        </div>
        <p className="text-[13px] text-steel">
          Made with love in Mumbai, Delhi and Bengaluru. A Flighty-inspired demo —
          not affiliated with Indian Railways.
        </p>
      </div>
    </footer>
  );
}
