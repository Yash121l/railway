"use client";

import { useEffect, useRef, useState } from "react";
import {
  LngLatBounds,
  Map as MapLibreMap,
  prewarm,
  setWorkerUrl,
  type GeoJSONSource,
  type MapGeoJSONFeature,
} from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import { haltPointFeatures, routeLineFeature, type LensRoute } from "@/lib/raillens";

/**
 * The RailLens canvas: a train's real route drawn over the OpenStreetMap rail
 * network. Basemap tiles come from OpenFreeMap (keyless, OSM-derived); the
 * route line and halts are ours, spliced onto real track geometry where we
 * have it — see `src/lib/railshapes.ts`.
 *
 * The map is built exactly once and then fed new data. Picking a different
 * train must not throw away the WebGL context: rebuilding it mid-navigation
 * races maplibre's style load and leaves the map stuck on a blank basemap.
 */

const STYLE_URL = "https://tiles.openfreemap.org/styles/liberty";

/** Copied out of node_modules by `tools/sync-maplibre-worker.mjs`. */
const WORKER_URL = "/maplibre/maplibre-gl-worker.mjs";

/** Our overlay source and layer ids, all prefixed so nothing collides. */
const SRC_ROUTE = "railly-route";
const SRC_HALTS = "railly-halts";
const SRC_ACTIVE = "railly-active";
const LYR_CASING = "railly-route-casing";
const LYR_LINE = "railly-route-line";
const LYR_HALT = "railly-halt-dot";
const LYR_ACTIVE = "railly-halt-active";
const LYR_LABEL = "railly-halt-label";

/** The basemap's own OSM railway lines — toggled by the "Rail network" filter. */
const BASEMAP_RAIL_LAYERS = [
  "tunnel_major_rail",
  "tunnel_major_rail_hatching",
  "tunnel_transit_rail",
  "tunnel_transit_rail_hatching",
  "road_major_rail",
  "road_major_rail_hatching",
  "road_transit_rail",
  "road_transit_rail_hatching",
  "bridge_major_rail",
  "bridge_major_rail_hatching",
  "bridge_transit_rail",
  "bridge_transit_rail_hatching",
];

const ROUTE_BLUE = "#0a84ff";
const ROUTE_DEEP = "#0b3d91";

const EMPTY: GeoJSON.FeatureCollection = { type: "FeatureCollection", features: [] };

export interface MapLayerToggles {
  route: boolean;
  halts: boolean;
  labels: boolean;
  network: boolean;
  places: boolean;
}

export interface RouteMapHandle {
  fitRoute: (animate?: boolean) => void;
  zoomBy: (delta: number) => void;
  focusStop: (index: number) => void;
}

export interface RouteMapProps {
  /** null renders the bare network view — no train picked yet */
  route: LensRoute | null;
  activeIndex: number | null;
  onSelectStop: (index: number) => void;
  layers: MapLayerToggles;
  /** space taken by the surrounding panels, so framing never hides the route */
  insets: MapInsets;
  handleRef?: { current: RouteMapHandle | null };
}

/** Panel-occupied edges in CSS pixels: the side panel, or the mobile sheet. */
export interface MapInsets {
  right: number;
  bottom: number;
}

/** Mainland India plus the island territories — the no-train default view. */
const INDIA_BOUNDS: [number, number, number, number] = [68.0, 6.5, 97.5, 35.7];

function boundsFor(route: LensRoute | null): LngLatBounds {
  const [w, s, e, n] = route?.bounds ?? INDIA_BOUNDS;
  return new LngLatBounds([w, s], [e, n]);
}

/**
 * Padding for `fitBounds`, keeping the route clear of the panels. maplibre
 * needs the padded viewport to stay positive, so each axis is scaled down
 * proportionally if the panels would eat more than 80% of it.
 */
function framePadding(map: MapLibreMap, insets: MapInsets) {
  const { width, height } = map.getCanvas().getBoundingClientRect();
  const base = 48;
  let [top, right, bottom, left] = [base, base + insets.right, base + insets.bottom, base];

  const spanX = left + right;
  if (spanX > width * 0.8) {
    const k = (width * 0.8) / spanX;
    left *= k;
    right *= k;
  }
  const spanY = top + bottom;
  if (spanY > height * 0.8) {
    const k = (height * 0.8) / spanY;
    top *= k;
    bottom *= k;
  }
  return { top, right, bottom, left };
}

function setData(map: MapLibreMap, id: string, data: GeoJSON.GeoJSON) {
  map.getSource<GeoJSONSource>(id)?.setData(data);
}

/**
 * The basemap draws railways as 0.4px #bbb hairlines until zoom 14 — invisible
 * at anything wider than city scale. We surface them as a deliberate "Rail
 * network" layer, so give them enough weight to actually read once toggled on.
 */
