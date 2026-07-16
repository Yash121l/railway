import React from "react";
import { CalendarDays, CloudFog, Mail, Smartphone, Ticket, TrainFront } from "lucide-react";
import { APP_CTA_HREF, APP_CTA_LABEL } from "@/lib/cta";
import { MiniPhone } from "./MidSections";
import { NotifCard } from "./NotifCard";
import { Reveal } from "./Reveal";
import { Starfield } from "./Starfield";

/** Mini "where's my rake" inbound tracker — the bar creeps closer, live */
function InboundRakeCard() {
  return (
    <div className="w-full max-w-[300px] rounded-[20px] bg-white p-4 shadow-float" style={{ rotate: "-2deg" }}>
      <div className="text-[11px] font-bold uppercase tracking-[1px] text-steel">
        Where&apos;s my rake
      </div>
      <div className="mt-2 flex items-center gap-2 text-[15px] font-semibold text-black">
        <TrainFront size={16} className="text-signal" />
        Arriving from Ahmedabad
      </div>
      <div className="relative mt-3 h-[3px] w-full rounded-full bg-black/10">
        <div className="h-full animate-creep rounded-full bg-signal motion-reduce:w-[78%] motion-reduce:animate-none" />
      </div>
      <p className="mt-2 text-[13px] text-steel">
        Running 12m late · your departure impact: <b className="text-black">+9m</b>
      </p>
    </div>
  );
}

