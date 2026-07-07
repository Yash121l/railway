# Railly — the Flighty of train travel 🚆

**Get the truth when you take the train.** Railly reimagines [Flighty](https://flighty.com/) — the Apple Design Award-winning flight tracker — for Indian Railways: live train tracking, delay predictions before the railway announces them, platform-change alerts, and a Passport-style logbook. One codebase ships both the flighty.com-style marketing site and the app itself.

Built with **Next.js 16 · React 19 · Tailwind CSS 4 · MapLibre GL · TypeScript (strict)**, plus a **native iOS app (SwiftUI + MapKit)** in [`ios/`](ios/) whose engine is a bit-exact port of the web simulation. No backend, no API keys — see [how the live network works](#how-the-live-network-works).

![Marketing site](docs/screens/landing.png)

|  My Trips  |  Trip detail  |  Track  |
| :---: | :---: | :---: |
| ![My Trips](docs/screens/my-trips.png) | ![Trip detail](docs/screens/trip-detail.png) | ![Track board](docs/screens/track.png) |

|  Logbook  |  Delay report  |
| :---: | :---: |
| ![Logbook](docs/screens/logbook.png) | ![Delay report](docs/screens/delay-report.png) |

## What's inside

**Marketing site (`/`)** — a faithful flighty.com structural clone, re-copywritten for rail: announcement bar, floating pill nav, hero with auto-cycling notification cards orbiting a phone mockup, dark press-quote wall with hover crossfade, alternating feature journey, Friends, Passport teaser, a dark "Network Intelligence" live board, masonry testimonial wall, INR pricing, and the full footer. Scroll reveals respect `prefers-reduced-motion`.

**The app (`/app`)** — the Dec 2025 Flighty design language (studied from 119 real iOS screenshots), applied to trains:

- **My Trips** — a live network map (every route as a glowing blue arc, live trains as markers) behind a white sheet: "My Trips ⌄", a working "Search to add trains" field, and one dense row per journey — huge countdown numerals or an ON RAILS badge on the left rail, bold city pairs, and dep/arr time cells whose whole cluster flips green/red with status (`+1` superscripts for next-day arrivals).
- **Trip detail** (`/app/trip/[id]`) — dark MapLibre map with the flown route solid blue and the remainder dashed, a live speed pill, then the sheet: mint/rose status banner with a plain-English explanation, giant colored times with struck-through scheduled ones, amber platform chips, live-run stats, a delay-explanation **Updates feed**, a Scheduled/Estimated timetable for every halt, 60-day arrival-forecast histogram, a *Where's My Rake?* card, operator contact card, route history, booking tiles, and a floating action bar with the purple **Get Pro** pill.
- **Track** (`/app/track`) — the whole network as a one-line-per-train live board.
- **Logbook** (`/app/logbook`) — the Flighty Passport treatment: an indigo-gradient ALL-TIME RAILLY PASSPORT stat card, a maroon delay report with a **CSS split-flap board** and amber dot-matrix worst-delay row, a lavender most-ridden-train card, and the past-trips log.

## How the live network works

There is no backend. Eight real Indian Railways services (Mumbai & Howrah Rajdhani, two Vande Bharats, Shatabdi, Duronto, Coromandel and Karnataka Express) carry researched public timetables with station coordinates in [`src/lib/trains.ts`](src/lib/trains.ts).

The simulation ([`src/lib/sim.ts`](src/lib/sim.ts)) makes the network a **pure function of (train, date, time)**: per-run delays are a seeded random walk over the timetable (with occasional incident jolts and recoveries), positions interpolate along the route between stops, and the event feed — departures, delay explanations, platform changes — derives from the same seed. Every client on Earth renders the identical "live" network, it evolves in real time, and premium trains are measurably more punctual than the humble Superfast, just like real life.

Departures are staggered 06:00–19:20 IST across 6–38 h journeys, so something is always running.

**Native iOS app ([`ios/`](ios/))** — SwiftUI + MapKit, iOS 17+. The simulation engine is a bit-exact Swift port (same seeded PRNG, same IST math): at any instant the iPhone app and the web app show the identical live network. `open ios/Railly.xcodeproj` in Xcode 16+ and run. Details in [`ios/README.md`](ios/README.md).

## Getting started

```bash
npm install
npm run dev     # http://localhost:3000  (site) · /app (the app)
```

`npm run build` produces the production build; `npx eslint .` lints (Next 16 removed `next lint`).

## Project structure

```
src/
  app/
    page.tsx              marketing landing page
    app/                  the Railly app (dark, phone-column shell)
      page.tsx            My Trips
      trip/[id]/          live trip detail + map
      track/              network board
      logbook/            Passport-style stats
  components/
    marketing/            hero orbit, press wall, feature journey, pricing…
    app/                  trip cards, live map, status pills, tab bar…
  lib/
    trains.ts             researched timetables + coordinates
    sim.ts                deterministic live-network engine
    trips.ts              the demo persona's tickets, derived live
    geo.ts · rng.ts · time.ts · format.ts · types.ts
```

## Design system

Tokens live in [`src/app/globals.css`](src/app/globals.css). The marketing site follows a Flighty style reference: white "departure board" canvas, `#0d0021` violet "control room" sections, exactly two chromatic signals (action blue `#007bff`, conversion amber `#f7be00`). The app follows the Dec 2025 Flighty iOS release: white sheets over a dark map, `#f2f2f5` fills and hairline dividers, status green `#1e9e4a` / red `#d93025` owning entire time clusters, amber `#f6c445` platform chips, iOS blue actions, Pro purple `#7c3aed` — system-ui type, tabular numerals everywhere, uppercase micro-labels.

---

*A design-study demo. Not affiliated with Indian Railways or Flighty; timetables are approximations and lifetime stats are illustrative.*