const RAIL_LINE_LAYERS = [
  "road_major_rail",
  "road_transit_rail",
  "tunnel_major_rail",
  "tunnel_transit_rail",
  "bridge_major_rail",
  "bridge_transit_rail",
];

function emphasiseRailNetwork(map: MapLibreMap) {
  for (const id of RAIL_LINE_LAYERS) {
    if (!map.getLayer(id)) continue;
    map.setPaintProperty(id, "line-color", "#7c8794");
    map.setPaintProperty(id, "line-width", [
      "interpolate",
      ["linear"],
      ["zoom"],
      5,
      0.5,
      8,
      0.9,
      11,
      1.4,
      14,
      2,
      20,
      3.5,
    ]);
  }
}

/** Every source and layer we own, added once with empty data. */
function addOverlay(map: MapLibreMap) {
  emphasiseRailNetwork(map);

  map.addSource(SRC_ROUTE, { type: "geojson", data: EMPTY });
  map.addSource(SRC_HALTS, { type: "geojson", data: EMPTY });
  map.addSource(SRC_ACTIVE, { type: "geojson", data: EMPTY });

  // Keep the line under the basemap's place labels so cities stay legible;
  // our own halt dots and labels sit above everything.
  const firstSymbol = map.getStyle().layers?.find((l) => l.type === "symbol")?.id;

  map.addLayer(
    {
      id: LYR_CASING,
      type: "line",
      source: SRC_ROUTE,
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-color": "#ffffff",
        "line-opacity": 0.9,
        "line-width": ["interpolate", ["linear"], ["zoom"], 4, 4, 10, 9],
      },
    },
    firstSymbol,
  );
  map.addLayer(
    {
      id: LYR_LINE,
      type: "line",
      source: SRC_ROUTE,
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-color": ROUTE_BLUE,
        "line-width": ["interpolate", ["linear"], ["zoom"], 4, 1.8, 10, 4.5],
      },
    },
    firstSymbol,
  );

  map.addLayer({
    id: LYR_ACTIVE,
    type: "circle",
    source: SRC_ACTIVE,
    paint: {
      "circle-radius": ["interpolate", ["linear"], ["zoom"], 4, 9, 10, 14],
      "circle-color": ROUTE_BLUE,
      "circle-opacity": 0.18,
      "circle-stroke-width": 2,
      "circle-stroke-color": ROUTE_BLUE,
    },
  });

  map.addLayer({
    id: LYR_HALT,
    type: "circle",
    source: SRC_HALTS,
    paint: {
      "circle-radius": [
        "interpolate",
        ["linear"],
        ["zoom"],
        4,
        ["case", ["==", ["get", "terminus"], 1], 4.5, 2.6],
        10,
        ["case", ["==", ["get", "terminus"], 1], 7, 4.5],
      ],
      "circle-color": ["case", ["==", ["get", "terminus"], 1], ROUTE_DEEP, "#ffffff"],
      "circle-stroke-width": 2,
      "circle-stroke-color": ROUTE_BLUE,
    },
  });

  map.addLayer({
    id: LYR_LABEL,
    type: "symbol",
    source: SRC_HALTS,
    layout: {
      "text-field": ["get", "label"],
      "text-font": ["Noto Sans Bold"],
      "text-size": ["interpolate", ["linear"], ["zoom"], 5, 9, 11, 12],
      "text-offset": [0, 1.1],
      "text-anchor": "top",
      "text-max-width": 9,
      "text-padding": 4,
      // termini win any collision
      "symbol-sort-key": ["case", ["==", ["get", "terminus"], 1], 0, 1],
    },
    paint: {
      "text-color": "#111318",
      "text-halo-color": "#ffffff",
      "text-halo-width": 1.6,
      // Intermediate halts only earn a label once you've zoomed in. The
      // spec requires `zoom` to be the input of a *top-level* step, so the
      // terminus test has to live inside the branch, not wrap it.
      "text-opacity": [
        "step",
        ["zoom"],
        ["case", ["==", ["get", "terminus"], 1], 1, 0],
        6.5,
        1,
      ],
    },
  });
}

