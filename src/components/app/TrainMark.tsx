import type { TrainCategory } from "@/lib/types";

/** Livery-colored monogram circle — Railly's stand-in for airline logos. */
const LIVERY: Record<TrainCategory, { bg: string; mark: string }> = {
  rajdhani: { bg: "#c62828", mark: "RJ" },
  "vande-bharat": { bg: "#0d47a1", mark: "VB" },
  shatabdi: { bg: "#546e7a", mark: "SH" },
  duronto: { bg: "#2e7d32", mark: "DR" },
  tejas: { bg: "#ef6c00", mark: "TJ" },
  superfast: { bg: "#6a1b9a", mark: "SF" },
  express: { bg: "#37474f", mark: "EX" },
};

export function TrainMark({
  category,
  size = 28,
}: {
  category: TrainCategory;
  size?: number;
}) {
  const livery = LIVERY[category];
  return (
    <span
      className="inline-flex shrink-0 items-center justify-center rounded-full font-bold text-white"
      style={{
        width: size,
        height: size,
        background: livery.bg,
        fontSize: Math.round(size * 0.36),
        letterSpacing: "0.02em",
      }}
      aria-hidden
    >
      {livery.mark}
    </span>
  );
}
