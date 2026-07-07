import { TabBar } from "@/components/app/TabBar";

/**
 * The app renders as a phone-width column — Railly is a handset experience,
 * shown on desktop the way Flighty's press shots show it: one bright device
 * on a dark table.
 */
export default function AppLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <div className="min-h-dvh bg-[#04060a]">
      <div className="relative mx-auto min-h-dvh w-full max-w-[430px] bg-void text-[#f2f4f7] shadow-[0_0_90px_rgba(0,0,0,0.85)]">
        <main className="pb-28">{children}</main>
        <TabBar />
      </div>
    </div>
  );
}
