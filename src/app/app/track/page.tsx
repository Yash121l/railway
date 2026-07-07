import type { Metadata } from "next";
import { TrackBoard } from "@/components/app/TrackBoard";

export const metadata: Metadata = { title: "Track" };

export default function TrackPage() {
  return <TrackBoard />;
}
