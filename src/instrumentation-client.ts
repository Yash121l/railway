import posthog from "posthog-js";
import { APP_CTA_HREF } from "@/lib/cta";

// PostHog product analytics. The key only exists in production builds
// (.env.production), and local runs are skipped so dev traffic never lands in
// the shared project. Events go through the /ingest rewrite in next.config.ts.
const key = process.env.NEXT_PUBLIC_POSTHOG_KEY;
const isLocal = ["localhost", "127.0.0.1", "[::1]"].includes(window.location.hostname);

if (key && !isLocal) {
  try {
    posthog.init(key, {
      api_host: "/ingest",
      ui_host: "https://us.posthog.com",
      defaults: "2026-08-30",
      capture_pageview: "history_change",
      capture_pageleave: true,
      autocapture: true,
      enable_heatmaps: true,
      capture_dead_clicks: true,
      capture_exceptions: true,
      capture_performance: { web_vitals: true },
      session_recording: { maskAllInputs: true },
    });
    posthog.register({ app: "railway" });

    // Every "get the app" button points at the one waitlist mailto in
    // lib/cta.ts, so one delegated listener covers them all.
    document.addEventListener(
      "click",
      (e) => {
        const link = (e.target as Element | null)?.closest?.("a");
        if (link?.getAttribute("href") === APP_CTA_HREF) {
          posthog.capture("waitlist_cta_clicked", { path: window.location.pathname });
        }
      },
      { capture: true },
    );
  } catch {
    // Analytics must never break the site.
  }
}
