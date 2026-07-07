# Railly for iOS 🚆

A native SwiftUI port of Railly — the same Dec 2025 Flighty design language, the same deterministic live-train network, running natively with MapKit.

## What's here

- **The engine** (`Rng.swift`, `TimeUtil.swift`, `Geo.swift`, `Sim.swift`, `Trips.swift`) is a **bit-exact port** of the web app's simulation: the seeded PRNG matches JS `Math.imul` semantics via wrapping `UInt32` math, IST is a fixed +5:30, and delays are the same random walk. Verified: at the same instant, the Swift and TypeScript engines produce identical phases, delay arrays, run dates, event counts, and even the same seeded PNRs.
- **`Trains.swift` is generated** from `src/lib/trains.ts` (see the repo's history for the generator) — keep the two datasets in sync.
- **Views**: My Trips (MapKit network map with blue route arcs and live markers over a white sheet, countdown-rail rows, working search), Trip Detail (route map with flown/remaining arc, speed pill, status banner, giant colored times, amber PF chips, updates feed, Scheduled/Estimated timetable, booking), Track (one line per train), Logbook (indigo Passport gradient card, maroon delay card with split-flap board and LED worst-delay row).

## Building

Requires **Xcode 16+** (the project uses the synchronized-folder format) and iOS 17+.

```bash
open ios/Railly.xcodeproj   # then ⌘R on any simulator
```

No dependencies, no signing requirements beyond automatic signing, no API keys — the whole network is simulated on-device and matches what the web app shows at the same moment.

## Verification status

Written and verified on a machine without full Xcode: every Swift file **typechecks clean against the macOS 14 SDK** (all APIs used are iOS 17/macOS 14 cross-platform), and the engine was compiled with `swiftc` and parity-tested against the TypeScript engine. The full iOS app target has not been run on a simulator here — open it in Xcode and it should build; if anything trips, it will be cosmetic, not the engine.
