import { fullTrain, RailError } from "@/lib/rail/erail";
import { recordDelay } from "@/lib/rail/history";
import { getLiveStatusForRun } from "@/lib/sim";

/**
 * Schedule-projected estimate, refreshed at most once a minute. Honest label:
 * `source: "sim"`. There is no live position feed yet — this projects the real
 * timetable onto "now"; wiring a live key later flips the source to a feed.
 */
export const revalidate = 60;

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ no: string; date: string }> },
) {
  const { no, date } = await params;
  if (!/^\d{4,6}$/.test(no)) {
    return Response.json(
      { error: "Train number must be 4–6 digits.", source: "sim" },
      { status: 400 },
    );
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return Response.json(
      { error: "Date must be YYYY-MM-DD.", source: "sim" },
      { status: 400 },
    );
  }
  try {
    // Schedule cached long; the projection onto "now" is what varies per minute.
    const train = await fullTrain(no, { revalidate: 604800, tags: [`train:${no}`] });
    const now = new Date();
    const status = getLiveStatusForRun(train, date, now);

    const idx = status.atStation ? status.prevStopIdx : status.nextStopIdx;
    const station = train.stops[idx]?.code ?? train.stops[0].code;
    await recordDelay({
      trainNo: no,
      date,
      station,
      delayMin: status.delayMin,
      at: now.toISOString(),
    });

    return Response.json({
      source: "sim",
      asOf: now.toISOString(),
      note: "Schedule-projected estimate, not a live feed. Real-time position needs a live data key.",
      status,
    });
  } catch (e) {
    if (e instanceof RailError) {
      const httpStatus = e.kind === "notFound" ? 404 : e.kind === "throttled" ? 503 : 502;
      return Response.json({ error: e.message, source: "sim" }, { status: httpStatus });
    }
    return Response.json(
      { error: "Unexpected error building the estimate.", source: "sim" },
      { status: 500 },
    );
  }
}
