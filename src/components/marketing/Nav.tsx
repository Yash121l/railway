import Link from "next/link";
import { ArrowRight, Smartphone, TrainFront } from "lucide-react";

export function AnnouncementBar() {
  return (
    <div className="flex items-center justify-center gap-2 bg-midnight px-4 py-2 text-[13px] font-medium text-white">
      <span className="rounded-full bg-signal px-1.5 py-0.5 text-[10px] font-bold uppercase">
        New
      </span>
      <span className="text-white/85">Network Intelligence</span>
      <Link
        href="/app/track"
        className="inline-flex items-center gap-1 text-white underline-offset-2 hover:underline"
      >
        View Live <ArrowRight size={13} />
      </Link>
    </div>
  );
}

/** Floating pill nav — sits on the page like a control device, not a bar. */
export function Nav() {
  return (
    <div className="sticky top-4 z-50 flex justify-center px-4">
      <nav className="flex items-center gap-1 rounded-full bg-white/90 py-2 pl-4 pr-2 shadow-pill ring-1 ring-black/[0.06] backdrop-blur-xl">
        <Link href="/" className="mr-2 flex items-center gap-2">
          <span className="flex h-7 w-7 items-center justify-center rounded-[9px] bg-midnight">
            <TrainFront size={15} className="text-white" />
          </span>
          <span className="text-[17px] font-bold tracking-tight text-black">
            Railly
          </span>
        </Link>
        <div className="hidden items-center md:flex">
          {[
            ["Features", "#features"],
            ["Friends", "#friends"],
            ["Passport", "#passport"],
            ["Pricing", "#pricing"],
            ["Reviews", "#reviews"],
          ].map(([label, href]) => (
            <a
              key={href}
              href={href}
              className="rounded-full px-3 py-1.5 text-[15px] font-medium text-black transition-colors hover:bg-black/[0.05]"
            >
              {label}
            </a>
          ))}
        </div>
        <Link
          href="/app"
          className="ml-2 inline-flex items-center gap-1.5 rounded-full border border-black/50 px-4 py-2 text-[14px] font-semibold text-black transition-colors hover:bg-black hover:text-white"
        >
          <Smartphone size={14} />
          Open the app
        </Link>
      </nav>
    </div>
  );
}
