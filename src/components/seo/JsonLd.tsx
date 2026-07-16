/**
 * Renders a structured-data payload as a native <script type="application/ld+json">.
 * Following Next.js's blessed pattern, the JSON is serialized and every "<" is
 * escaped to its unicode form so a hostile string can never break out of the
 * script context (XSS-safe). JSON-LD is data, not executable code, so a plain
 * <script> — not next/script — is the right tag.
 */
export function JsonLd({ data }: { data: Record<string, unknown> }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{
        __html: JSON.stringify(data).replace(/</g, "\\u003c"),
      }}
    />
  );
}
