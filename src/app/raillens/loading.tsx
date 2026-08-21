/**
 * Shown while the route is fetched server-side.
 *
 * RailLens makes two sequential erail calls, each with three attempts and a
 * 15s timeout, so a cold miss on a slow upstream can take a long time. Without
 * this the page sat blank with no feedback and nothing to cancel, which reads
 * as broken rather than busy.
 */
export default function Loading() {
  return (
    <div className="flex min-h-[70vh] flex-col items-center justify-center gap-5 px-4 text-center">
      <div className="h-1 w-56 animate-pulse rounded-full bg-signal/40" />
      <div>
        <div className="text-[17px] font-semibold text-black">
          Drawing the route
        </div>
        <p className="mt-1.5 max-w-sm text-[14px] leading-relaxed text-steel">
          Fetching the timetable, then tracing the line over OpenStreetMap rail.
          The first look at a train can take a few seconds.
        </p>
      </div>
    </div>
  );
}
