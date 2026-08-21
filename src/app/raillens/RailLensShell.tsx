"use client";

import dynamic from "next/dynamic";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useCallback, useEffect, useId, useMemo, useRef, useState } from "react";
import {
  ChevronDown,
  Crosshair,
  Eye,
  EyeOff,
  Layers,
  Loader2,
  Minus,
  Plus,
  Search,
  TrainFront,
  TriangleAlert,
  X,
} from "lucide-react";
import type { LensRoute, LensStop } from "@/lib/raillens";
import { fmtDuration } from "@/lib/time";
import type { MapInsets, MapLayerToggles, RouteMapHandle } from "./RouteMap";

/**
 * The chrome around the RailLens map: layer filters, the train card with its
 * halt list, and the search that swaps the `?train=` in the URL. The map
 * itself is browser-only (WebGL), so it loads client-side.
 */

const RouteMap = dynamic(() => import("./RouteMap"), {
  ssr: false,
  loading: () => (
    <div className="absolute inset-0 grid place-items-center bg-linen">
      <div className="flex items-center gap-2 text-[14px] font-medium text-steel">
        <Loader2 size={16} className="animate-spin" />
        Loading the network…
      </div>
    </div>
  ),
});

/** Width reserved for the desktop detail panel (356px card + its 16px margin). */
const PANEL_WIDTH = 380;
/** The collapsed mobile sheet covers this share of the viewport. */
const SHEET_FRACTION = 0.44;

interface SearchHit {
  number: string;
  name: string;
  category: string;
}

export interface RailLensShellProps {
  route: LensRoute | null;
  /** the real error from the feed, when a lookup failed */
  error: string | null;
  /** what the visitor asked for, echoed back in the error state */
  requested: string | null;
}

export function RailLensShell({ route, error, requested }: RailLensShellProps) {
  const [activeIndex, setActiveIndex] = useState<number | null>(null);
  const [sheetOpen, setSheetOpen] = useState(false);
  const [layers, setLayers] = useState<MapLayerToggles>({
    route: true,
    halts: true,
    labels: true,
    // With no train picked, the bare network is the whole point of the view.
    network: route === null,
    places: true,
  });
  const mapHandle = useRef<RouteMapHandle | null>(null);
  const stopRefs = useRef<(HTMLLIElement | null)[]>([]);

  const { isDesktop, viewportHeight } = useViewport();
  // The map has to frame the route around whatever panel is covering it: the
  // side card on desktop, the bottom sheet on a phone.
  const insets: MapInsets = useMemo(
    () =>
      isDesktop
        ? { right: PANEL_WIDTH, bottom: 0 }
        : { right: 0, bottom: Math.round(viewportHeight * SHEET_FRACTION) },
    [isDesktop, viewportHeight],
  );

  const selectStop = useCallback((index: number) => {
    setActiveIndex(index);
    mapHandle.current?.focusStop(index);
    stopRefs.current[index]?.scrollIntoView({ block: "nearest", behavior: "smooth" });
  }, []);

  return (
    <div className="relative flex-1 overflow-hidden bg-linen">
      <RouteMap
        route={route}
        activeIndex={activeIndex}
        onSelectStop={selectStop}
        layers={layers}
        insets={insets}
        handleRef={mapHandle}
      />

      <LayerFilters
        layers={layers}
        onChange={setLayers}
        hasRoute={route !== null}
        startOpen={isDesktop}
      />

      <TrainSearch />

      <MapControls
        onFit={() => mapHandle.current?.fitRoute(true)}
        onZoom={(d) => mapHandle.current?.zoomBy(d)}
        hasRoute={route !== null}
      />

      {error && <FeedError message={error} requested={requested} />}

      {!route && !error && <EmptyPrompt />}

      {route && (
        <TrainCard
          route={route}
          activeIndex={activeIndex}
          onSelectStop={selectStop}
          stopRefs={stopRefs}
          open={sheetOpen}
          onToggle={() => setSheetOpen((v) => !v)}
        />
      )}

      <Attribution hasRoute={route !== null} />
    </div>
  );
}

/* -------------------------------------------------------------------------- */
/* Layer filters                                                              */
/* -------------------------------------------------------------------------- */

