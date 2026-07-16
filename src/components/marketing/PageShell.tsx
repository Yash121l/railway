import { Nav } from "./Nav";
import { ClosingCta, Footer } from "./Footer";

/**
 * Shared chrome for every subpage: the same sticky nav and footer as the
 * landing page, so the site reads as one product everywhere.
 */
export function PageShell({
  children,
  closingCta = true,
}: {
  children: React.ReactNode;
  closingCta?: boolean;
}) {
  return (
    <div className="overflow-x-clip bg-white">
      <Nav />
      <main>{children}</main>
      {closingCta && <ClosingCta />}
      <Footer />
    </div>
  );
}

/**
 * Subpage opener — eyebrow, big balanced headline, one-paragraph dek.
 * Matches the landing hero's type voice at subpage scale.
 */
export function PageHero({
  eyebrow,
  title,
  dek,
}: {
  eyebrow: string;
  title: string;
  dek: string;
}) {
  return (
    <header className="mx-auto max-w-3xl px-4 pb-4 pt-16 text-center md:pt-24">
      <div className="text-[12px] font-bold uppercase tracking-[2px] text-signal">
        {eyebrow}
      </div>
      <h1 className="mt-4 text-[36px] font-bold leading-[1.05] tracking-[-1px] text-black [text-wrap:balance] md:text-[52px]">
        {title}
      </h1>
      <p className="mx-auto mt-5 max-w-2xl text-[17px] leading-relaxed text-carbon">
        {dek}
      </p>
    </header>
  );
}
