"use client";

import { useEffect } from "react";
import Link from "next/link";
import { RotateCcw } from "lucide-react";

/**
 * Root error boundary. The app previously had none, so an unhandled error
 * anywhere showed the framework's default screen.
 *
 * Next 16 names the recovery prop `unstable_retry`, not the `reset` of earlier
 * versions.
 */
export default function Error({
  error,
  unstable_retry,
}: {
  error: Error & { digest?: string };
  unstable_retry: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main className="flex min-h-[70vh] flex-col items-center justify-center px-4 text-center">
      <div className="text-[11px] font-bold uppercase tracking-[1.6px] text-steel">
        Something broke
      </div>
      <h1 className="mt-3 max-w-lg text-[28px] font-bold leading-tight tracking-tight text-black md:text-[34px]">
        That page didn&apos;t load.
      </h1>
      <p className="mt-4 max-w-md text-[15px] leading-relaxed text-carbon">
        This one is on us, not on you. Trying again often works, since most
        failures here are a rail data feed timing out rather than anything
        wrong with your request.
      </p>
      {error.digest && (
        <p className="mt-3 text-[12px] text-steel">
          Reference <span className="tnum font-semibold">{error.digest}</span>
        </p>
      )}
      <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
        <button
          onClick={unstable_retry}
          className="inline-flex items-center gap-2 rounded-full bg-black px-6 py-3 text-[15px] font-semibold text-white transition-transform hover:scale-[1.03] active:scale-95"
        >
          <RotateCcw size={16} />
          Try again
        </button>
        <Link
          href="/"
          className="rounded-full px-5 py-3 text-[15px] font-semibold text-black transition-opacity hover:opacity-70"
        >
          Back to the homepage
        </Link>
      </div>
    </main>
  );
}
