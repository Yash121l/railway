import type { Metadata } from "next";
import { MyTrips } from "@/components/app/MyTrips";

export const metadata: Metadata = { title: "My Trips" };

export default function AppHome() {
  return <MyTrips />;
}
