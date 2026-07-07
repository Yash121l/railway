"use client";

import Link from "next/link";
import { useState } from "react";
import { ArrowRight, Menu, Smartphone, TrainFront, X } from "lucide-react";

/** flighty.com's announcement strip is royal blue, dismissible. */
export function AnnouncementBar() {
  const [hidden, setHidden] = useState(false);
  if (hidden) return null;
  return (
    <div className="relative flex items-center justify-center gap-2 bg-[#2c39b8] px-10 py-2.5 text-[14px] font-medium text-white">
      <TrainFront size={14} className="shrink-0" />
      <span className="font-semibold">NEW! Network Intelligence</span>
      <span className="text-white/50">|</span>
      <Link
        href="/app/track"
        className="inline-flex items-center gap-1 font-semibold text-white underline-offset-2 hover:underline"
      >
        View Live <ArrowRight size={14} />
      </Link>
      <button
        aria-label="Dismiss"
        onClick={() => setHidden(true)}
        className="absolute right-4 top-1/2 -translate-y-1/2 text-white/80 hover:text-white"
      >
        <X size={16} />
      </button>
    </div>
  );
}

const LINKS = [
  ["Pricing", "#pricing"],
  ["Gift Cards", "#pricing"],
  ["Passport", "#passport"],
  ["Stations", "#features"],
  ["Help Center", "#reviews"],
] as const;

/** Plain full-width nav row, like the real site — logo, quiet links, "Get the app". */
export function Nav() {
  const [open, setOpen] = useState(false);

  return (
    <div className="sticky top-0 z-50 bg-white/90 backdrop-blur-xl">
      <nav className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="flex h-8 w-8 items-center justify-center rounded-[10px] bg-black">
            <TrainFront size={17} className="text-white" />
          </span>
          <span className="text-[19px] font-bold tracking-tight text-black">
            Railly
          </span>
        </Link>

        <div className="hidden items-center gap-1 md:flex">
          {LINKS.map(([label, href]) => (
            <a
              key={label}
              href={href}
              className="rounded-full px-3.5 py-2 text-[15px] font-medium text-black/80 transition-colors hover:text-black"
            >
              {label}
            </a>
          ))}
        </div>

        <div className="flex items-center gap-2">
          <Link
            href="/app"
            className="hidden items-center gap-1.5 text-[15px] font-semibold text-black hover:opacity-70 sm:inline-flex"
          >
            Get the app
            <Smartphone size={15} />
          </Link>
          <button
            aria-label={open ? "Close menu" : "Open menu"}
            aria-expanded={open}
            onClick={() => setOpen((o) => !o)}
            className="flex h-9 w-9 items-center justify-center rounded-full text-black md:hidden"
          >
            {open ? <X size={19} /> : <Menu size={19} />}
          </button>
        </div>
      </nav>

      {open && (
        <div className="mx-auto flex max-w-6xl flex-col border-t border-black/[0.06] px-6 py-3 md:hidden">
          {LINKS.map(([label, href]) => (
            <a
              key={label}
              href={href}
              onClick={() => setOpen(false)}
              className="rounded-xl px-2 py-3 text-[16px] font-medium text-black"
            >
              {label}
            </a>
          ))}
          <Link
            href="/app"
            onClick={() => setOpen(false)}
            className="rounded-xl px-2 py-3 text-[16px] font-semibold text-black"
          >
            Get the app →
          </Link>
        </div>
      )}
    </div>
  );
}
