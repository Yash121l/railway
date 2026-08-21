import CoreLocation
import Foundation

/// Real rail-track geometry between halts, bundled from OpenStreetMap by
/// `tools/railshapes/build_segments.py`. erail only gives a train's halts, so a
/// straight chord between two far-apart coastal halts cuts across open water;
/// splicing the actual track shape in between keeps the drawn line on the rails.
///
/// `RailSegments.json` maps a "FROM>TO" station-code pair to an ordered list of
/// `[lat, lng]` points (stored one direction; the reverse is flipped in). Any
/// pair without a bundled segment falls back to a straight chord — so the app
/// works with a partial library or none at all.
enum RailShapes {
    static let segments: [String: [[Double]]] = {
        guard let url = Bundle.main.url(forResource: "RailSegments", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: [[Double]]].self, from: data)
        else { return [:] }
        return dict
    }()

    /// Real intermediate coastal stations for the few corridors where OSM
    /// routing is unreliable (the coastal bbox is huge and Overpass times out),
    /// so the visible water-crossings stay on land regardless. OSM segments
    /// take priority; this is only consulted when the library lacks the leg.
    static let curated: [String: [[Double]]] = [
        // Vijayawada → Chennai down the Bay of Bengal coast, via Ongole,
        // Kavali, Nellore, Gudur, Sullurupeta — all real halts on the line.
        "BZA>MAS": [
            [16.5187, 80.6193], [15.5060, 80.0490], [14.9130, 79.9940],
            [14.4430, 79.9860], [14.1510, 79.8530], [13.7050, 80.0240],
            [13.0825, 80.2754],
        ],
    ]

    /// The bundled track between two halts, forward or reversed, as map coords.
    /// Prefers the OSM library, then the curated coastal fallback.
    static func between(_ from: String, _ to: String) -> [CLLocationCoordinate2D]? {
        for table in [segments, curated] {
            if let seg = table["\(from)>\(to)"] {
                return seg.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
            }
            if let seg = table["\(to)>\(from)"] {
                return seg.reversed().map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
            }
        }
        return nil
    }
}

// MARK: - The tracked route

/// A run's drawn polyline *and* everything tracking needs to sit on it.
///
/// The app used to draw one thing and track another: the drawn line spliced
/// real OSM track shape between halts, but the live position was a straight
/// `lerp` between the two halt coordinates. On any leg with real geometry the
/// train marker therefore drifted off the line it was supposedly running on —
/// most visibly on the coastal legs the OSM splice exists to fix, where the
/// drawn track hugs the shore and the dot cut across open water.
///
/// `RailRoute` resolves that by parameterising the *drawn* polyline: it records
/// which vertex each halt sits at, so a position can be expressed as "fraction
/// of the way along the leg from halt i to halt i+1" and resolved to a real
/// point on the real line, with the real local heading.
struct RailRoute {
    /// The full drawn polyline, origin to destination.
    let coords: [CLLocationCoordinate2D]
    /// Index into `coords` for each halt — `stopVertex.count == stops.count`.
    let stopVertex: [Int]
    /// Cumulative track kilometres at each halt.
    let stopKm: [Double]
    /// True when `stopKm` is the feed's own published track distance rather
    /// than something we measured off the drawn line.
    let kmFromFeed: Bool
    /// Legs drawn along real OSM (or curated) track shape.
    let tracedLegs: Int
    /// Legs drawn as a straight chord for want of a bundled track shape.
    let approximatedLegs: Int

    var totalKm: Double { stopKm.last ?? 0 }

    /// The whole line is guesswork between halts — used to label the map
    /// honestly rather than implying we know the exact path.
    var pathIsApproximate: Bool { tracedLegs == 0 }

    /// Where the train is when it's `frac` (0...1) of the way along the leg
    /// out of halt `leg`, measured along the drawn geometry — plus the heading
    /// of the track it's standing on, and the vertex the position falls after
    /// (so the line can be split at exactly that point).
    func locate(leg: Int, frac: Double) -> (coordinate: CLLocationCoordinate2D,
                                            bearing: Double, afterVertex: Int) {
        guard leg >= 0, leg + 1 < stopVertex.count else {
            let v = min(max(0, stopVertex.last ?? 0), coords.count - 1)
            return (coords[v], 0, v)
        }
        let first = stopVertex[leg]
        let last = stopVertex[leg + 1]
        guard last > first else { return (coords[first], 0, first) }

        // Distances along this leg only, so `frac` means the same thing whether
        // the leg is a two-point chord or an 80-point traced curve.
        var spans: [Double] = []
        var legLength = 0.0
        for i in first..<last {
            let d = haversineKm(coords[i].latitude, coords[i].longitude,
                                coords[i + 1].latitude, coords[i + 1].longitude)
            spans.append(d)
            legLength += d
        }
        guard legLength > 0 else { return (coords[first], 0, first) }

        var target = clamp(frac, 0, 1) * legLength
        for (offset, span) in spans.enumerated() {
            if target <= span || offset == spans.count - 1 {
                let a = coords[first + offset]
                let b = coords[first + offset + 1]
                let t = span > 0 ? clamp(target / span, 0, 1) : 0
                let here = CLLocationCoordinate2D(
                    latitude: lerp(a.latitude, b.latitude, t),
                    longitude: lerp(a.longitude, b.longitude, t))
                return (here,
                        bearingDeg(a.latitude, a.longitude, b.latitude, b.longitude),
                        first + offset)
            }
            target -= span
        }
        return (coords[last], 0, last)
    }

