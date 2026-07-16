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

/// Polyline coordinates for a run: each leg drawn along the real track where we
/// have it, else as a straight chord. Consecutive legs share their junction
/// point (dropped once) so the line stays continuous.
func railDrawCoords(_ stops: [Stop]) -> [CLLocationCoordinate2D] {
    guard stops.count >= 2 else {
        return stops.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
    }
    var out: [CLLocationCoordinate2D] = []
    for i in 1..<stops.count {
        let a = stops[i - 1], b = stops[i]
        let leg = RailShapes.between(a.code, b.code) ?? [
            CLLocationCoordinate2D(latitude: a.lat, longitude: a.lng),
            CLLocationCoordinate2D(latitude: b.lat, longitude: b.lng),
        ]
        out.append(contentsOf: out.isEmpty ? leg[...] : leg.dropFirst())
    }
    return out
}
