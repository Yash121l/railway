import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft, ArrowRight, Check, TrainFront } from "lucide-react";
import { PageHero, PageShell } from "@/components/marketing/PageShell";
import { Reveal } from "@/components/marketing/Reveal";
import { JsonLd } from "@/components/seo/JsonLd";
import { APPS, PROFILES, ROWS, type Verdict } from "@/app/compare/page";

export const dynamicParams = false;

export function generateStaticParams() {
  return PROFILES.map((p) => ({ slug: p.slug }));
}

function profileFromSlug(slug: string) {
  return PROFILES.find((p) => p.slug === slug);
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const app = profileFromSlug(slug);
  if (!app) return {};

  const title = `Railly vs ${app.name} — Live Status, PNR & Delay Predictions Compared (2026)`;
  const description = `How Railly and ${app.name} compare on live running status, PNR watch, delay predictions, and platform alerts — an honest, feature-by-feature look at where each one fits.`;

  return {
    title: { absolute: title },
    description,
    alternates: { canonical: `/compare/${slug}` },
    openGraph: {
      type: "website",
      siteName: "Railly",
      locale: "en_IN",
      url: `/compare/${slug}`,
      title,
      description,
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
    },
  };
}

function verdictLabel(v: Verdict) {
  if (v === "yes")
    return <span className="text-[14px] font-semibold text-carbon">Yes</span>;
  if (v === "varies")
    return <span className="text-[14px] text-fog">Varies</span>;
  return (
    <span className="text-fog">
      <span aria-hidden>—</span>
      <span className="sr-only">Not offered, as far as we can tell</span>
    </span>
  );
}

