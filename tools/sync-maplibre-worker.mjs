#!/usr/bin/env node
/**
 * Copy MapLibre's web worker into `public/maplibre/` so the browser can load
 * it from a stable URL.
 *
 * MapLibre resolves its worker with `new URL('./maplibre-gl-worker.mjs',
 * import.meta.url)`. Inside a Next bundle `import.meta.url` isn't an http URL,
 * so that resolution collapses to the empty string and the worker is spawned
 * against the *page* — it parses the HTML as JavaScript, dies silently, and
 * the map then renders raster tiles only: no vector layers, no route, and
 * `load` never fires. The fix is to serve the worker ourselves and point
 * MapLibre at it with `setWorkerUrl()` (see `src/app/raillens/RouteMap.tsx`).
 *
 * The worker imports `maplibre-gl-shared.mjs` as a sibling, so both files have
 * to land in the same directory.
 *
 * Runs from `predev` and `prebuild`. The output is gitignored — it is a copy
 * of whatever `maplibre-gl` version is installed, and must never drift from it.
 */

import { copyFile, mkdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const FROM = join(ROOT, "node_modules", "maplibre-gl", "dist");
const TO = join(ROOT, "public", "maplibre");

const FILES = ["maplibre-gl-worker.mjs", "maplibre-gl-shared.mjs"];

const version = JSON.parse(
  await readFile(join(ROOT, "node_modules", "maplibre-gl", "package.json"), "utf8"),
).version;

await mkdir(TO, { recursive: true });
for (const file of FILES) {
  await copyFile(join(FROM, file), join(TO, file));
}

console.log(`maplibre worker ${version} → public/maplibre/ (${FILES.join(", ")})`);
