"use client";

import { useEffect, useRef } from "react";
import "maplibre-gl/dist/maplibre-gl.css";
import type {
  GeoJSONSource,
  Map as MLMap,
  Marker as MLMarker,
} from "maplibre-gl";
import type { LiveStatus } from "@/lib/types";

const STYLE_URL =
  "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json";

type Coord = [number, number];

function lineFC(coords: Coord[]) {
  return {
    type: "FeatureCollection" as const,
    features:
      coords.length >= 2
        ? [
            {
              type: "Feature" as const,
              properties: {},
              geometry: { type: "LineString" as const, coordinates: coords },
            },
          ]
        : [],
  };
}

function pointFC(coords: Coord[]) {
  return {
    type: "FeatureCollection" as const,
    features: coords.map((c) => ({
      type: "Feature" as const,
      properties: {},
      geometry: { type: "Point" as const, coordinates: c },
    })),
  };
}

/** Flown portion solid, remaining portion dimmed & dashed — Flighty's arc treatment. */
function splitRoute(live: LiveStatus): { done: Coord[]; rest: Coord[] } {
  const coords: Coord[] = live.train.stops.map((s) => [s.lng, s.lat]);
  const pos: Coord = [live.position.lng, live.position.lat];
  if (live.phase === "arrived") return { done: coords, rest: [] };
  if (live.phase !== "enroute") return { done: [], rest: coords };
  return {
    done: [...coords.slice(0, live.prevStopIdx + 1), pos],
    rest: [pos, ...coords.slice(live.nextStopIdx)],
  };
}

export function LiveMap({
  live,
  className = "",
}: {
  live: LiveStatus;
  className?: string;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<MLMap | null>(null);
  const markerRef = useRef<MLMarker | null>(null);
  const readyRef = useRef(false);
  const liveRef = useRef(live);

  useEffect(() => {
    let cancelled = false;

    (async () => {
      // maplibre-gl touches window — load it only in the browser.
      const maplibregl = (await import("maplibre-gl")).default;
      if (cancelled || !containerRef.current) return;

      const stops = liveRef.current.train.stops;
      const lngs = stops.map((s) => s.lng);
      const lats = stops.map((s) => s.lat);

      const map = new maplibregl.Map({
        container: containerRef.current,
        style: STYLE_URL,
        bounds: [
          [Math.min(...lngs), Math.min(...lats)],
          [Math.max(...lngs), Math.max(...lats)],
        ],
        fitBoundsOptions: { padding: { top: 48, bottom: 56, left: 40, right: 40 } },
        attributionControl: { compact: true },
        dragRotate: false,
        pitchWithRotate: false,
      });
      mapRef.current = map;

      map.on("load", () => {
        if (cancelled) return;
        const current = liveRef.current;
        const { done, rest } = splitRoute(current);

        map.addSource("route-rest", { type: "geojson", data: lineFC(rest) });
        map.addSource("route-done", { type: "geojson", data: lineFC(done) });
        map.addSource("stations", {
          type: "geojson",
          data: pointFC(current.train.stops.map((s) => [s.lng, s.lat])),
        });

        map.addLayer({
          id: "route-rest",
          type: "line",
          source: "route-rest",
          layout: { "line-cap": "round" },
          paint: {
            "line-color": "#7eb6f6",
            "line-opacity": 0.5,
            "line-width": 2.5,
            "line-dasharray": [0.1, 2],
          },
        });
        map.addLayer({
          id: "route-done-glow",
          type: "line",
          source: "route-done",
          layout: { "line-cap": "round", "line-join": "round" },
          paint: { "line-color": "#4d9fff", "line-opacity": 0.3, "line-width": 8 },
        });
        map.addLayer({
          id: "route-done",
          type: "line",
          source: "route-done",
          layout: { "line-cap": "round", "line-join": "round" },
          paint: { "line-color": "#4d9fff", "line-width": 3 },
        });
        map.addLayer({
          id: "stations",
          type: "circle",
          source: "stations",
          paint: {
            "circle-radius": 3,
            "circle-color": "#0b0f14",
            "circle-stroke-width": 1.5,
            "circle-stroke-color": "rgba(255,255,255,0.7)",
          },
        });

        const el = document.createElement("div");
        el.className = "railly-train-marker";
        markerRef.current = new maplibregl.Marker({ element: el })
          .setLngLat([current.position.lng, current.position.lat])
          .addTo(map);

        readyRef.current = true;
      });
    })();

    return () => {
      cancelled = true;
      readyRef.current = false;
      markerRef.current = null;
      mapRef.current?.remove();
      mapRef.current = null;
    };
  }, []);

  // Live updates: move the marker and re-split the arc as the train advances.
  useEffect(() => {
    liveRef.current = live;
    const map = mapRef.current;
    if (!map || !readyRef.current) return;
    const { done, rest } = splitRoute(live);
    (map.getSource("route-done") as GeoJSONSource | undefined)?.setData(
      lineFC(done),
    );
    (map.getSource("route-rest") as GeoJSONSource | undefined)?.setData(
      lineFC(rest),
    );
    markerRef.current?.setLngLat([live.position.lng, live.position.lat]);
  }, [live]);

  return <div ref={containerRef} className={className} />;
}