export default async function CompareChildPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const app = profileFromSlug(slug);
  if (!app) notFound();

  const idx = APPS.findIndex((a) => a.id === app.id);
  const others = PROFILES.filter((p) => p.slug !== slug);

  const breadcrumbJsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "Home",
        item: "https://railly.app",
      },
      {
        "@type": "ListItem",
        position: 2,
        name: "Compare",
        item: "https://railly.app/compare",
      },
      {
        "@type": "ListItem",
        position: 3,
        name: `Railly vs ${app.name}`,
        item: `https://railly.app/compare/${slug}`,
      },
    ],
  };

  return (
    <PageShell>
      <JsonLd data={breadcrumbJsonLd} />

      <div className="mx-auto max-w-3xl px-4 pt-16 md:pt-24">
        <Link
          href="/compare"
          className="inline-flex items-center gap-1.5 text-[13px] font-semibold text-steel transition-colors hover:text-black"
        >
          <ArrowLeft size={15} strokeWidth={2.2} />
          All comparisons
        </Link>
      </div>

      <PageHero
        eyebrow="COMPARE"
        title={`Railly vs ${app.name}.`}
        dek={app.about}
      />

      {/* Two-way feature table */}
      <section className="bg-linen px-4 py-16 md:py-24">
        <div className="mx-auto max-w-4xl">
          <Reveal from="zoom">
            <div className="overflow-hidden rounded-3xl bg-white shadow-float ring-1 ring-black/[0.05]">
              <div className="overflow-x-auto">
                <table className="w-full min-w-[560px] border-separate border-spacing-0 text-left">
                  <thead>
                    <tr>
                      <th
                        scope="col"
                        className="sticky left-0 z-10 border-r border-black/[0.06] bg-white px-6 py-5 text-[11px] font-bold uppercase tracking-[2px] text-steel md:px-8"
                      >
                        Feature
                      </th>
                      <th
                        scope="col"
                        className="bg-signal/[0.04] px-4 py-5 text-center align-middle"
                      >
                        <span className="inline-flex items-center gap-2">
                          <span className="flex h-6 w-6 items-center justify-center rounded-[7px] bg-signal">
                            <TrainFront size={13} className="text-white" />
                          </span>
                          <span className="text-[14px] font-bold text-black">
                            Railly
                          </span>
                        </span>
                      </th>
                      <th
                        scope="col"
                        className="px-4 py-5 text-center align-middle text-[14px] font-semibold text-carbon"
                      >
                        {app.name}
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {ROWS.map((row) => (
                      <tr key={row.feature}>
                        <th
                          scope="row"
                          className="sticky left-0 z-10 max-w-[360px] border-r border-t border-black/[0.06] bg-white px-6 py-5 font-normal md:px-8"
                        >
                          <span className="block text-[15px] font-semibold leading-snug text-black">
                            {row.feature}
                          </span>
                          <span className="mt-1 block text-[13px] leading-relaxed text-steel">
                            {row.claim}
                          </span>
                        </th>
                        <td className="border-t border-black/[0.06] bg-signal/[0.04] px-4 py-5 text-center align-middle">
                          {row.railly === "yes" ? (
                            <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-go/15">
                              <Check size={15} strokeWidth={3} className="text-go" />
                              <span className="sr-only">Built into Railly</span>
                            </span>
                          ) : (
                            <span className="text-[14px] font-medium text-fog">
                              {row.railly === "varies" ? "Partly" : "Not yet"}
                            </span>
                          )}
                        </td>
                        <td className="border-t border-black/[0.06] px-4 py-5 text-center align-middle">
                          {verdictLabel(row.cells[idx])}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </Reveal>

          <Reveal delay={80}>
            <p className="mx-auto mt-6 max-w-2xl text-center text-[13px] leading-relaxed text-fog">
              &ldquo;Varies&rdquo; means offered in some form, with depth and
              coverage that differ; &mdash; means not offered, as far as we can
              tell. This reflects our reading of publicly available apps as of
              July 2026 — verify with each product. Railly is independent and not
              affiliated with Indian Railways or IRCTC.
            </p>
          </Reveal>
        </div>
      </section>

      {/* Where each fits */}
      <section className="mx-auto max-w-4xl px-4 py-20 md:py-28">
        <div className="grid gap-4 md:grid-cols-2">
          <Reveal>
            <div className="flex h-full flex-col rounded-3xl bg-linen p-8 ring-1 ring-black/[0.05]">
              <div className="flex items-center justify-between gap-3">
                <h2 className="text-[22px] font-bold tracking-tight text-black">
                  {app.name}
                </h2>
                <span className="whitespace-nowrap rounded-full bg-white px-3 py-1 text-[11px] font-bold uppercase tracking-[1px] text-steel ring-1 ring-black/[0.06]">
                  {app.tag}
                </span>
              </div>
              <p className="mt-4 text-[15px] leading-relaxed text-carbon">
                {app.about}
              </p>
            </div>
          </Reveal>
          <Reveal delay={70}>
            <div className="flex h-full flex-col rounded-3xl bg-midnight p-8 text-white ring-1 ring-white/[0.06]">
              <div className="text-[11px] font-bold uppercase tracking-[2px] text-sun">
                Where Railly fits
              </div>
              <p className="mt-3 text-[15px] leading-relaxed text-silver">
                {app.fit}
              </p>
            </div>
          </Reveal>
        </div>
      </section>

      {/* Cross-links to the other comparisons */}
      <section className="mx-auto max-w-4xl px-4 pb-24">
        <Reveal>
          <h2 className="text-[13px] font-bold uppercase tracking-[2px] text-steel">
            Compare Railly with
          </h2>
          <div className="mt-5 grid gap-3 sm:grid-cols-3">
            {others.map((o) => (
              <Link
                key={o.slug}
                href={`/compare/${o.slug}`}
                className="card-lift flex items-center justify-between gap-3 rounded-2xl bg-linen px-5 py-4 ring-1 ring-black/[0.05]"
              >
                <span className="text-[15px] font-semibold text-black">
                  {o.name}
                </span>
                <ArrowRight size={16} strokeWidth={2.2} className="text-signal" />
              </Link>
            ))}
          </div>
          <Link
            href="/compare"
            className="mt-5 inline-flex items-center gap-1.5 text-[14px] font-semibold text-signal transition-colors hover:text-black"
          >
            See all five apps side by side
            <ArrowRight size={15} strokeWidth={2.2} />
          </Link>
        </Reveal>
      </section>
    </PageShell>
  );
}
