import { pnrStatus, PnrError } from "@/lib/rail/confirmtkt";
import { trainInfo, RailError } from "@/lib/rail/erail";

/** Always a live probe. */
export const dynamic = "force-dynamic";

interface SourceHealth {
  ok: boolean;
  latencyMs: number;
  note?: string;
  error?: string;
}

async function probeErail(): Promise<SourceHealth> {
  const t0 = Date.now();
  try {
    // A known always-running train (Mumbai Rajdhani). Live (uncached) fetch.
    await trainInfo("12951");
    return { ok: true, latencyMs: Date.now() - t0 };
  } catch (e) {
    return {
      ok: false,
      latencyMs: Date.now() - t0,
      error: e instanceof RailError ? e.message : "Unreachable.",
    };
  }
}

async function probeConfirmtkt(): Promise<SourceHealth> {
  const t0 = Date.now();
  try {
    // A syntactically-valid dummy: an "invalid PNR" rejection still proves the
    // service answered, so that counts as healthy/reachable.
    await pnrStatus("0000000000");
    return { ok: true, latencyMs: Date.now() - t0 };
  } catch (e) {
    if (e instanceof PnrError && e.kind === "invalid") {
      return {
        ok: true,
        latencyMs: Date.now() - t0,
        note: "reachable (dummy PNR rejected)",
      };
    }
    return {
      ok: false,
      latencyMs: Date.now() - t0,
      error: e instanceof PnrError ? e.message : "Unreachable.",
    };
  }
}

export async function GET() {
  const [erail, confirmtkt] = await Promise.all([probeErail(), probeConfirmtkt()]);
  const ok = erail.ok && confirmtkt.ok;
  return Response.json(
    { ok, asOf: new Date().toISOString(), sources: { erail, confirmtkt } },
    { status: ok ? 200 : 503 },
  );
}
