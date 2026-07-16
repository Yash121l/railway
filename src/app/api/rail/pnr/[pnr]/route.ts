import { pnrStatus, PnrError } from "@/lib/rail/confirmtkt";

/** Live per-passenger status — never cache; every check hits the upstream. */
export const dynamic = "force-dynamic";

// Basic in-memory per-IP throttle. Caveat: process-local, so it resets on
// redeploy and doesn't coordinate across serverless instances — a durable
// store (KV / Redis) is the production answer.
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 8;
const hits = new Map<string, number[]>();

function rateLimited(ip: string): boolean {
  const now = Date.now();
  const recent = (hits.get(ip) ?? []).filter((t) => now - t < WINDOW_MS);
  recent.push(now);
  hits.set(ip, recent);
  return recent.length > MAX_PER_WINDOW;
}

export async function GET(
  req: Request,
  { params }: { params: Promise<{ pnr: string }> },
) {
  const { pnr } = await params;
  if (!/^\d{10}$/.test(pnr)) {
    return Response.json(
      { error: "PNR must be exactly 10 digits.", source: "confirmtkt" },
      { status: 400 },
    );
  }

  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0].trim() ||
    req.headers.get("x-real-ip") ||
    "unknown";
  if (rateLimited(ip)) {
    return Response.json(
      { error: "Too many PNR checks. Try again in a minute.", source: "confirmtkt" },
      { status: 429 },
    );
  }

  try {
    const ticket = await pnrStatus(pnr);
    return Response.json({
      source: "confirmtkt",
      asOf: new Date().toISOString(),
      ticket,
    });
  } catch (e) {
    if (e instanceof PnrError) {
      const status = e.kind === "invalid" ? 404 : 502;
      return Response.json({ error: e.message, source: "confirmtkt" }, { status });
    }
    return Response.json(
      { error: "Unexpected error checking the PNR.", source: "confirmtkt" },
      { status: 500 },
    );
  }
}
