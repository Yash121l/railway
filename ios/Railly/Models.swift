import Foundation

enum TrainCategory: String, Codable {
    case rajdhani
    case vandeBharat = "vande-bharat"
    case shatabdi
    case duronto
    case tejas
    case superfast
    case express

    var label: String {
        switch self {
        case .rajdhani: return "Rajdhani"
        case .vandeBharat: return "Vande Bharat"
        case .shatabdi: return "Shatabdi"
        case .duronto: return "Duronto"
        case .tejas: return "Tejas"
        case .superfast: return "Superfast"
        case .express: return "Express"
        }
    }
}

enum Day: String, Codable, CaseIterable {
    case sun = "Sun", mon = "Mon", tue = "Tue", wed = "Wed", thu = "Thu",
         fri = "Fri", sat = "Sat"
}

struct Stop: Codable {
    let name: String
    let code: String
    let lat: Double
    let lng: Double
    /// minutes after origin departure the train arrives here (0 at origin)
    let arrMin: Int
    /// minutes after origin departure the train departs (== arrMin at destination)
    let depMin: Int
    let platform: String?
}

/// A real Indian Railways service. Everything here comes from the live
/// erail.in feed (or the bundled seed cache fetched from it) — schedules,
/// platforms, coordinates, run days, and classes are real data.
struct Train: Identifiable, Codable {
    let number: String
    /// raw feed name, ALL-CAPS and truncated ("NDLS TEJAS RAJ") — display
    /// via `displayName`
    let name: String
    let category: TrainCategory
    /// origin departure "HH:MM", IST
    let departureTime: String
    let days: [Day]
    let distanceKm: Double
    let stops: [Stop]
    /// erail's internal id, needed for the TRAINROUTE call
    let trainId: Int
    /// feed service type ("RAJDHANI", "SUPERFAST", …)
    let typeName: String
    /// coach classes on the rake ("1A", "2A", "3A", "CC", …)
    let classes: [String]

    var id: String { number }
    var origin: Stop { stops[0] }
    var destination: Stop { stops[stops.count - 1] }
    var displayName: String { prettyTrainName(name) }
}

enum RunPhase {
    case scheduled, boarding, enroute, arrived
}

struct StopTiming {
    let arrSched: Date
    let arrEst: Date
    let depSched: Date
    let depEst: Date
    let delayMin: Int
    var passed: Bool
    var current: Bool
}

enum TrainEventKind {
    case departed, stop, delay, recovery, platform, arrived
    /// journey-companion grammar for 30h+ runs: a scheduled long halt and the
    /// morning position summary
    case halt, summary
}

struct TrainEvent {
    let time: Date
    let kind: TrainEventKind
    let text: String
    let detail: String?
}

struct LiveStatus {
    let train: Train
    let runDate: String
    let phase: RunPhase
    /// current delay in minutes (interpolated between stops)
    let delayMin: Int
    let positionLat: Double
    let positionLng: Double
    let bearing: Double
    let speedKmh: Int
    let prevStopIdx: Int
    let nextStopIdx: Int
    let atStation: Bool
    let stopTimings: [StopTiming]
    let progressKm: Double
    let totalKm: Double
    /// 0...1 along the route polyline
    let progress: Double
    let departsAt: Date
    let arrivesSched: Date
    let arrivesEst: Date
    let events: [TrainEvent]
}

/// A journey on a specific run date. `isHeld` distinguishes the user's own
/// ticketed trips (persisted in TripStore) from trains merely being watched.
struct HeldTrip: Identifiable {
    let id: String
    let train: Train
    let live: LiveStatus
    /// Ticket details — only present when the user actually has a booking (or
    /// for seeded demo trips). A train merely being tracked has none, so the
    /// detail screen shows no fabricated PNR/seat.
    let booking: Booking?
    let isHeld: Bool
}
