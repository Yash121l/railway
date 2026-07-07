"use client";

import { useEffect, useRef } from "react";
import { getLiveStatus } from "@/lib/sim";
import { TRAINS } from "@/lib/trains";

/**
 * flighty.com puts a live globe in its dark section; Railly puts the real
 * network. Every arc is an actual route from trains.ts and every glowing
 * dot is a train positioned by the same deterministic simulation the app
 * runs — this canvas IS the product, not an illustration of it.
 */
export function NetworkCanvas({ className = "" }: { className?: string }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const still = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    // fit India's rail bounds into the canvas with padding
    const lats = TRAINS.flatMap((t) => t.stops.map((s) => s.lat));
    const lngs = TRAINS.flatMap((t) => t.stops.map((s) => s.lng));
    const minLat = Math.min(...lats) - 1.2;
    const maxLat = Math.max(...lats) + 1.2;
    const minLng = Math.min(...lngs) - 1.2;
    const maxLng = Math.max(...lngs) + 1.2;

    let w = 0;
    let h = 0;
    let raf = 0;
    let running = false;

    const px = (lng: number) => ((lng - minLng) / (maxLng - minLng)) * w;
    const py = (lat: number) => ((maxLat - lat) / (maxLat - minLat)) * h;

    const draw = () => {
      const now = new Date();
      ctx.clearRect(0, 0, w, h);

      // routes
      for (const train of TRAINS) {
        ctx.beginPath();
        train.stops.forEach((s, i) => {
          if (i === 0) ctx.moveTo(px(s.lng), py(s.lat));
          else ctx.lineTo(px(s.lng), py(s.lat));
        });
        ctx.strokeStyle = "rgba(77, 159, 255, 0.34)";
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.stroke();

        // stations
        for (const s of train.stops) {
          ctx.beginPath();
          ctx.arc(px(s.lng), py(s.lat), 1.6, 0, Math.PI * 2);
          ctx.fillStyle = "rgba(255,255,255,0.4)";
          ctx.fill();
        }
      }

      // live trains
      for (const train of TRAINS) {
        const live = getLiveStatus(train, now);
        if (live.phase !== "enroute") continue;
        const x = px(live.position.lng);
        const y = py(live.position.lat);

        const glow = ctx.createRadialGradient(x, y, 0, x, y, 13);
        glow.addColorStop(0, "rgba(77, 159, 255, 0.85)");
        glow.addColorStop(1, "rgba(77, 159, 255, 0)");
        ctx.beginPath();
        ctx.arc(x, y, 13, 0, Math.PI * 2);
        ctx.fillStyle = glow;
        ctx.fill();

        ctx.beginPath();
        ctx.arc(x, y, 3.2, 0, Math.PI * 2);
        ctx.fillStyle = "#ffffff";
        ctx.fill();
        ctx.lineWidth = 2;
        ctx.strokeStyle = "#4d9fff";
        ctx.stroke();
      }
    };

    const loop = () => {
      draw();
      if (running && !still) raf = requestAnimationFrame(loop);
    };

    const resize = () => {
      const rect = canvas.getBoundingClientRect();
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      w = rect.width;
      h = rect.height;
      canvas.width = Math.round(w * dpr);
      canvas.height = Math.round(h * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      if (!running) draw();
    };

    const ro = new ResizeObserver(resize);
    ro.observe(canvas);

    const io = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !running) {
        running = true;
        raf = requestAnimationFrame(loop);
      } else if (!entry.isIntersecting) {
        running = false;
        cancelAnimationFrame(raf);
      }
    });
    io.observe(canvas);

    return () => {
      running = false;
      cancelAnimationFrame(raf);
      ro.disconnect();
      io.disconnect();
    };
  }, []);

  return <canvas ref={ref} aria-hidden className={`block ${className}`} />;
}
