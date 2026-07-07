"use client";

import { useEffect, useRef } from "react";
import "maplibre-gl/dist/maplibre-gl.css";
import type { Map as MLMap, Marker as MLMarker } from "maplibre-gl";
import { getLiveStatus } from "@/lib/sim";
import { TRAINS } from "@/lib/trains";

const STYLE_URL =
  "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json";

/**
 * The ambient hero behind the home sheet: every route as a blue arc on the
 * dark world, live trains as glowing markers — Flighty's globe, for rail.
 */
export function NetworkMap({ className = "" }: { className?: string }) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<MLMap | null>(null);
  const markersRef = useRef<Map<string, MLMarker>>(new Map());

  useEffect(() => {
    let cancelled = false;
    let timer: ReturnType<typeof setInterval> | undefined;
    const markers = markersRef.current;

    (async () => {
      const maplibregl = (await import("maplibre-gl")).default;
      if (cancelled || !containerRef.current) return;

      const map = new maplibregl.Map({
        container: containerRef.current,
        style: STYLE_URL,
        bounds: [
          [70.5, 8.5],
          [90.5, 30.5],
        ],
        fitBoundsOptions: { padding: 24 },
        attributionControl: { compact: true },
        dragRotate: false,
        pitchWithRotate: false,
      });
      mapRef.current = map;

      map.on("load", () => {
        if (cancelled) return;

        map.addSource("routes", {
          type: "geojson",
          data: {
            type: "FeatureCollection",
            features: TRAINS.map((t) => ({
              type: "Feature" as const,
              properties: {},
              geometry: {
                type: "LineString" as const,
                coordinates: t.stops.map((s) => [s.lng, s.lat]),
              },
            })),
          },
        });
        // Soft glow underlay + crisp core, Flighty's arc treatment.
        map.addLayer({
          id: "routes-glow",
          type: "line",
          source: "routes",
          layout: { "line-cap": "round", "line-join": "round" },
          paint: { "line-color": "#4d9fff", "line-opacity": 0.22, "line-width": 6 },
        });
        map.addLayer({
          id: "routes-core",
          type: "line",
          source: "routes",
          layout: { "line-cap": "round", "line-join": "round" },
          paint: { "line-color": "#7eb6f6", "line-opacity": 0.85, "line-width": 1.8 },
        });

        const endpoints = TRAINS.flatMap((t) => [
          t.stops[0],
          t.stops[t.stops.length - 1],
        ]);
        map.addSource("terminals", {
          type: "geojson",
          data: {
            type: "FeatureCollection",
            features: endpoints.map((s) => ({
              type: "Feature" as const,
              properties: {},
              geometry: { type: "Point" as const, coordinates: [s.lng, s.lat] },
            })),
          },
        });
        map.addLayer({
          id: "terminals",
          type: "circle",
          source: "terminals",
          paint: {
            "circle-radius": 3,
            "circle-color": "#0b0f14",
            "circle-stroke-width": 1.5,
            "circle-stroke-color": "rgba(255,255,255,0.85)",
          },
        });

        const placeMarkers = () => {
          const now = new Date();
          for (const train of TRAINS) {
            const live = getLiveStatus(train, now);
            const key = train.number;
            const existing = markers.get(key);
            if (live.phase === "enroute") {
              if (existing) {
                existing.setLngLat([live.position.lng, live.position.lat]);
              } else {
                const el = document.createElement("div");
                el.className = "railly-train-marker railly-train-marker--small";
                markers.set(
                  key,
                  new maplibregl.Marker({ element: el })
                    .setLngLat([live.position.lng, live.position.lat])
                    .addTo(map),
                );
              }
            } else if (existing) {
              existing.remove();
              markers.delete(key);
            }
          }
        };
        placeMarkers();
        timer = setInterval(placeMarkers, 5_000);
      });
    })();

    return () => {
      cancelled = true;
      if (timer) clearInterval(timer);
      markers.clear();
      mapRef.current?.remove();
      mapRef.current = null;
    };
  }, []);

  return <div ref={containerRef} className={className} />;
}
