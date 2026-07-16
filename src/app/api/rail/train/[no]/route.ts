import { fullTrain, RailError } from "@/lib/rail/erail";

/** Full schedules rarely change — cache each train for ~7 days. */
export const revalidate = 604800;

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ no: string }> },
) {
  const { no } = await params;
  if (!/^\d{4,6}$/.test(no)) {
    return Response.json(
      { error: "Train number must be 4–6 digits.", source: "erail" },
      { status: 400 },
    );
  }
  try {
    const train = await fullTrain(no, { revalidate: 604800, tags: [`train:${no}`] });
    return Response.json({
      source: "erail",
      asOf: new Date().toISOString(),
      train,
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
