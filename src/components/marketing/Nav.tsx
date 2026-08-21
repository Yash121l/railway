"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { ArrowRight, Menu, Smartphone, TrainFront, X } from "lucide-react";
import { APP_CTA_HREF, APP_CTA_LABEL } from "@/lib/cta";

const ANNOUNCEMENT_KEY = "railly-announcement-dismissed";

/** flighty.com's announcement strip is royal blue, dismissible. */
export function AnnouncementBar() {
  const [hidden, setHidden] = useState(false);
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- SSR-safe: start hidden=false on both server and client, hide post-mount to avoid a hydration mismatch
    if (window.localStorage.getItem(ANNOUNCEMENT_KEY) === "1") setHidden(true);
  }, []);
  const dismiss = () => {
    setHidden(true);
    window.localStorage.setItem(ANNOUNCEMENT_KEY, "1");
  };
  if (hidden) return null;
  return (
    <div
      className="relative flex items-center justify-center gap-2 px-10 py-2.5 text-[14px] font-medium text-white"
      style={{ background: "linear-gradient(171deg, #616170 -45%, #12128c 69%)" }}
    >
      <TrainFront size={14} className="shrink-0" />
      <span className="font-semibold">NEW! Network Intelligence</span>
      <span className="text-white/50">|</span>
      <Link
        href="/#network"
        className="inline-flex items-center gap-1 font-semibold text-white underline-offset-2 hover:underline"
      >
        View Live <ArrowRight size={14} />
      </Link>
      <button
        aria-label="Dismiss"
        onClick={dismiss}
        className="absolute right-4 top-1/2 -translate-y-1/2 text-white/80 hover:text-white"
      >
        <X size={16} />
      </button>
    </div>
  );
}

const LINKS = [
  ["RailLens", "/raillens"],
  ["Compare", "/compare"],
  ["Stations", "/stations"],
  ["Passport", "/passport"],
  ["Help Center", "/help"],
] as const;

/**
 * Starts as the real site's plain full-width row; once you scroll, it
 * detaches into flighty.com's floating white pill — shadow, tucked-in
 * width, and the "Get the app" link hardens into a black button.
 */
export function Nav() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 48);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const pill = scrolled && !open;

  return (
    <div
      className={`sticky top-0 z-50 transition-[background-color,padding] duration-500 ${
        pill ? "bg-transparent px-3 pt-4" : "bg-white/90 backdrop-blur-xl"
      }`}
    >
      {/* max-width morphs between two concrete values — fit-content would
          snap, and the whole point of the pill is the collapse feeling */}
      <nav
        className={`mx-auto flex w-full items-center justify-between transition-all duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] ${
          pill
            // 890px, not flighty's 708 — seven links plus the CTA need the
            // room, and a wrapped pill reads as broken rather than collapsed.
            ? "max-w-[890px] rounded-full bg-white/95 py-2 pl-3 pr-2 shadow-[0_18px_44px_rgba(0,0,0,0.14),0_2px_8px_rgba(0,0,0,0.06)] ring-1 ring-black/[0.06] backdrop-blur-xl"
            : "max-w-6xl px-6 py-5"
        }`}
      >
        <Link href="/" aria-label="Railly home" className="flex items-center">
          <span className="flex h-8 w-8 items-center justify-center rounded-[10px] bg-black">
            <TrainFront size={17} className="text-white" />
          </span>
          <span
            className={`inline-block overflow-hidden text-[19px] font-bold tracking-tight text-black transition-all duration-500 ${
              pill ? "ml-0 max-w-0 opacity-0" : "ml-2.5 max-w-[80px] opacity-100"
            }`}
          >
            Railly
          </span>
        </Link>

        {/* flighty's pill has a hairline between the mark and the links */}
        <span
          className={`hidden h-5 w-px bg-black/10 transition-opacity duration-500 md:block ${
            pill ? "opacity-100" : "opacity-0"
          }`}
        />

        <div className="hidden items-center gap-1 md:flex">
          {LINKS.map(([label, href]) => (
            <Link
              key={label}
              href={href}
              className="whitespace-nowrap rounded-full px-3.5 py-2 text-[15px] font-medium text-black/80 transition-colors hover:bg-black/[0.05] hover:text-black"
            >
              {label}
            </Link>
          ))}
        </div>

        <div className="flex items-center gap-2">
          <a
            href={APP_CTA_HREF}
            className={`hidden items-center gap-1.5 whitespace-nowrap text-[15px] font-semibold transition-all duration-500 sm:inline-flex ${
              pill
                ? "rounded-full bg-black px-4 py-2 text-white hover:bg-black/85"
                : "text-black hover:opacity-70"
            }`}
          >
            {APP_CTA_LABEL}
            <Smartphone size={15} />
          </a>
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
        <div className="mx-auto flex max-w-6xl flex-col border-t border-black/[0.06] bg-white px-6 py-3 md:hidden">
          {LINKS.map(([label, href]) => (
            <Link
              key={label}
              href={href}
              onClick={() => setOpen(false)}
              className="rounded-xl px-2 py-3 text-[16px] font-medium text-black"
            >
              {label}
            </Link>
          ))}
          <a
            href={APP_CTA_HREF}
            onClick={() => setOpen(false)}
            className="rounded-xl px-2 py-3 text-[16px] font-semibold text-black"
          >
            {APP_CTA_LABEL} →
          </a>
        </div>
      )}
    </div>
  );
}
