import Link from "next/link";
import { ArrowRight, Compass, GitCompare, LifeBuoy } from "lucide-react";
import { PageShell } from "@/components/marketing/PageShell";

const LINKS: {
  href: string;
  label: string;
  sub: string;
  icon: typeof Compass;
}[] = [
  {
    href: "/",
    label: "Back to the platform",
    sub: "The Railly home page",
    icon: Compass,
  },
  {
    href: "/help",
    label: "Help Center",
    sub: "PNR, chart timing & Tatkal",
    icon: LifeBuoy,
  },
  {
    href: "/compare",
    label: "Compare train apps",
    sub: "Railly vs the rest, honestly",
    icon: GitCompare,
  },
];

export default function NotFound() {
  return (
    <PageShell closingCta={false}>
      <section className="mx-auto flex max-w-3xl flex-col items-center px-4 py-24 text-center md:py-32">
        <div className="tnum text-[13px] font-bold uppercase tracking-[3px] text-signal">
          404 · No train on this line
        </div>
        <h1 className="mt-5 text-[40px] font-bold leading-[1.05] tracking-[-1px] text-black [text-wrap:balance] md:text-[56px]">
          This platform doesn&apos;t exist.
        </h1>
        <p className="mx-auto mt-5 max-w-xl text-[17px] leading-relaxed text-carbon">
          The page you were looking for has been rerouted, renamed, or never ran
          in the first place. Let&apos;s get you back on a track that goes
          somewhere.
        </p>

        <div className="mt-12 grid w-full gap-3 sm:grid-cols-3">
          {LINKS.map(({ href, label, sub, icon: Icon }) => (
            <Link
              key={href}
              href={href}
              className="card-lift group flex h-full flex-col items-start rounded-3xl bg-linen p-6 text-left ring-1 ring-black/[0.05]"
            >
              <span className="flex h-11 w-11 items-center justify-center rounded-full bg-white ring-1 ring-black/[0.05]">
                <Icon size={19} className="text-carbon" strokeWidth={1.8} />
              </span>
              <span className="mt-4 flex items-center gap-1 text-[16px] font-bold tracking-tight text-black">
                {label}
                <ArrowRight
                  size={15}
                  strokeWidth={2.2}
                  className="text-signal transition-transform group-hover:translate-x-0.5"
                />
              </span>
              <span className="mt-1 text-[13px] leading-relaxed text-steel">
                {sub}
              </span>
            </Link>
          ))}
        </div>
      </section>
    </PageShell>
  );
}
