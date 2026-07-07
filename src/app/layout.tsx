import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "Railly — Know the truth when you take the train",
    template: "%s — Railly",
  },
  description:
    "Live train tracking, delay predictions before the railway announces them, platform-change alerts, and a logbook of every kilometre. Railly is the Flighty of rail travel.",
  applicationName: "Railly",
  openGraph: {
    siteName: "Railly",
    type: "website",
    title: "Railly — Know the truth when you take the train",
    description:
      "Live train tracking, delay predictions before the railway announces them, and platform-change alerts — for every journey.",
  },
  twitter: {
    card: "summary_large_image",
    title: "Railly — Know the truth when you take the train",
    description:
      "Live train tracking, delay predictions before the railway announces them, and platform-change alerts — for every journey.",
  },
};

export const viewport: Viewport = {
  themeColor: "#0d0021",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