const LAYER_ROWS: {
  key: keyof MapLayerToggles;
  label: string;
  swatch: "line" | "dot" | "network" | "text";
  routeOnly?: boolean;
}[] = [
  { key: "route", label: "This train's route", swatch: "line", routeOnly: true },
  { key: "halts", label: "Halts", swatch: "dot", routeOnly: true },
  { key: "labels", label: "Halt names", swatch: "text", routeOnly: true },
  { key: "network", label: "Rail network", swatch: "network" },
  { key: "places", label: "Place labels", swatch: "text" },
];

function LayerFilters({
  layers,
  onChange,
  hasRoute,
  startOpen,
}: {
  layers: MapLayerToggles;
  onChange: (next: MapLayerToggles) => void;
  hasRoute: boolean;
  startOpen: boolean;
}) {
  // Expanded is the better desktop default; on a phone it would bury the map.
  // Derived rather than synced, so the breakpoint decides until the visitor
  // does — after that their choice sticks.
  const [choice, setChoice] = useState<boolean | null>(null);
  const open = choice ?? startOpen;
  const rows = LAYER_ROWS.filter((r) => hasRoute || !r.routeOnly);

  return (
    // Tucked under the search field on a phone, top-left beside it on desktop.
    <div className="pointer-events-none absolute left-3 top-[62px] z-20 md:left-4 md:top-4">
      <div className="pointer-events-auto w-[218px] overflow-hidden rounded-2xl bg-white/95 shadow-float backdrop-blur">
        <button
          onClick={() => setChoice(!open)}
          aria-expanded={open}
          className="flex w-full items-center gap-2 px-3.5 py-2.5 text-[11px] font-bold uppercase tracking-[1.4px] text-steel"
        >
          <Layers size={13} className="shrink-0" />
          Filter layers
          <ChevronDown
            size={14}
            className={`ml-auto transition-transform ${open ? "" : "-rotate-90"}`}
          />
        </button>
        {open && (
          <ul className="border-t border-hairline px-1.5 pb-1.5 pt-1.5">
            {rows.map((row) => {
              const on = layers[row.key];
              return (
                <li key={row.key}>
                  <button
                    onClick={() => onChange({ ...layers, [row.key]: !on })}
                    aria-pressed={on}
                    className="flex w-full items-center gap-2.5 rounded-xl px-2 py-1.5 text-left transition-colors hover:bg-fill"
                  >
                    <LayerSwatch kind={row.swatch} dim={!on} />
                    <span
                      className={`flex-1 text-[13px] font-medium ${on ? "text-inkline" : "text-faded"}`}
                    >
                      {row.label}
                    </span>
                    {on ? (
                      <Eye size={14} className="text-steel" />
                    ) : (
                      <EyeOff size={14} className="text-silver" />
                    )}
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </div>
  );
}

function LayerSwatch({ kind, dim }: { kind: "line" | "dot" | "network" | "text"; dim: boolean }) {
  const faded = dim ? "opacity-35" : "";
  if (kind === "line") {
    return <span className={`h-[3px] w-5 rounded-full bg-action ${faded}`} />;
  }
  if (kind === "dot") {
    return (
      <span
        className={`h-2.5 w-2.5 rounded-full border-2 border-action bg-white ${faded}`}
      />
    );
  }
  if (kind === "network") {
    return <span className={`h-[2px] w-5 rounded-full bg-steel ${faded}`} />;
  }
  return (
    <span
      className={`w-5 text-center text-[10px] font-bold leading-none text-steel ${faded}`}
    >
      Aa
    </span>
  );
}

/* -------------------------------------------------------------------------- */
/* Search                                                                     */
/* -------------------------------------------------------------------------- */

function TrainSearch() {
  const router = useRouter();
  const listId = useId();
  const [query, setQuery] = useState("");
  const [hits, setHits] = useState<SearchHit[]>([]);
  const [busy, setBusy] = useState(false);
  const [open, setOpen] = useState(false);
  const boxRef = useRef<HTMLDivElement>(null);

  // Clearing is handled where the query changes, not here — an effect that
  // sets state synchronously just triggers a cascading render.
  useEffect(() => {
    const q = query.trim();
    if (q.length < 2) return;
    const controller = new AbortController();
    const timer = setTimeout(async () => {
      setBusy(true);
      try {
        const res = await fetch(`/api/rail/search?q=${encodeURIComponent(q)}`, {
          signal: controller.signal,
        });
        if (!res.ok) throw new Error("search failed");
        const data: { results: SearchHit[] } = await res.json();
        setHits(data.results);
      } catch {
        if (!controller.signal.aborted) setHits([]);
      } finally {
        if (!controller.signal.aborted) setBusy(false);
      }
    }, 180);
    return () => {
      controller.abort();
      clearTimeout(timer);
    };
  }, [query]);

  useEffect(() => {
    const onDown = (e: MouseEvent) => {
      if (!boxRef.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", onDown);
    return () => document.removeEventListener("mousedown", onDown);
  }, []);

  const onQueryChange = (value: string) => {
    setQuery(value);
    setOpen(true);
    // too short to search — drop whatever the last query matched
    if (value.trim().length < 2) setHits([]);
  };

  const go = (number: string) => {
    setOpen(false);
    setQuery("");
    router.push(`/raillens?train=${number}`);
  };

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const q = query.trim();
    if (/^\d{4,6}$/.test(q)) go(q);
    else if (hits.length > 0) go(hits[0].number);
  };

  return (
    // Centred in the space the panels leave: past the filter card on the left,
    // clear of the detail panel on the right.
    <div
      ref={boxRef}
      className="pointer-events-none absolute inset-x-3 top-3 z-30 flex flex-col items-center md:left-[250px] md:right-[calc(var(--lens-panel)+1rem)] md:top-4"
      style={{ ["--lens-panel" as string]: `${PANEL_WIDTH}px` }}
    >
      <form
        onSubmit={onSubmit}
        className="pointer-events-auto w-full max-w-[420px]"
        role="search"
      >
        <div className="flex items-center gap-2 rounded-full bg-white/95 px-4 py-2.5 shadow-float backdrop-blur focus-within:ring-2 focus-within:ring-action/30">
          <Search size={16} className="shrink-0 text-steel" />
          <input
            value={query}
            onChange={(e) => onQueryChange(e.target.value)}
            onFocus={() => setOpen(true)}
            role="combobox"
            aria-expanded={open && hits.length > 0}
            aria-controls={listId}
            aria-label="Search a train by number or name"
            placeholder="Search a train — 01435, Rajdhani…"
            className="w-full bg-transparent text-[14px] text-inkline outline-none placeholder:text-faded"
          />
          {busy && <Loader2 size={14} className="shrink-0 animate-spin text-faded" />}
          {!busy && query && (
            <button
              type="button"
              aria-label="Clear search"
              onClick={() => {
                setQuery("");
                setHits([]);
              }}
              className="shrink-0 text-faded hover:text-steel"
            >
              <X size={14} />
            </button>
          )}
        </div>
      </form>

      {open && hits.length > 0 && (
        <ul
          id={listId}
          role="listbox"
          className="pointer-events-auto mt-2 max-h-[min(60vh,380px)] w-full max-w-[420px] overflow-y-auto rounded-2xl bg-white/97 p-1.5 shadow-float backdrop-blur"
        >
          {hits.map((hit) => (
            <li key={hit.number} role="option" aria-selected={false}>
              <button
                onClick={() => go(hit.number)}
                className="flex w-full items-center gap-3 rounded-xl px-2.5 py-2 text-left transition-colors hover:bg-fill"
              >
                <TrainFront size={15} className="shrink-0 text-steel" />
                <span className="w-[52px] shrink-0 font-mono text-[13px] font-bold text-inkline">
                  {hit.number}
                </span>
                <span className="truncate text-[13px] text-sub">{hit.name}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

/* -------------------------------------------------------------------------- */
/* Map controls                                                               */
/* -------------------------------------------------------------------------- */

function MapControls({
  onFit,
  onZoom,
  hasRoute,
}: {
  onFit: () => void;
  onZoom: (delta: number) => void;
  hasRoute: boolean;
}) {
  return (
    // Bottom-left on desktop; on a phone the sheet owns the bottom of the
    // screen, so they sit up top opposite the filter card.
    <div className="pointer-events-none absolute right-3 top-[62px] z-20 md:bottom-10 md:left-4 md:right-auto md:top-auto">
      <div className="pointer-events-auto flex items-center gap-0.5 rounded-full bg-white/95 p-1 shadow-float backdrop-blur">
        <ControlButton
          label={hasRoute ? "Fit the whole route" : "Fit India"}
          onClick={onFit}
        >
          <Crosshair size={16} />
        </ControlButton>
        <span className="h-4 w-px bg-hairline" />
        <ControlButton label="Zoom in" onClick={() => onZoom(1)}>
          <Plus size={16} />
        </ControlButton>
        <ControlButton label="Zoom out" onClick={() => onZoom(-1)}>
          <Minus size={16} />
        </ControlButton>
      </div>
    </div>
  );
}

function ControlButton({
  label,
  onClick,
  children,
}: {
  label: string;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      aria-label={label}
      title={label}
      className="grid h-8 w-8 place-items-center rounded-full text-carbon transition-colors hover:bg-fill"
    >
      {children}
    </button>
  );
}

/* -------------------------------------------------------------------------- */
/* Train card                                                                 */
/* -------------------------------------------------------------------------- */

function TrainCard({
  route,
  activeIndex,
  onSelectStop,
  stopRefs,
  open,
  onToggle,
}: {
  route: LensRoute;
  activeIndex: number | null;
  onSelectStop: (i: number) => void;
  stopRefs: React.RefObject<(HTMLLIElement | null)[]>;
  open: boolean;
  onToggle: () => void;
}) {
  const { approximatedLegs, tracedLegs, totalLegs } = route.geometry;

  const runsOn = route.runsDaily ? "Runs daily" : `Runs ${route.days.join(" · ")}`;

  // Halt coordinates always come from the feed; it's the line *between* them
  // that's only as good as the track shape we have bundled. Say which.
  const pathNote =
    approximatedLegs === 0
      ? null
      : tracedLegs === 0
        ? "Halt positions are exact, but the line between them is drawn straight — real OpenStreetMap track shape isn't bundled for this corridor yet."
        : `${tracedLegs} of ${totalLegs} legs follow real OpenStreetMap track; the other ${approximatedLegs} are drawn straight between halts.`;

  return (
    <aside
      className={`pointer-events-auto absolute z-20 flex flex-col overflow-hidden bg-white/97 shadow-float backdrop-blur
        inset-x-0 bottom-0 rounded-t-3xl transition-[max-height] duration-300
        ${open ? "max-h-[82svh]" : "max-h-[44svh]"}
        md:inset-x-auto md:bottom-4 md:right-4 md:top-4 md:w-[356px] md:max-h-none md:rounded-3xl`}
    >
      <button
        onClick={onToggle}
        className="mx-auto mt-2 h-1 w-10 shrink-0 rounded-full bg-silver md:hidden"
        aria-label={open ? "Collapse details" : "Expand details"}
      />

      <header className="shrink-0 px-5 pb-4 pt-3 md:pt-5">
        <span className="inline-flex rounded-full bg-fill px-2.5 py-1 text-[10px] font-bold uppercase tracking-[1.2px] text-steel">
          {route.categoryLabel}
        </span>
        <h2 className="mt-2.5 text-[21px] font-bold leading-tight tracking-[-0.5px] text-inkline">
          {route.name}
        </h2>
        <p className="mt-1 text-[13px] text-sub">
          <span className="font-mono font-semibold">{route.number}</span>
          {" · "}
          {route.origin.name} → {route.destination.name}
        </p>

        <dl className="mt-4 flex items-end gap-6">
          <Stat value={String(route.stops.length)} label="Halts" />
          <Stat value={String(route.distanceKm)} label="km" />
          <Stat value={fmtDuration(route.durationMin)} label="Journey" />
        </dl>

        <p className="mt-3 text-[12px] text-faded">{runsOn}</p>

        {pathNote && <Caveat>{pathNote}</Caveat>}
        {!route.kmIsExact && (
          <Caveat>
            The feed omitted per-halt distances here, so the kilometre column is
            measured straight between halts and reads short.
          </Caveat>
        )}
      </header>

      <div className="flex shrink-0 items-baseline justify-between border-t border-hairline px-5 py-2.5">
        <h3 className="text-[11px] font-bold uppercase tracking-[1.4px] text-steel">
          Halts
        </h3>
        <span className="text-[11px] text-faded">Times IST</span>
      </div>

      <ol className="min-h-0 flex-1 overflow-y-auto px-2 pb-3">
        {route.stops.map((stop, i) => (
          <StopRow
            key={`${stop.code}-${i}`}
            stop={stop}
            active={i === activeIndex}
            last={i === route.stops.length - 1}
            onClick={() => onSelectStop(i)}
            ref={(el) => {
              stopRefs.current[i] = el;
            }}
          />
        ))}
      </ol>

      <footer className="shrink-0 border-t border-hairline px-5 py-2.5 text-[11px] text-faded">
        Schedule from erail · Track shape © OpenStreetMap
      </footer>
    </aside>
  );
}

function Stat({ value, label }: { value: string; label: string }) {
  return (
    <div>
      <dd className="text-[24px] font-bold leading-none tracking-[-0.6px] text-inkline">
        {value}
      </dd>
      <dt className="mt-1 text-[10px] font-bold uppercase tracking-[1.2px] text-faded">
        {label}
      </dt>
    </div>
  );
}

function Caveat({ children }: { children: React.ReactNode }) {
  return (
    <p className="mt-3 flex gap-2 rounded-xl bg-sun/10 px-3 py-2.5 text-[12px] leading-snug text-carbon">
      <TriangleAlert size={14} className="mt-px shrink-0 text-sun" />
      <span>{children}</span>
    </p>
  );
}

function StopRow({
  stop,
  active,
  last,
  onClick,
  ref,
}: {
  stop: LensStop;
  active: boolean;
  last: boolean;
  onClick: () => void;
  ref: (el: HTMLLIElement | null) => void;
}) {
  const terminus = stop.isOrigin || stop.isDestination;
  return (
    <li ref={ref}>
      <button
        onClick={onClick}
        aria-current={active ? "true" : undefined}
        className={`flex w-full gap-3 rounded-xl px-3 py-2 text-left transition-colors ${
          active ? "bg-action/8" : "hover:bg-fill"
        }`}
      >
        <span className="relative flex w-3 shrink-0 justify-center pt-1.5">
          <span
            className={`z-10 rounded-full border-2 border-action ${
              terminus ? "h-2.5 w-2.5 bg-action" : "h-2 w-2 bg-white"
            }`}
          />
          {!last && (
            <span className="absolute top-3 h-[calc(100%-0.25rem)] w-[2px] bg-action/25" />
          )}
        </span>

        <span className="min-w-0 flex-1">
          <span className="block font-mono text-[13px] font-bold text-inkline">
            {stop.code}
          </span>
          <span className="block truncate text-[12px] text-sub">{stop.name}</span>
        </span>

        <span className="shrink-0 text-right">
          <span className="block text-[13px] font-semibold tabular-nums text-inkline">
            {stop.isOrigin ? stop.departure : stop.arrival}
          </span>
          {!stop.isOrigin && !stop.isDestination && stop.haltMin > 0 && (
            <span className="block text-[11px] tabular-nums text-sub">
              {stop.departure}
            </span>
          )}
          <span className="block text-[11px] tabular-nums text-faded">
            {stop.km} km{stop.day > 1 ? ` · day ${stop.day}` : ""}
          </span>
        </span>
      </button>
    </li>
  );
}

/* -------------------------------------------------------------------------- */
/* Empty state                                                                */
/* -------------------------------------------------------------------------- */

/**
 * A few recognisable services to start from — all real, and all in the
 * bundled index. Coromandel is the one worth clicking first: its
 * Vijayawada→Chennai leg is the coastal stretch that used to draw itself
 * across the Bay of Bengal.
 */
const EXAMPLES: { number: string; label: string; leg: string }[] = [
  { number: "12951", label: "Mumbai Rajdhani", leg: "MMCT → NDLS" },
  { number: "12841", label: "Coromandel Express", leg: "HWH → MAS" },
  { number: "22436", label: "Vande Bharat", leg: "NDLS → BSB" },
  { number: "12627", label: "Karnataka Express", leg: "SBC → NDLS" },
  { number: "01435", label: "Solapur–LTT Special", leg: "SUR → LTT" },
];

function EmptyPrompt() {
  return (
    <aside className="pointer-events-auto absolute inset-x-0 bottom-0 z-20 rounded-t-3xl bg-white/97 px-5 pb-6 pt-4 shadow-float backdrop-blur md:inset-x-auto md:bottom-auto md:right-4 md:top-20 md:w-[356px] md:rounded-3xl md:pt-5">
      <span className="inline-flex rounded-full bg-fill px-2.5 py-1 text-[10px] font-bold uppercase tracking-[1.2px] text-steel">
        RailLens
      </span>
      <h2 className="mt-2.5 text-[21px] font-bold leading-tight tracking-[-0.5px] text-inkline">
        Any train, halt by halt
      </h2>
      <p className="mt-2 text-[13px] leading-relaxed text-sub">
        Search any of the 4,022 services in the index for its full halt list,
        arrival times and kilometre marks from the live schedule feed. Real
        OpenStreetMap track geometry covers 120 corridors so far; anywhere it
        does not reach, the line is drawn straight between halts and the map
        says which legs those are.
      </p>

      <h3 className="mt-5 text-[11px] font-bold uppercase tracking-[1.4px] text-steel">
        Start with
      </h3>
      <ul className="mt-2 space-y-0.5">
        {EXAMPLES.map((ex) => (
          <li key={ex.number}>
            <Link
              href={`/raillens?train=${ex.number}`}
              className="flex items-center gap-3 rounded-xl px-2.5 py-2 transition-colors hover:bg-fill"
            >
              <span className="w-[52px] shrink-0 font-mono text-[13px] font-bold text-inkline">
                {ex.number}
              </span>
              <span className="min-w-0 flex-1 truncate text-[13px] text-inkline">
                {ex.label}
              </span>
              <span className="shrink-0 font-mono text-[11px] text-faded">{ex.leg}</span>
            </Link>
          </li>
        ))}
      </ul>
    </aside>
  );
}

/* -------------------------------------------------------------------------- */
/* Error + attribution                                                        */
/* -------------------------------------------------------------------------- */

function FeedError({
  message,
  requested,
}: {
  message: string;
  requested: string | null;
}) {
  return (
    <div className="pointer-events-none absolute inset-x-0 bottom-14 z-20 flex justify-center px-4 md:bottom-10">
      <div className="pointer-events-auto flex max-w-md gap-3 rounded-2xl bg-white/97 px-4 py-3 shadow-float backdrop-blur">
        <TriangleAlert size={16} className="mt-0.5 shrink-0 text-crit" />
        <div>
          <p className="text-[13px] font-semibold text-inkline">
            {requested ? `Couldn't load train ${requested}` : "Couldn't load that train"}
          </p>
          <p className="mt-0.5 text-[12px] leading-snug text-sub">{message}</p>
        </div>
      </div>
    </div>
  );
}

function Attribution({ hasRoute }: { hasRoute: boolean }) {
  return (
    <div className="pointer-events-none absolute inset-x-0 bottom-0 z-10 flex items-center justify-center gap-1.5 bg-gradient-to-t from-white/85 to-transparent px-3 py-2 text-[10px] text-steel md:justify-start md:px-4">
      <span className="rounded bg-carbon px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wider text-white">
        Beta
      </span>
      <span className="pointer-events-auto">
        {hasRoute ? "Route " : "Network "}© Railly · Basemap ©{" "}
        <a
          href="https://openfreemap.org"
          target="_blank"
          rel="noopener noreferrer"
          className="underline underline-offset-2 hover:text-carbon"
        >
          OpenFreeMap
        </a>{" "}
        · Data ©{" "}
        <a
          href="https://www.openstreetmap.org/copyright"
          target="_blank"
          rel="noopener noreferrer"
          className="underline underline-offset-2 hover:text-carbon"
        >
          OpenStreetMap
        </a>
      </span>
    </div>
  );
}

/* -------------------------------------------------------------------------- */

/**
 * Tailwind's `md` breakpoint (the panel-vs-sheet swap) plus the viewport
 * height the mobile sheet is sized against.
 */
function useViewport(): { isDesktop: boolean; viewportHeight: number } {
  const [state, setState] = useState({ isDesktop: false, viewportHeight: 0 });
  useEffect(() => {
    const sync = () =>
      setState({
        isDesktop: window.matchMedia("(min-width: 768px)").matches,
        viewportHeight: window.innerHeight,
      });
    sync();
    window.addEventListener("resize", sync);
    return () => window.removeEventListener("resize", sync);
  }, []);
  return state;
}
