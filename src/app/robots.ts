import type { MetadataRoute } from "next";

/*
 * Pre-launch, everything is welcome — search engines and AI crawlers alike.
 * The AI bots are listed explicitly (rather than folded into the "*" rule)
 * so a future "let's block the AI crawlers" edit has to make a deliberate,
 * per-bot decision instead of flipping one wildcard.
 */
const AI_CRAWLERS = [
  "GPTBot",
  "OAI-SearchBot",
  "ChatGPT-User",
  "ClaudeBot",
  "Claude-SearchBot",
  "Claude-User",
  "PerplexityBot",
  "Perplexity-User",
  "Google-Extended",
  "Bingbot",
  "DuckAssistBot",
  "Applebot",
  "Applebot-Extended",
  "CCBot",
  "meta-externalagent",
];

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      ...AI_CRAWLERS.map((userAgent) => ({ userAgent, allow: "/" })),
      { userAgent: "*", allow: "/" },
    ],
    sitemap: "https://railly.app/sitemap.xml",
    host: "https://railly.app",
  };
}
