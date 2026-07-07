import { TabBar } from "@/components/app/TabBar";

/**
 * The app renders as a phone-width column on a black backdrop — a bright
 * device on a dark table, the way Flighty's press shots frame it. Screens
 * are white sheets; the map peeks through where a screen wants it.
 */
export default function AppLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <div className="min-h-dvh bg-black">
      <div className="relative mx-auto min-h-dvh w-full max-w-[430px] bg-white text-inkline shadow-[0_0_90px_rgba(0,0,0,0.9)]">
        <main className="min-h-dvh pb-24">{children}</main>
        <TabBar />
      </div>
    </div>
  );
}