function ProDataCard() {
  const cells = [
    ["Platform", "PF 5"],
    ["Coach", "C4 · front"],
    ["Seat", "32A window"],
    ["Exit", "Gate 2"],
  ];
  return (
    <div className="w-full max-w-[300px] rounded-[20px] bg-white p-4 shadow-float" style={{ rotate: "1.5deg" }}>
      <div className="grid grid-cols-2 gap-3">
        {cells.map(([label, value]) => (
          <div key={label}>
            <div className="text-[10px] font-bold uppercase tracking-[1px] text-fog">
              {label}
            </div>
            <div className="mt-0.5 text-[17px] font-bold text-black">{value}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

/**
 * The night card's "hero photo": a WAP-7 electric loco hauling LHB stock,
 * drawn to profile — pantograph on the contact wire, Co-Co bogies under the
 * loco, FIAT twin-axle bogies under the coaches, window bands, end doors.
 */
function RakeSilhouette() {
  const locoWheels = [26, 42, 58, 78, 94, 110]; // two Co-Co bogies
  const coachAWheels = [148, 164, 216, 232];
  const coachBWheels = [262, 278, 330, 346];
  return (
    <svg viewBox="0 0 360 92" className="w-full" aria-hidden>
      {/* overhead contact wire */}
      <line x1="0" y1="9" x2="360" y2="9" stroke="#4b5680" strokeWidth="1.2" />
      {/* pantograph, knee raised to the wire */}
      <g stroke="#9aa4c6" strokeWidth="2" strokeLinecap="round" fill="none">
        <path d="M52 26 L66 14 L82 12" />
        <path d="M82 12 L74 26" />
        <line x1="74" y1="12" x2="90" y2="12" />
      </g>
      <rect x="60" y="24" width="18" height="3" rx="1.5" fill="#39435c" />

      {/* WAP-7 body: twin-cab box with gently slanted noses */}
      <path
        d="M14 66 L14 38 Q14 32 19 30 L26 27.5 Q30 26 36 26 L100 26 Q106 26 110 27.5 L117 30 Q122 32 122 38 L122 66 Z"
        fill="#dfe4ee"
      />
      {/* cab windshields */}
      <path d="M20 31.5 L32 29 L32 38 L20 38 Z" fill="#151b30" />
      <path d="M116 31.5 L104 29 L104 38 L116 38 Z" fill="#151b30" />
      {/* louvre grilles + body stripe */}
      {[42, 60, 78].map((x) => (
        <g key={x} fill="#28304d">
          <rect x={x} y="31" width="12" height="2" rx="1" />
          <rect x={x} y="35" width="12" height="2" rx="1" />
          <rect x={x} y="39" width="12" height="2" rx="1" />
        </g>
      ))}
      <rect x="14" y="47" width="108" height="5" fill="#28304d" opacity="0.8" />
      {/* headlight + buffers */}
      <circle cx="17.5" cy="34" r="2.6" fill="#f6c445" />
      <circle cx="17.5" cy="34" r="5.5" fill="#f6c445" opacity="0.22" />
      <rect x="8" y="56" width="6" height="4" rx="1.5" fill="#39435c" />
      {/* loco bogie frames + Co-Co wheels */}
      <rect x="18" y="62" width="50" height="8" rx="3" fill="#232c49" />
      <rect x="70" y="62" width="50" height="8" rx="3" fill="#232c49" />
      {locoWheels.map((x) => (
        <g key={x}>
          <circle cx={x} cy="72" r="6" fill="#4a5572" />
          <circle cx={x} cy="72" r="2.2" fill="#161d33" />
        </g>
      ))}

      {/* two LHB coaches (third implied off-frame) */}
      {[
        { x: 130, wheels: coachAWheels },
        { x: 244, wheels: coachBWheels },
      ].map(({ x, wheels }) => (
        <g key={x}>
          {/* coupler */}
          <rect x={x - 8} y="50" width="8" height="3" fill="#39435c" />
          {/* shell with rounded LHB ends */}
          <rect x={x} y="28" width="110" height="36" rx="9" fill="#e6eaf3" />
          {/* roofline */}
          <rect x={x + 4} y="28" width="102" height="4" rx="2" fill="#c4cbdd" />
          {/* end doors */}
          <rect x={x + 5} y="36" width="7" height="24" rx="2" fill="#28304d" />
          <rect x={x + 98} y="36" width="7" height="24" rx="2" fill="#28304d" />
          {/* window band */}
          {[18, 32, 46, 60, 74].map((wx) => (
            <rect
              key={wx}
              x={x + wx}
              y="36"
              width="10"
              height="9"
              rx="2"
              fill="#151b30"
            />
          ))}
          {/* skirt + FIAT bogies */}
          <rect x={x + 4} y="60" width="102" height="3" fill="#b9c1d6" />
          <rect x={x + 12} y="64" width="34" height="6" rx="3" fill="#232c49" />
          <rect x={x + 80} y="64" width="34" height="6" rx="3" fill="#232c49" />
          {wheels.map((wx) => (
            <g key={wx}>
              <circle cx={wx} cy="72" r="5.2" fill="#4a5572" />
              <circle cx={wx} cy="72" r="1.9" fill="#161d33" />
            </g>
          ))}
        </g>
      ))}

      {/* rail + sleepers */}
      <line x1="0" y1="79" x2="360" y2="79" stroke="#4b5680" strokeWidth="2" />
      {Array.from({ length: 19 }, (_, i) => 8 + i * 19).map((x) => (
        <rect key={x} x={x} y="82" width="9" height="2.5" rx="1" fill="#333d5e" />
      ))}
    </svg>
  );
}

/**
 * Signal gantry against the dusk — a proper lattice structure: X-braced
 * masts and boom, drop posts, hooded three-aspect color-light heads with a
 * ladder up the near mast. Pure silhouette; only the lit aspects glow.
 */
function GantrySilhouette() {
  const ink = "#150a2e";
  // one three-aspect head: backplate, hoods, lamps (top→bottom G/Y/R)
  const head = (cx: number, lit: "green" | "amber") => {
    const lamps: [number, string, boolean][] = [
      [64, "#30d158", lit === "green"],
      [80, "#f6c445", lit === "amber"],
      [96, "#ff5449", false],
    ];
    return (
      <g key={cx}>
        {/* drop post from the boom */}
        <rect x={cx - 2} y="34" width="4" height="16" fill={ink} />
        {/* backplate */}
        <rect x={cx - 14} y="50" width="28" height="58" rx="11" fill={ink} />
        {lamps.map(([cy, color, isLit]) => (
          <g key={cy}>
            {/* visor hood over each lamp */}
            <path
              d={`M ${cx - 8} ${cy - 5} Q ${cx} ${cy - 11} ${cx + 8} ${cy - 5}`}
              fill="none"
              stroke="#241448"
              strokeWidth="2.5"
            />
            {isLit ? (
              <>
                <circle cx={cx} cy={cy} r="10" fill={color} opacity="0.18" />
                <circle cx={cx} cy={cy} r="5.5" fill={color} />
              </>
            ) : (
              <circle cx={cx} cy={cy} r="5.5" fill="#0b0620" />
            )}
          </g>
        ))}
        {/* number plate */}
        <rect x={cx - 6} y="110" width="12" height="7" rx="1.5" fill={ink} />
      </g>
    );
  };

  return (
    <svg viewBox="0 0 360 150" className="w-full" aria-hidden>
      {/* masts with internal X-bracing */}
      {[34, 314].map((x) => (
        <g key={x}>
          <rect x={x} y="8" width="3" height="142" fill={ink} />
          <rect x={x + 11} y="8" width="3" height="142" fill={ink} />
          {Array.from({ length: 7 }, (_, i) => 14 + i * 19).map((y, i) => (
            <line
              key={y}
              x1={i % 2 ? x + 14 : x}
              y1={y}
              x2={i % 2 ? x : x + 14}
              y2={y + 19}
              stroke={ink}
              strokeWidth="2"
            />
          ))}
          {/* base plinth */}
          <rect x={x - 4} y="144" width="22" height="6" rx="1" fill={ink} />
        </g>
      ))}

      {/* boom: top + bottom chords with lattice diagonals */}
      <rect x="34" y="14" width="283" height="3.5" fill={ink} />
      <rect x="34" y="32" width="283" height="3.5" fill={ink} />
      {Array.from({ length: 12 }, (_, i) => 40 + i * 23).map((x, i) => (
        <line
          key={x}
          x1={x}
          y1={i % 2 ? 17 : 33}
          x2={x + 23}
          y2={i % 2 ? 33 : 17}
          stroke={ink}
          strokeWidth="2"
        />
      ))}

      {/* ladder up the near mast */}
      <g stroke={ink} strokeWidth="1.6">
        <line x1="52" y1="40" x2="52" y2="146" />
        <line x1="60" y1="40" x2="60" y2="146" />
        {Array.from({ length: 13 }, (_, i) => 44 + i * 8).map((y) => (
          <line key={y} x1="52" y1={y} x2="60" y2={y} />
        ))}
      </g>

      {head(128, "green")}
      {head(232, "amber")}
    </svg>
  );
}

/**
 * flighty opens its feature run with a huge dark card: copy on the left,
 * the real product cropped at the card edge on the right. Same here —
 * the screenshot is our actual trip-detail screen, with the live
 * inbound-rake card floating over it.
 */
function DarkIntroCard() {
  return (
    <Reveal from="zoom">
      <div
        id="before-you-board"
        className="relative scroll-mt-28 overflow-hidden rounded-3xl bg-gradient-to-b from-[#161028] to-[#0b081a] ring-1 ring-white/[0.06]"
      >
        <Starfield className="opacity-40" />
        <div className="relative grid items-center md:grid-cols-2">
          <div className="p-8 md:p-12">
            <h3 className="text-[26px] font-bold leading-tight tracking-tight text-white md:text-[30px]">
              See why you&apos;re delayed. Finally!
            </h3>
            <p className="mt-4 max-w-md text-[15px] leading-relaxed text-white/65">
              Railways often keep delay information under wraps until the last
              minute. Railly doesn&apos;t. We track your inbound rake 24 hours
              before departure, so we can predict a new time long before the
              announcement crackles over the PA.
            </p>
          </div>
          <div className="relative h-[340px] md:h-[430px]">
            <div className="absolute left-1/2 top-10 -translate-x-1/2 rotate-[4deg] md:left-auto md:right-14 md:translate-x-0">
              <MiniPhone
                src="/screens/trip-detail.png"
                alt="Railly trip detail with delay prediction and live map"
              />
            </div>
            <div className="absolute bottom-8 left-4 w-[300px] md:left-10" style={{ rotate: "-3deg" }}>
              <InboundRakeCard />
            </div>
          </div>
        </div>
      </div>
    </Reveal>
  );
}

/** IRCTC-true availability strings, color-coded the way the app renders
    them — green means book now, amber means it'll clear, red means fight. */
function AvailabilityStripCard() {
  const rows: [string, string, string, string][] = [
    ["Tomorrow", "Sat 11 Jul", "GNWL21/WL9", "text-[#ff8d7f]"],
    ["Sun 12 Jul", "", "RAC 12", "text-sun"],
    ["Mon 13 Jul", "", "AVAILABLE-0042", "text-go"],
    ["Tue 14 Jul", "", "AVAILABLE-0113", "text-go"],
  ];
  return (
    <div className="w-full rounded-2xl bg-white/[0.06] p-5 ring-1 ring-white/[0.08]">
      <div className="flex items-center justify-between">
        <span className="text-[13px] font-bold text-white">
          12951 Mumbai Rajdhani
        </span>
        <span className="flex gap-1.5">
          {["SL", "3A", "2A"].map((c) => (
            <span
              key={c}
              className={`rounded-md px-2 py-1 text-[11px] font-bold ${
                c === "3A"
                  ? "bg-white text-black"
                  : "bg-white/[0.08] text-white/60"
              }`}
            >
              {c}
            </span>
          ))}
        </span>
      </div>
      <div className="mt-4 space-y-2.5">
        {rows.map(([day, sub, status, tone]) => (
          <div
            key={day}
            className="flex items-center justify-between border-b border-white/[0.07] pb-2.5 last:border-0 last:pb-0"
          >
            <span className="text-[13px] font-semibold text-white">
              {day}
              {sub && (
                <span className="ml-2 font-normal text-white/45">{sub}</span>
              )}
            </span>
            <span className={`tnum text-[13px] font-bold ${tone}`}>
              {status}
            </span>
          </div>
        ))}
      </div>
      <div className="mt-4 border-t border-white/10 pt-3 text-[12px] text-white/50">
        Tatkal opens 10:00 AM the day before — Railly pings you at 9:55.
      </div>
    </div>
  );
}

/** The India-first pair: the PNR question and the seat question. */
function DarkBookingPair() {
  return (
    <div id="before-you-book" className="grid scroll-mt-28 gap-4 md:grid-cols-2">
      <Reveal from="left" className="h-full">
        <div className="card-lift relative flex h-full flex-col overflow-hidden rounded-3xl bg-white/[0.04] p-7 ring-1 ring-white/[0.06]">
          <h3 className="text-[22px] font-bold leading-snug tracking-tight text-white">
            Your PNR, decoded.{" "}
            <span className="text-white/60">And watched.</span>
          </h3>
          <p className="mt-3 text-[14px] leading-relaxed text-white/60">
            Ten digits in, the whole booking out: every passenger&apos;s
            GNWL → RAC → CNF ladder, chart timing, and the coach and berth
            the moment they&apos;re assigned. One tap imports the trip.
          </p>
          <div className="relative mt-8 h-[320px] flex-1">
            <div className="absolute left-1/2 top-0 -translate-x-1/2 rotate-[2deg]">
              <MiniPhone
                src="/screens/pnr.png"
                alt="Railly PNR status: all passengers confirmed, berth ladder and coach position"
              />
            </div>
            <div className="pointer-events-none absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t from-[#0d0a1c] to-transparent" />
          </div>
        </div>
      </Reveal>

      <Reveal from="right" delay={90} className="h-full">
        <div className="card-lift relative flex h-full flex-col overflow-hidden rounded-3xl bg-white/[0.04] p-7 ring-1 ring-white/[0.06]">
          <h3 className="text-[22px] font-bold leading-snug tracking-tight text-white">
            Seven days of seats.{" "}
            <span className="text-white/60">At a glance.</span>
          </h3>
          <p className="mt-3 text-[14px] leading-relaxed text-white/60">
            Every class, every quota, every run date — with the PRS strings
            you already know how to read, colored so the bookable days jump
            out before the WL grows.
          </p>
          <div className="mt-8 flex flex-1 items-center justify-center pb-2">
            <AvailabilityStripCard />
          </div>
        </div>
      </Reveal>
    </div>
  );
}

/** The two flighty-style graphic cards: night sky + dusk control room. */
function DarkFeaturePair() {
  return (
    <div id="on-the-platform" className="grid scroll-mt-28 gap-4 md:grid-cols-2">
      <Reveal from="left" className="h-full">
        <div className="night-sky card-lift relative h-full overflow-hidden rounded-3xl p-7 ring-1 ring-white/[0.06]">
          <Starfield className="opacity-80" />
          <div className="relative flex h-full flex-col">
            <h3 className="text-[22px] font-bold leading-snug tracking-tight text-white">
              Delay predictions.{" "}
              <span className="text-white/60">
                Long before the railway admits it.
              </span>
            </h3>
            <p className="mt-3 text-[14px] leading-relaxed text-white/60">
              Late rakes are the #1 cause of delays. Railly uses machine
              learning to predict them — up to 6 hours before the railway says
              anything.
            </p>
            <div className="mt-6 rounded-2xl bg-white/[0.06] p-5 ring-1 ring-white/[0.08]">
              <div className="text-[17px] font-bold text-white">
                Where&apos;s My Rake?
              </div>
              <div className="mt-0.5 text-[12px] text-white/50">
                WAP-7 hauled · 22 LHB coaches · inbound from Ahmedabad
              </div>
              <div className="mt-5">
                <RakeSilhouette />
              </div>
              <span className="mt-4 inline-block rounded-md bg-crit px-2.5 py-1 text-[11px] font-bold uppercase tracking-[0.5px] text-white">
                ⚠ Running late
              </span>
              <div className="mt-2 text-[13px] font-medium text-white/85">
                40m delay predicted due to the late arriving rake
              </div>
              <div className="mt-4 space-y-2.5 border-t border-white/10 pt-3">
                <div className="flex items-center justify-between text-[13px]">
                  <span className="font-semibold text-white">My Train</span>
                  <span className="font-semibold text-[#e58fff]">
                    ✦ 40m Delay Predicted
                  </span>
                </div>
                <div className="flex items-center justify-between text-[13px]">
                  <span className="text-white/55">
                    Ahmedabad to Mumbai · arriving in 1h 10m
                  </span>
                  <span className="font-semibold text-[#ff7b6e]">
                    52m Late
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Reveal>

      <Reveal from="right" delay={90} className="h-full">
        <div className="dusk-sky card-lift relative h-full overflow-hidden rounded-3xl p-7 ring-1 ring-white/[0.06]">
          <div className="relative flex h-full flex-col">
            <h3 className="text-[22px] font-bold leading-snug tracking-tight text-white">
              Direct from the control room.{" "}
              <span className="text-white/70">
                Section mandates are the #2 cause of delays.
              </span>
            </h3>
            <p className="mt-3 text-[14px] leading-relaxed text-white/70">
              Railly sifts through control-room bulletins and tells you what
              might impact your train: fog blocks, crossings, line works, yard
              congestion.
            </p>
            <div className="mt-auto pt-6">
              <GantrySilhouette />
              <div className="-mt-3 overflow-hidden rounded-2xl bg-[#170d2c]/90 ring-1 ring-white/[0.09] backdrop-blur">
                <div className="flex items-center justify-between border-b border-white/[0.08] px-4 py-2.5">
                  <span className="text-[13px] font-bold text-white">
                    Itarsi Section
                  </span>
                  <span className="text-[12px] font-semibold text-[#ff8d7f]">
                    ⌁ 40m delays
                  </span>
                </div>
                <div className="space-y-3 px-4 py-3.5">
                  <div className="flex gap-2.5">
                    <span className="mt-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-crit/25 text-[11px] text-[#ff8d7f]">
                      !
                    </span>
                    <div>
                      <div className="text-[13px] font-semibold text-[#ff8d7f]">
                        Trains through Itarsi held
                      </div>
                      <div className="mt-0.5 text-[12px] leading-snug text-white/60">
                        Fog speed restrictions for the next 40 min (not this
                        train currently). Probability of extension is 30–60%.
                      </div>
                    </div>
                  </div>
                  <div className="flex gap-2.5">
                    <CloudFog size={16} className="mt-0.5 text-white/50" />
                    <div>
                      <div className="text-[13px] font-semibold text-white">
                        Dense fog
                      </div>
                      <div className="mt-0.5 text-[12px] text-white/60">
                        Advisory from section control
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Reveal>
    </div>
  );
}

/** The second dark pair: instant alerts + the pro-data card. */
function DarkFeatureSecondPair() {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      <Reveal from="left" className="h-full">
        <div className="card-lift relative flex h-full flex-col overflow-hidden rounded-3xl bg-white/[0.04] p-7 ring-1 ring-white/[0.06]">
          <h3 className="text-[22px] font-bold leading-snug tracking-tight text-white">
            First to know.{" "}
            <span className="text-white/60">First to go.</span>
          </h3>
          <p className="mt-3 text-[14px] leading-relaxed text-white/60">
            Hear about delays and platform changes before anyone else, even the
            announcer. Railly&apos;s alerts are instant, clear, and unfiltered,
            giving you the earliest heads-up to replan and skip the scrum on the
            footbridge.
          </p>
          <div className="mt-8 flex flex-1 flex-col items-center justify-center gap-4 pb-2">
            <NotifCard
              title="Platform changed at Kota"
              body="PF 1 → PF 3 · announced 38 min before arrival."
              time="4:12"
              accent="crit"
              tilt={-2}
            />
            <NotifCard
              title="Boarding now"
              body="Your coach C4 stops near the PF 3 stairs."
              time="4:48"
              accent="signal"
              tilt={2}
            />
          </div>
        </div>
      </Reveal>

      <Reveal from="right" delay={90} className="h-full">
        <div
          className="card-lift relative flex h-full flex-col overflow-hidden rounded-3xl bg-white/[0.04] p-7 ring-1 ring-white/[0.06]"
        >
          <h3 className="text-[22px] font-bold leading-snug tracking-tight text-white">
            Putting the &lsquo;Pro&rsquo; in{" "}
            <span className="text-white/60">approachable.</span>
          </h3>
          <p className="mt-3 text-[14px] leading-relaxed text-white/60">
            Powerful, loco-grade data that you can actually understand.
            Platform, coach position, seat, PNR and exit gate — all at a
            glance. Never stop and stare at a departure board again.
          </p>
          <div className="mt-8 flex flex-1 items-center justify-center pb-2">
            <ProDataCard />
          </div>
        </div>
      </Reveal>
    </div>
  );
}

/** flighty closes the dark band with the import card and its white pill CTA. */
function ImportCard() {
  return (
    <Reveal from="zoom">
      <div className="relative overflow-hidden rounded-3xl bg-white/[0.04] px-6 py-14 text-center ring-1 ring-white/[0.06]">
        <Starfield className="opacity-30" />
        <div className="relative mx-auto max-w-2xl">
          <h3 className="text-[28px] font-bold tracking-tight text-white md:text-[32px]">
            Add your trips in seconds.
          </h3>
          <p className="mt-4 text-[16px] leading-relaxed text-white/60">
            You can magically (read: extremely quickly) make your journeys
            appear on Railly from your PNR, calendar, or email. Get up &amp;
            running faster than you can say, &ldquo;have a nice journey&rdquo;.
          </p>
          <div className="mt-7 flex items-center justify-center gap-3">
            {[Ticket, CalendarDays, Mail].map((Icon, i) => (
              <span
                key={i}
                className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/[0.08] ring-1 ring-white/[0.1]"
              >
                <Icon size={19} className="text-white/80" />
              </span>
            ))}
          </div>
          <p className="mt-4 text-[13px] text-white/45">
            PNR import works today; calendar and email import are on the roadmap.
          </p>
          <a
            href={APP_CTA_HREF}
            className="mt-9 inline-flex items-center gap-2 rounded-full bg-white px-7 py-3.5 text-[15px] font-semibold text-black transition-transform hover:scale-[1.03] active:scale-95"
          >
            {APP_CTA_LABEL}
            <Smartphone size={16} />
          </a>
        </div>
      </div>
    </Reveal>
  );
}

/**
 * flighty.com's feature run lives INSIDE the same near-black band as the
 * press wall — one continuous dark stretch from the hero handoff to the
 * white Friends section. White 56px H2, six dark cards, import CTA last.
 */
export function FeatureJourney() {
  return (
    // generous top padding: the hero phone bleeds ~9rem into this dark band
    <section id="features" className="relative bg-ink px-4 pb-24 pt-44 md:pb-32 md:pt-64">
      <div className="mx-auto max-w-6xl">
        <Reveal className="mx-auto max-w-3xl text-center">
          <h2 className="text-[34px] font-bold leading-[1.05] tracking-[-0.5px] text-white md:text-[54px] md:leading-[1.02]">
            Everything you&apos;ve ever wanted to know about your train—and more.
          </h2>
          <p className="mt-5 text-[18px] leading-relaxed text-white/65">
            Railly keeps you informed by tracking more information about your train
            than any other app—like the #1 and #2 biggest causes of delays. Know
            exactly what&apos;s happening and how it affects your journey, so you can
            finally just enjoy the ride.
          </p>
          <div className="mt-7 inline-flex gap-2 rounded-full bg-white/[0.06] p-1.5 ring-1 ring-white/[0.08]">
            {[
              ["Before you book", "#before-you-book"],
              ["Before you board", "#before-you-board"],
              ["On the platform", "#on-the-platform"],
              ["After arrival", "#passport"],
            ].map(([label, href]) => (
              <a
                key={href}
                href={href}
                className="rounded-full px-4 py-2 text-[14px] font-semibold text-white/85 transition-colors hover:bg-white/10 hover:text-white"
              >
                {label}
              </a>
            ))}
          </div>
        </Reveal>

        <div className="mt-20 space-y-4">
          {/* flighty's dark-card run, in journey order: the booking pair, then
              the big intro card, then the platform pairs */}
          <DarkBookingPair />
          <DarkIntroCard />
          <DarkFeaturePair />
          <DarkFeatureSecondPair />
          <ImportCard />
        </div>
      </div>
    </section>
  );
}
