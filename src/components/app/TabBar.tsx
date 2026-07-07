"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { BookOpen, Radar, TrainFront } from "lucide-react";

const TABS = [
  { href: "/app", label: "My Trips", icon: TrainFront },
  { href: "/app/track", label: "Track", icon: Radar },
  { href: "/app/logbook", label: "Logbook", icon: BookOpen },
] as const;

export function TabBar() {
  const pathname = usePathname();
  return (
    <nav className="fixed bottom-0 left-1/2 z-40 w-full max-w-[430px] -translate-x-1/2 border-t border-white/[0.08] bg-void/85 pb-[max(env(safe-area-inset-bottom),10px)] pt-2 backdrop-blur-xl">
      <div className="grid grid-cols-3">
        {TABS.map(({ href, label, icon: Icon }) => {
          const active =
            href === "/app" ? pathname === "/app" : pathname.startsWith(href);
          return (
            <Link
              key={href}
              href={href}
              className={`flex flex-col items-center gap-1 py-1 ${
                active ? "text-flame" : "text-white/45"
              }`}
            >
              <Icon size={22} strokeWidth={active ? 2.2 : 1.8} />
              <span className="text-[10px] font-medium">{label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
