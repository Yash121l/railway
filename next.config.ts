import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // PostHog reverse proxy: the browser posts to /ingest on our own origin so
  // ad blockers don't drop events. Its API paths use trailing slashes.
  skipTrailingSlashRedirect: true,
  async rewrites() {
    return [
      {
        source: "/ingest/static/:path*",
        destination: "https://us-assets.i.posthog.com/static/:path*",
      },
      {
        source: "/ingest/:path*",
        destination: "https://us.i.posthog.com/:path*",
      },
    ];
  },
};

export default nextConfig;
