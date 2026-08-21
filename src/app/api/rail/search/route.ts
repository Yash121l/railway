import { searchTrains } from "@/lib/catalog";

/**
 * Train lookup against the bundled offline index. Server-side so the 4,022-
 * train / 9,109-code catalog never ships to the browser — RailLens's
 * search box would otherwise pull ~365 KB of JSON into the map bundle.
 *
 * The index is static, so any answer is cacheable indefinitely.
 */
export const revalidate = 604800;

const MAX_LIMIT = 25;

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const q = (searchParams.get("q") ?? "").trim();
  const limitRaw = Number(searchParams.get("limit"));
  const limit =
    Number.isInteger(limitRaw) && limitRaw > 0 ? Math.min(limitRaw, MAX_LIMIT) : 10;

  if (q.length < 2) {
    return Response.json({ source: "catalog", query: q, results: [] });
  }

  const results = searchTrains(q, limit).map((t) => ({
    number: t.number,
    name: t.name,
    category: t.category,
  }));

  return Response.json(
    { source: "catalog", query: q, results },
    { headers: { "Cache-Control": "public, max-age=3600, s-maxage=604800" } },
  );
}
