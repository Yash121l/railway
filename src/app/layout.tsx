import type { Metadata, Viewport } from "next";
import { JsonLd } from "@/components/seo/JsonLd";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://railly.app"),
  title: {
    default: "Railly — Get the truth when you take the train",
    template: "%s — Railly",
  },
  description:
    "The Flighty of Indian Railways, built for iPhone. Your trips on a satellite globe, a real PNR check, your coach on the platform, and a Passport of every kilometre. 4,022 trains, 9,109 station codes, works offline.",
  applicationName: "Railly",
  openGraph: {
    siteName: "Railly",
    type: "website",
    locale: "en_IN",
    title: "Railly — Get the truth when you take the train",
    description:
      "The Flighty of Indian Railways — built for iPhone. Track any train, check a real PNR, and find your coach on the platform.",
  },
  twitter: {
    card: "summary_large_image",
    title: "Railly — Get the truth when you take the train",
    description:
      "The Flighty of Indian Railways — built for iPhone. Track any train, check a real PNR, and find your coach on the platform.",
  },
};

export const viewport: Viewport = {
  themeColor: "#0d0021",
};

const ORG_JSON_LD = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://railly.app/#org",
      name: "Railly",
      url: "https://railly.app",
      logo: "https://railly.app/logo.svg",
      email: "hello@railly.app",
      description:
        "Railly is an independent train-tracking app for Indian Railways, built for iPhone. Railly is not affiliated with, endorsed by, or operated by Indian Railways or IRCTC.",
    },
    {
      "@type": "WebSite",
      "@id": "https://railly.app/#website",
      url: "https://railly.app",
      name: "Railly",
      publisher: { "@id": "https://railly.app/#org" },
    },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en-IN">
      <body>
        <JsonLd data={ORG_JSON_LD} />
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-[100] focus:rounded-full focus:bg-black focus:px-4 focus:py-2 focus:text-[14px] focus:font-semibold focus:text-white"
        >
          Skip to content
        </a>
        {children}
      </body>
    </html>
  );
}
