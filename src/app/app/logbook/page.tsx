import type { Metadata } from "next";
import { Logbook } from "@/components/app/Logbook";

export const metadata: Metadata = { title: "Logbook" };

export default function LogbookPage() {
  return <Logbook />;
}
