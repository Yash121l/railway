import Foundation

enum TrainCategory: String {
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

enum Day: String, CaseIterable {
    case sun = "Sun", mon = "Mon", tue = "Tue", wed = "Wed", thu = "Thu",
         fri = "Fri", sat = "Sat"
}

struct Stop {
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

struct Train: Identifiable {
    let number: String
    let name: String
    let category: TrainCategory
    /// origin departure "HH:MM", IST
    let departureTime: String
    let days: [Day]
    let distanceKm: Double
    let stops: [Stop]

    var id: String { number }
    var origin: Stop { stops[0] }
    var destination: Stop { stops[stops.count - 1] }
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

/// A journey the user holds a ticket for.
struct HeldTrip: Identifiable {
    let id: String
    let train: Train
    let live: LiveStatus
    let coach: String
    let seat: String
    let pnr: String
}
