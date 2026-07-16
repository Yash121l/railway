import type { MetadataRoute } from "next";
import { PROFILES } from "@/app/compare/page";
import { TRAINS, trainSlug } from "@/app/trains/[slug]/page";

const BASE = "https://railly.app";
const UPDATED = "2026-07-12";

/** Per-route last-modified dates — bump the one line that actually changed. */
const LAST_MODIFIED: Record<string, string> = {
  "": "2026-07-12",
  "/pricing": "2026-07-12",
  "/compare": "2026-07-12",
  "/stations": "2026-07-12",
  "/trains": "2026-07-12",
  "/pnr-status": "2026-07-12",
  "/passport": "2026-07-12",
  "/help": "2026-07-11",
  "/about": "2026-07-12",
  "/gift-cards": "2026-07-11",
  "/press": "2026-07-12",
  "/privacy": "2026-07-11",
  "/terms": "2026-07-11",
};

const GUIDES = [
  "/guides/pnr-status-explained",
  "/guides/tatkal-booking-time",
  "/guides/live-train-running-status",
];

export default function sitemap(): MetadataRoute.Sitemap {
  const routes: [string, MetadataRoute.Sitemap[number]["priority"]][] = [
    ["", 1],
    ["/pricing", 0.8],
    ["/compare", 0.8],
    ["/stations", 0.8],
    ["/pnr-status", 0.7],
    ["/passport", 0.7],
    ["/help", 0.7],
    ["/trains", 0.6],
    ["/about", 0.6],
    ["/gift-cards", 0.5],
    ["/press", 0.4],
    ["/privacy", 0.3],
    ["/terms", 0.3],
  ];

  const staticEntries: MetadataRoute.Sitemap = routes.map(
    ([path, priority]) => ({
      url: `${BASE}${path}`,
      lastModified: LAST_MODIFIED[path] ?? UPDATED,
      changeFrequency: path === "" ? "weekly" : "monthly",
      priority,
    }),
  );

  const guideEntries: MetadataRoute.Sitemap = GUIDES.map((path) => ({
    url: `${BASE}${path}`,
    lastModified: UPDATED,
    changeFrequency: "monthly",
    priority: 0.7,
  }));

  const compareEntries: MetadataRoute.Sitemap = PROFILES.map((p) => ({
    url: `${BASE}/compare/${p.slug}`,
    lastModified: UPDATED,
    changeFrequency: "monthly",
    priority: 0.7,
  }));

  const trainEntries: MetadataRoute.Sitemap = TRAINS.map((t) => ({
    url: `${BASE}/trains/${trainSlug(t)}`,
    lastModified: UPDATED,
    changeFrequency: "monthly",
    priority: 0.6,
  }));

  return [
    ...staticEntries,
    ...guideEntries,
    ...compareEntries,
    ...trainEntries,
  ];
}
