import { cache } from "react";
import type { Metadata } from "next";
import { JsonLd } from "@/components/seo/JsonLd";
import { Nav } from "@/components/marketing/Nav";
import { buildLensRoute, type LensRoute } from "@/lib/raillens";
import { fullTrain, RailError } from "@/lib/rail/erail";
import { fmtDuration } from "@/lib/time";
import { RailLensShell } from "./RailLensShell";

/**
 * RailLens — a train's real route drawn over the OpenStreetMap rail network.
 *
 * `/raillens?train=01435` is the addressable unit: one train, one map. The
 * schedule (halts, times, kilometre marks) comes from erail server-side and
 * is cached for a week, so the browser only ever receives the finished view
 * model plus the map bundle.
 */

/** Schedules shift slowly; a week of caching keeps the feed unbothered. */
const ROUTE_TTL = 604800;

export interface LensResult {
  route: LensRoute | null;
  error: string | null;
  requested: string | null;
}

/**
 * Deduped across `generateMetadata` and the page render — React's cache means
 * one request, not two, per visit.
 */
const loadRoute = cache(async (raw: string | null): Promise<LensResult> => {
  if (raw === null) return { route: null, error: null, requested: null };

  const requested = raw.trim();
  if (!/^\d{4,6}$/.test(requested)) {
    return {
      route: null,
      requested,
      error: "Train numbers are 4–6 digits — check the number and try again.",
    };
  }

  try {
    const train = await fullTrain(requested, {
      revalidate: ROUTE_TTL,
      tags: [`train:${requested}`],
    });
    return { route: buildLensRoute(train), error: null, requested };
  } catch (e) {
    // Show the service's own error, never a stand-in.
    return {
      route: null,
      requested,
      error:
        e instanceof RailError
          ? e.message
          : "Couldn't reach the railway data feed just now.",
    };
  }
});

/** The `train` search param, normalised — the first value wins if repeated. */
function readTrainParam(value: string | string[] | undefined): string | null {
  if (value === undefined) return null;
  const first = Array.isArray(value) ? value[0] : value;
  const trimmed = (first ?? "").trim();
  return trimmed === "" ? null : trimmed;
}

interface PageProps {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

export async function generateMetadata({ searchParams }: PageProps): Promise<Metadata> {
  const { route, requested } = await loadRoute(
    readTrainParam((await searchParams).train),
  );

  if (!route) {
    return {
      title: "RailLens — the Indian Railways network, mapped",
      description:
        "Draw any Indian Railways service on an interactive map: every halt, arrival time and kilometre mark, over the real OpenStreetMap rail network.",
      alternates: { canonical: "/raillens" },
      openGraph: {
        title: "RailLens — the Indian Railways network, mapped",
        description:
          "Draw any Indian Railways service on an interactive map — every halt, arrival time and kilometre mark.",
        url: "/raillens",
      },
    };
  }

  const title = `${route.name} (${route.number}) route map`;
  const description = `${route.origin.name} → ${route.destination.name} — ${route.stops.length} halts over ${route.distanceKm} km, ${fmtDuration(route.durationMin)}. Departs ${route.origin.departure} IST. Mapped halt by halt on RailLens.`;

  return {
    title,
    description,
    alternates: { canonical: `/raillens?train=${requested}` },
    openGraph: { title, description, url: `/raillens?train=${requested}` },
    twitter: { title, description },
  };
}

function structuredData(route: LensRoute) {
  return {
    "@context": "https://schema.org",
    "@type": "TrainTrip",
    trainNumber: route.number,
    trainName: route.name,
    departureStation: {
      "@type": "TrainStation",
      name: route.origin.name,
      identifier: route.origin.code,
    },
    arrivalStation: {
      "@type": "TrainStation",
      name: route.destination.name,
      identifier: route.destination.code,
    },
    departureTime: route.origin.departure,
    arrivalTime: route.destination.arrival,
    provider: { "@type": "Organization", "@id": "https://railly.app/#org" },
  };
}

export default async function RailLensPage({ searchParams }: PageProps) {
  const { route, error, requested } = await loadRoute(
    readTrainParam((await searchParams).train),
  );

  return (
    <div className="flex h-dvh flex-col overflow-hidden bg-white">
      {route && <JsonLd data={structuredData(route)} />}
      <Nav />
      <main id="main-content" className="flex min-h-0 flex-1 flex-col">
        {/* The page's real heading lives in the panel; this keeps the document
            outline correct for screen readers when the map is the whole view. */}
        <h1 className="sr-only">
          {route
            ? `RailLens — ${route.name} (${route.number}) route map`
            : "RailLens — interactive map of the Indian Railways network"}
        </h1>
        <RailLensShell route={route} error={error} requested={requested} />
      </main>
    </div>
  );
}
