import type { StatusTone } from "@/lib/types";

const TONE_CLASSES: Record<StatusTone, string> = {
  go: "text-go bg-go/15",
  sun: "text-sun bg-sun/15",
  crit: "text-late bg-late/15",
  signal: "text-[#4da3ff] bg-signal/15",
  steel: "text-[#9aa4af] bg-white/10",
};

export function StatusPill({ tone, text }: { tone: StatusTone; text: string }) {
  return (
    <span
      className={`inline-flex h-[22px] shrink-0 items-center rounded-full px-2.5 text-[11px] font-semibold uppercase tracking-[0.5px] ${TONE_CLASSES[tone]}`}
    >
      {text}
    </span>
  );
}