    func point(leg: Int, frac: Double) -> (coordinate: CLLocationCoordinate2D, bearing: Double) {
        let hit = locate(leg: leg, frac: frac)
        return (hit.coordinate, hit.bearing)
    }

    /// The line already covered, ending exactly at the train — cut at the
    /// vertex the train has just passed, so a traced curve stays traced right
    /// up to the marker instead of jumping to it from the last halt.
    func travelled(toLeg leg: Int, frac: Double) -> [CLLocationCoordinate2D] {
        let hit = locate(leg: leg, frac: frac)
        return Array(coords[0...hit.afterVertex]) + [hit.coordinate]
    }

    /// The line still to run, starting exactly at the train.
    func remaining(fromLeg leg: Int, frac: Double) -> [CLLocationCoordinate2D] {
        let hit = locate(leg: leg, frac: frac)
        let next = hit.afterVertex + 1
        guard next < coords.count else { return [hit.coordinate] }
        return [hit.coordinate] + Array(coords[next...])
    }
}

/// Build the drawn-and-tracked route for a set of halts.
///
/// Kilometres come from the best source available, in order:
///  1. the feed's own per-halt track distance (`Stop.distanceKm`) — exact;
///  2. the drawn polyline's own length, rescaled so the route totals the
///     train's declared distance — exact total, proportional halt marks;
///  3. the raw polyline length, which is right wherever we have real track
///     shape and a straight chord elsewhere.
///
/// The old code always used straight chords, which read up to 10% short and
/// dragged every derived number (progress, distance covered, speed) short
/// with it.
func buildRailRoute(_ stops: [Stop], declaredTotalKm: Double = 0) -> RailRoute {
    guard stops.count >= 2 else {
        let coords = stops.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
        return RailRoute(coords: coords, stopVertex: Array(coords.indices),
                         stopKm: Array(repeating: 0, count: coords.count),
                         kmFromFeed: false, tracedLegs: 0, approximatedLegs: 0)
    }

    var coords: [CLLocationCoordinate2D] = []
    var stopVertex: [Int] = []
    var polylineKm: [Double] = [0]
    var traced = 0
    var approximated = 0

    for i in 1..<stops.count {
        let a = stops[i - 1]
        let b = stops[i]
        let shape = RailShapes.between(a.code, b.code)
        if shape != nil { traced += 1 } else { approximated += 1 }
        let leg = shape ?? [
            CLLocationCoordinate2D(latitude: a.lat, longitude: a.lng),
            CLLocationCoordinate2D(latitude: b.lat, longitude: b.lng),
        ]
        if coords.isEmpty {
            stopVertex.append(0)
            coords.append(leg[0])
        }
        var legKm = 0.0
        for point in leg.dropFirst() {
            legKm += haversineKm(coords[coords.count - 1].latitude,
                                 coords[coords.count - 1].longitude,
                                 point.latitude, point.longitude)
            coords.append(point)
        }
        stopVertex.append(coords.count - 1)
        polylineKm.append(polylineKm[i - 1] + legKm)
    }

    // The feed's distances only stand in if it published one for every halt and
    // they climb monotonically — a partial or scrambled column is worse than
    // measuring the line ourselves.
    let feedKm = stops.map(\.distanceKm)
    let usableFeedKm: [Double]? = {
        let values = feedKm.compactMap { $0 }
        guard values.count == feedKm.count else { return nil }
        for i in 1..<values.count where values[i] < values[i - 1] { return nil }
        guard let total = values.last, total > 0 else { return nil }
        return values
    }()

    // Without per-halt distances, the polyline still reads short across legs we
    // haven't traced. The train's declared total *is* real feed data, so stretch
    // the measured shape onto it: the total becomes exact and each halt keeps
    // its proportional place along the line.
    let measuredTotal = polylineKm.last ?? 0
    let scaledKm: [Double] = {
        guard usableFeedKm == nil, declaredTotalKm > 0, measuredTotal > 0 else { return polylineKm }
        let k = declaredTotalKm / measuredTotal
        return polylineKm.map { $0 * k }
    }()

    return RailRoute(
        coords: coords,
        stopVertex: stopVertex,
        stopKm: usableFeedKm ?? scaledKm,
        kmFromFeed: usableFeedKm != nil,
        tracedLegs: traced,
        approximatedLegs: approximated
    )
}

/// Routes are rebuilt on every status tick (and `TimelineView` ticks often), so
/// the spliced polyline is memoised per train. Keyed by number *and* halt count
/// so a schedule refresh that adds halts doesn't serve a stale line.
enum RailRouteCache {
    private static let lock = NSLock()
    private static var cache: [String: RailRoute] = [:]

    static func route(for train: Train) -> RailRoute {
        let key = "\(train.number):\(train.stops.count):\(train.stops.last?.arrMin ?? 0)"
        lock.lock()
        if let hit = cache[key] {
            lock.unlock()
            return hit
        }
        lock.unlock()

        let built = buildRailRoute(train.stops, declaredTotalKm: train.distanceKm)
        lock.lock()
        // A handful of routes is all a session touches; clear rather than grow
        // unbounded if someone browses a lot of trains.
        if cache.count > 24 { cache.removeAll() }
        cache[key] = built
        lock.unlock()
        return built
    }
}
