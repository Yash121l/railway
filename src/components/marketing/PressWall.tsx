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

/** Dark press strip — logos crossfade to their quotes on hover. */
export function PressWall() {
  return (
    <section className="bg-midnight px-4 py-16">
      <div className="mx-auto grid max-w-6xl grid-cols-2 gap-3 md:grid-cols-5">
        {PRESS.map(({ outlet, quote }) => (
          <div
            key={outlet}
            className="group relative flex min-h-[120px] items-center justify-center rounded-2xl bg-white/[0.05] p-5 ring-1 ring-white/[0.08]"
          >
            <span className="text-center text-[15px] font-bold tracking-tight text-white/60 transition-opacity duration-200 group-hover:opacity-0">
              {outlet}
            </span>
            <span className="absolute inset-0 flex items-center justify-center p-4 text-center text-[12px] leading-snug text-white opacity-0 transition-opacity duration-200 group-hover:opacity-100">
              “{quote}”
            </span>
          </div>
        ))}
      </div>
    </section>
  );
}
