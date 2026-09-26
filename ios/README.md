# Railly for iOS 🚆

A native SwiftUI port of Railly — the same Dec 2025 Flighty design language, the same deterministic live-train network, running natively with MapKit.

## What's here

- **The engine** (`Rng.swift`, `TimeUtil.swift`, `Geo.swift`, `Sim.swift`, `Trips.swift`) is a **bit-exact port** of the web app's simulation: the seeded PRNG matches JS `Math.imul` semantics via wrapping `UInt32` math, IST is a fixed +5:30, and delays are the same random walk. Verified: at the same instant, the Swift and TypeScript engines produce identical phases, delay arrays, run dates, event counts, and even the same seeded PNRs.
- **`Trains.swift` is generated** from `src/lib/trains.ts` (see the repo's history for the generator) — keep the two datasets in sync.
- **One screen** (`AppShell.swift`): a satellite globe (`HomeMap.swift`) under a custom draggable sheet. The sheet shows My Trips (`TripsSheet.swift`, `TripRowView.swift`) or, once a trip is focused, its detail (`TripDetailView.swift`) while the globe flies to the route. There is no tab bar.
- **Modals** hang off the sheet through `Router`: search and add (`AddTripView.swift`), PNR result (`PNRView.swift`), profile with Passport and delay stats (`ProfileView.swift`), settings, and the first-run welcome (`Onboarding.swift`).
- **Design system** (`DesignSystem.swift`): colour tokens, type scale, the one-status-colour rule (`StatusTone`), and the shared components every screen uses.

## Building

Requires **Xcode 16+** (the project uses the synchronized-folder format) and iOS 17+.

```bash
open ios/Railly.xcodeproj   # then ⌘R on any simulator
```

No dependencies, no signing requirements beyond automatic signing, no API keys — the whole network is simulated on-device and matches what the web app shows at the same moment.

## Verification status

Builds with `xcodebuild` (Xcode 27, iOS 27 simulator) and runs in the simulator. Launch arguments for screenshots and UI tests: `-railly.demo 1` (demo trips), `-railly.detail <train>` (focus that train), `-railly.pnr <10 digits>`, `-railly.screen add|profile|settings|large|peek`.
