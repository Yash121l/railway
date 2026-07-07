import { Starfield } from "./Starfield";

/**
 * flighty.com's press wall works because every cell is a real wordmark in
 * its own typeface. Our fictional outlets get the same treatment: each
 * masthead has a distinct typographic identity, all set in the same
 * silver so the wall reads as one row of logos.
 */
const PRESS: {
  outlet: string;
  quote: string;
  markClass: string;
  markStyle?: React.CSSProperties;
}[] = [
  {
    outlet: "The Daily Commute",
    quote: "The smartest travellers can't imagine taking a train without Railly",
    markClass: "text-[17px] italic",
    markStyle: { fontFamily: "Georgia, 'Times New Roman', serif", fontWeight: 700 },
  },
  {
    outlet: "PLATFORM WEEKLY",
    quote: "There are train trackers, and there's Railly",
    markClass: "text-[15px] font-black uppercase tracking-[0.02em]",
    markStyle: { fontStretch: "condensed" },
  },
  {
    outlet: "Rail Gazette",
    quote: "Railly gives riders the exact reason behind delays",
    markClass: "text-[20px] font-bold",
    markStyle: { fontFamily: "'Iowan Old Style', Georgia, serif", fontVariant: "small-caps" },
  },
  {
    outlet: "The Morning Express",
    quote: "A must-have for anyone boarding a train",
    markClass: "text-[18px]",
    markStyle: { fontFamily: "Didot, 'Bodoni 72', 'Playfair Display', Georgia, serif", fontWeight: 600, letterSpacing: "0.01em" },
  },
  {
    outlet: "TERMINUS",
    quote: "Finally, an app that treats trains like flights",
    markClass: "text-[15px] font-semibold uppercase tracking-[0.32em]",
    markStyle: { fontFamily: "ui-monospace, 'SF Mono', Menlo, monospace" },
  },
];

/** Dark press strip — wordmarks crossfade to their quotes on hover, focus, or tap. */
export function PressWall() {
  return (
    <section className="relative overflow-hidden bg-midnight px-4 pb-16 pt-44 md:pt-56">
      <Starfield className="opacity-50" />
      <div className="relative mx-auto grid max-w-6xl grid-cols-2 gap-3 md:grid-cols-5">
        {PRESS.map(({ outlet, quote, markClass, markStyle }) => (
          <button
            type="button"
            key={outlet}
            aria-label={`${outlet}: ${quote}`}
            className="group relative flex min-h-[150px] items-center justify-center rounded-2xl bg-white/[0.05] p-5 ring-1 ring-white/[0.08] transition-all duration-300 hover:-translate-y-0.5 hover:bg-white/[0.08] hover:ring-white/[0.16] focus-visible:ring-2 focus-visible:ring-signal md:min-h-[165px]"
          >
            <span
              className={`text-center text-white/[0.55] transition-opacity duration-200 group-hover:opacity-0 group-focus:opacity-0 ${markClass}`}
              style={markStyle}
            >
              {outlet}
            </span>
            <span className="absolute inset-0 flex items-center justify-center p-4 text-center text-[12px] leading-snug text-white opacity-0 transition-opacity duration-200 group-hover:opacity-100 group-focus:opacity-100">
              “{quote}”
            </span>
          </button>
        ))}
      </div>
    </section>
  );
}