export default function RouteMap({
  route,
  activeIndex,
  onSelectStop,
  layers,
  insets,
  handleRef,
}: RouteMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<MapLibreMap | null>(null);
  const [ready, setReady] = useState(false);

  // Mirrored into refs so the map's own callbacks can read the latest values
  // without the map being torn down and rebuilt on every change.
  const insetRef = useRef(insets);
  const selectRef = useRef(onSelectStop);
  useEffect(() => {
    insetRef.current = insets;
  }, [insets]);
  useEffect(() => {
    selectRef.current = onSelectStop;
  }, [onSelectStop]);

  // ---- build the map once --------------------------------------------------
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    // Keep the worker pool alive across teardowns. React's development
    // double-mount removes the first map while its style is still in flight;
    // without this the replacement never finishes loading and the map sticks
    // on a blank basemap.
    // MapLibre can't resolve its own worker from inside a Next bundle — see
    // tools/sync-maplibre-worker.mjs for the whole story.
    setWorkerUrl(WORKER_URL);
    // Keep the worker pool alive across teardowns, so React's development
    // double-mount doesn't strand the replacement map mid-style-load.
    prewarm();

    const map = new MapLibreMap({
      container,
      style: STYLE_URL,
      center: [78.9629, 22.5937], // India, until the route bounds land
      zoom: 3.6,
      attributionControl: false,
      // The route is the subject; tilting/rotating only makes it harder to read.
      pitchWithRotate: false,
      dragRotate: false,
    });
    mapRef.current = map;
    map.touchZoomRotate.disableRotation();
    // Zoom lives in our own control pill — maplibre's would sit under the
    // detail panel on desktop.

    map.on("load", () => {
      addOverlay(map);
      setReady(true);
    });

    const pick = (features: MapGeoJSONFeature[] | undefined) => {
      const idx = features?.[0]?.properties?.index;
      if (typeof idx === "number") selectRef.current(idx);
    };
    map.on("click", LYR_HALT, (e) => pick(e.features));
    map.on("mouseenter", LYR_HALT, () => {
      map.getCanvas().style.cursor = "pointer";
    });
    map.on("mouseleave", LYR_HALT, () => {
      map.getCanvas().style.cursor = "";
    });

    return () => {
      mapRef.current = null;
      setReady(false);
      map.remove();
    };
  }, []);

  // ---- feed the route in, and frame it -------------------------------------
  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;

    setData(map, SRC_ROUTE, route ? routeLineFeature(route.geometry.coords) : EMPTY);
    setData(map, SRC_HALTS, {
      type: "FeatureCollection",
      features: route ? haltPointFeatures(route.stops) : [],
    });
    map.fitBounds(boundsFor(route), {
      padding: framePadding(map, insetRef.current),
      animate: false,
    });
  }, [ready, route]);

  // ---- imperative controls for the chrome around the map -------------------
  useEffect(() => {
    if (!handleRef) return;
    handleRef.current = {
      fitRoute: (animate = true) => {
        const map = mapRef.current;
        if (!map) return;
        map.fitBounds(boundsFor(route), {
          padding: framePadding(map, insetRef.current),
          animate,
        });
      },
      zoomBy: (delta) => {
        const map = mapRef.current;
        if (!map) return;
        map.easeTo({ zoom: map.getZoom() + delta, duration: 260 });
      },
      focusStop: (index) => {
        const map = mapRef.current;
        const stop = route?.stops[index];
        if (!map || !stop) return;
        map.easeTo({
          center: [stop.lng, stop.lat],
          zoom: Math.max(map.getZoom(), 8.5),
          duration: 700,
          padding: framePadding(map, insetRef.current),
        });
      },
    };
    const ref = handleRef;
    return () => {
      ref.current = null;
    };
  }, [handleRef, route]);

  // ---- layer visibility ----------------------------------------------------
  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;

    const set = (id: string, on: boolean) => {
      if (map.getLayer(id)) {
        map.setLayoutProperty(id, "visibility", on ? "visible" : "none");
      }
    };
    set(LYR_CASING, layers.route);
    set(LYR_LINE, layers.route);
    set(LYR_HALT, layers.halts);
    set(LYR_ACTIVE, layers.halts);
    set(LYR_LABEL, layers.labels);
    for (const id of BASEMAP_RAIL_LAYERS) set(id, layers.network);
    for (const layer of map.getStyle().layers ?? []) {
      if (layer.type === "symbol" && !layer.id.startsWith("railly-")) {
        set(layer.id, layers.places);
      }
    }
  }, [ready, layers]);

  // ---- selection highlight -------------------------------------------------
  useEffect(() => {
    const map = mapRef.current;
    if (!map || !ready) return;

    const stop = activeIndex === null ? null : (route?.stops[activeIndex] ?? null);
    setData(map, SRC_ACTIVE, {
      type: "FeatureCollection",
      features: stop
        ? [
            {
              type: "Feature",
              properties: {},
              geometry: { type: "Point", coordinates: [stop.lng, stop.lat] },
            },
          ]
        : [],
    });
  }, [ready, activeIndex, route]);

  // maplibre's stylesheet forces `position: relative` onto whatever element it
  // mounts into, so the absolutely-positioned box has to be a wrapper.
  return (
    <div className="absolute inset-0">
      <div ref={containerRef} className="h-full w-full" />
    </div>
  );
}
