import type { Metadata } from "next";
import { TripDetail } from "@/components/app/TripDetail";
import { trainByNumber } from "@/lib/sim";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const { id } = await params;
  const train = trainByNumber(id.split("_")[0]);
  return { title: train ? `${train.number} ${train.name}` : "Trip" };
}

export default async function TripPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <TripDetail id={id} />;
}
