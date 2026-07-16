import { trainsBetween, RailError } from "@/lib/rail/erail";

/** Trains-between-stations shifts slowly — cache each pair for ~24 hours. */
export const revalidate = 86400;

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ from: string; to: string }> },
) {
  const p = await params;
  const from = p.from.toUpperCase();
  const to = p.to.toUpperCase();
  if (!/^[A-Z]{2,5}$/.test(from) || !/^[A-Z]{2,5}$/.test(to)) {
    return Response.json(
      { error: "Station codes must be 2–5 letters.", source: "erail" },
      { status: 400 },
    );
  }
  try {
    const trains = await trainsBetween(from, to, {
      revalidate: 86400,
      tags: [`between:${from}:${to}`],
    });
    return Response.json({
      source: "erail",
      asOf: new Date().toISOString(),
      from,
      to,
      count: trains.length,
      trains,
    });
  } catch (e) {
    if (e instanceof RailError) {
      const status = e.kind === "notFound" ? 404 : e.kind === "throttled" ? 503 : 502;
      return Response.json({ error: e.message, source: "erail" }, { status });
    }
    return Response.json(
      { error: "Unexpected error reading the railway feed.", source: "erail" },
      { status: 500 },
    );
  }
}
