import { TrainFront } from "lucide-react";

/**
 * The signature floating notification card: white, 20px radius, whisper-thin
 * shadow stack, optional status left-border, scattered at slight tilts.
 * flighty's cards get their life from colorful senders — memoji for people,
 * airline marks for flights. Ours: emoji for people, livery monograms for
 * trains, the black train tile as fallback.
 */
export function NotifCard({
  title,
  body,
  time = "now",
  accent,
  emoji,
  mark,
  markColor = "#C62828",
  tilt = 0,
  className = "",
  drift = false,
}: {
  title: string;
  body: string;
  time?: string;
  /** left border signal: blue action, amber advisory, red alert, green good news */
  accent?: "signal" | "sun" | "crit" | "go";
  /** person sender: an emoji face in a soft circle */
  emoji?: string;
  /** train sender: a two-letter livery monogram (RJ, VB, SH…) */
  mark?: string;
  markColor?: string;
  /** degrees, -3..3 keeps it looking scattered not messy */
  tilt?: number;
  className?: string;
  drift?: boolean;
}) {
  const accentClass =
    accent === "signal"
      ? "border-l-[3px] border-l-signal"
      : accent === "sun"
        ? "border-l-[3px] border-l-sun"
        : accent === "crit"
          ? "border-l-[3px] border-l-crit"
          : accent === "go"
            ? "border-l-[3px] border-l-go"
            : "";

  return (
    <div
      className={`w-full max-w-[290px] rounded-[20px] bg-white p-4 shadow-float ${accentClass} ${
        drift ? "animate-drift motion-reduce:animate-none" : ""
      } ${className}`}
      style={{ "--tilt": `${tilt}deg`, rotate: drift ? undefined : `${tilt}deg` } as React.CSSProperties}
    >
      <div className="flex items-start gap-2.5">
        {emoji ? (
          <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-fill text-[16px]">
            {emoji}
          </span>
        ) : mark ? (
          <span
            className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[10px] font-bold text-white"
            style={{ backgroundColor: markColor }}
          >
            {mark}
          </span>
        ) : (
          <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-[8px] bg-midnight">
            <TrainFront size={15} className="text-white" />
          </span>
        )}
        <div className="min-w-0 flex-1">
          <div className="flex items-baseline justify-between gap-2">
            <span className="truncate text-[15px] font-semibold text-black">
              {title}
            </span>
            <span className="shrink-0 text-[12px] text-steel">{time}</span>
          </div>
          <p className="mt-0.5 text-[13px] leading-snug text-steel">{body}</p>
        </div>
      </div>
    </div>
  );
}
