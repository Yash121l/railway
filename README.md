# Railly

A train tracker for Indian Railways, inspired by [Flighty](https://flighty.com/). One repository holds
the marketing site and a native iOS app: real PNR status, real coach position, real routes drawn on
real track, and a Passport-style logbook of every kilometre you ride.

Railly is a companion app, not a booking app. It sells no tickets and shows no ads, and it deep-links
to IRCTC when you are ready to book. It is not affiliated with Indian Railways or IRCTC.

**Status: pre-launch.** Not on the App Store yet. Live train positions are still projected from the
timetable rather than fetched from a feed, and every screen that shows one labels it as an estimate.

## What's here

| Path | What it is |
| --- | --- |
| `src/` | Next.js 16 marketing site, plus RailLens and a small API over the rail feeds |
| `ios/` | Native SwiftUI app, iOS 17+. This is the product |
| `ios/RaillyWidgets/` | Live Activity extension (lock screen and Dynamic Island) |
| `tools/railshapes/` | Offline pipeline that turns OpenStreetMap ways into per-corridor track geometry |
| `src/data/`, `ios/Railly/Resources/` | Bundled catalog and geometry, byte-identical across platforms |

Stack: Next.js 16 (App Router) · React 19 · Tailwind CSS 4 · TypeScript strict · MapLibre GL ·
SwiftUI. All schedules are IST, fixed at UTC+5:30.

## Where the data comes from

There is no Railly backend. Both clients read public rail feeds directly, and the web app proxies
some of them through its own routes for caching.

- **erail.in** is the source of schedules, routes, platforms, per-halt times, cumulative track
  kilometres, and every station coordinate in the app. `src/lib/rail/erail.ts` and
  `ios/Railly/RailAPI.swift`.
- **ConfirmTkt** answers PNR lookups: per-passenger booking and current status, coach, berth, quota,
  chart state, fare, and the live rake formation. `src/lib/rail/confirmtkt.ts`,
  `ios/Railly/ConfirmTktAPI.swift`.
- **EaseMyTrip** is the PNR fallback when ConfirmTkt is unreachable. iOS only.
- **indianrailapi.com** is a paid, keyed service for live position, PNR, and seat availability. No key
  ships, so this path is dormant. Paste one under Settings → Live Data to enable it.
- **OpenStreetMap** via Overpass supplies rail track geometry, resolved offline into
  `rail-segments.json`. Map tiles come from OpenFreeMap.

These are undocumented endpoints belonging to other companies, not official APIs. Expect them to
change shape without warning. `/api/rail/health` probes the two that matter.

### Catalog coverage

- **4,022 trains** and **9,109 unique station codes** for search and autocomplete, bundled offline
  and identical on both platforms. Note `stations.json` has 9,161 rows: 42 codes are duplicated
  because tourist destinations are aliased to their railhead.
- **12 trains** carry full offline schedules (`seed-trains.json`). Everything else needs one erail
  round trip, cached afterwards.
- **104 corridors** have real OSM track geometry. Those are the 12 seed trains' halt pairs. Any other
  route falls back to a straight line between halts, and the UI says so per route.

## How live positions work

India publishes no open live-position feed, so without an `indianrailapi` key Railly projects each
train along its real route from the published timetable and models delays the way they accumulate.
Those are estimates, and they are labelled as estimates wherever they appear.

The rule that matters: **the line drawn on the map and the position tracked along it are the same
geometry.** Anything that places a train, meaning position, bearing, progress, distance, or speed,
goes through `RailRoute`/`RailRouteCache` in `ios/Railly/RailGeometry.swift` and `src/lib/railshapes.ts`.
Real track kilometres come from erail's own per-halt figure (TRAINROUTE field 6). Straight-line
distance between halts reads 8 to 14 percent short, so it is a labelled last resort, never a
silent one.

## Honesty policy

This is a product rule, not a style preference.

- Nothing fabricated is ever presented as real. The simulator answers demo and snapshot launches
  only; a rejected PNR shows the service's own error rather than a stand-in.
- Anything estimated is labelled where it appears.
- No invented social proof. Illustrative content on the site says it is illustrative.

## Getting started

```bash
npm install
npm run dev        # http://localhost:3000
npm run build      # production build
npx eslint         # Next 16 removed `next lint`
```

`predev` and `prebuild` run `tools/sync-maplibre-worker.mjs`, which copies MapLibre's worker into
`public/maplibre/`. MapLibre cannot resolve its own worker from inside a Next bundle and fails
silently without this, rendering raster tiles and never firing `load`.

For iOS, open `ios/Railly.xcodeproj` in Xcode 16 or newer and run. The authoritative build check is:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project ios/Railly.xcodeproj -scheme Railly \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Trust `xcodebuild`. SourceKit's single-file diagnostics false-positive against the macOS SDK here.

### Regenerating track geometry

```bash
python3 tools/railshapes/build_segments.py
```

It writes both `src/data/rail-segments.json` and `ios/Railly/Resources/RailSegments.json`, and both
must stay in sync. `RailSegments.json` is a build-time bundle resource, so extending coverage needs an
app rebuild. Delete `tools/railshapes/cache/legkm.json` whenever the seed train set changes, or the
per-leg sanity check silently skips new legs. Raw Overpass extracts under `tools/railshapes/cache/`
are gitignored; they regenerate and go stale.

## Known gaps

Honest list, since the alternative is you finding out yourself.

- PNR status has no UI on the web yet, though the API route works and returns coach position.
- Seat availability is a model of PRS booking rules, not live data, unless a paid key is set.
- The `/app` routes are an old web preview capped at the 12 seed trains, kept only until they are
  removed. RailLens is the architecture that replaced them.
- No tests and no CI yet.
- No accounts by design. Trips live on the device, in `Documents/trips.json` on iOS.

## Layout notes

`AGENTS.md` carries the constraints that matter when editing this repo. `docs/plan/` holds the current
development plan.
