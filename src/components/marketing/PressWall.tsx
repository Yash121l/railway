const PRESS = [
  {
    outlet: "The Daily Commute",
    quote: "The smartest travellers can't imagine taking a train without Railly",
  },
  {
    outlet: "Platform Weekly",
    quote: "There are train trackers, and there's Railly",
  },
  {
    outlet: "Rail Gazette",
    quote: "Railly gives riders the exact reason behind delays",
  },
  {
    outlet: "The Morning Express",
    quote: "A must-have for anyone boarding a train",
  },
  {
    outlet: "Terminus",
    quote: "Finally, an app that treats trains like flights",
  },
];

import { Starfield } from "./Starfield";

/** Dark press strip — logos crossfade to their quotes on hover, focus, or tap. */
export function PressWall() {
  return (
    <section className="relative overflow-hidden bg-midnight px-4 py-16">
      <Starfield className="opacity-50" />
      <div className="relative mx-auto grid max-w-6xl grid-cols-2 gap-3 md:grid-cols-5">
        {PRESS.map(({ outlet, quote }) => (
          <button
            type="button"
            key={outlet}
            aria-label={`${outlet}: ${quote}`}
            className="group relative flex min-h-[120px] items-center justify-center rounded-2xl bg-white/[0.05] p-5 ring-1 ring-white/[0.08] transition-all duration-300 hover:-translate-y-0.5 hover:bg-white/[0.08] hover:ring-white/[0.16] focus-visible:ring-2 focus-visible:ring-signal"
          >
            <span className="text-center text-[15px] font-bold tracking-tight text-white/60 transition-opacity duration-200 group-hover:opacity-0 group-focus:opacity-0">
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
