import { TrainFront } from "lucide-react";

/** Live journey progress — orange fill with the train glyph riding the edge. */
export function ProgressBar({
  progress,
  muted = false,
}: {
  /** 0..1 */
  progress: number;
  /** finished journeys render calm, not loud */
  muted?: boolean;
}) {
  const pct = Math.min(100, Math.max(0, progress * 100));
  return (
    <div className="relative h-[3px] w-full rounded-full bg-white/12">
      <div
        className={`h-full rounded-full ${muted ? "bg-white/30" : "bg-flame"}`}
        style={{ width: `${pct}%` }}
      />
      {!muted && (
        <TrainFront
          size={13}
          className="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 text-flame drop-shadow-[0_0_6px_rgba(255,138,61,0.8)]"
          style={{ left: `${pct}%` }}
        />
      )}
    </div>
  );
}
