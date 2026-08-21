import ActivityKit
import Foundation

/// The Live Activity contract, shared verbatim by the app (which starts and
/// updates the activity) and the widget extension (which renders it). Keep
/// this file dependency-free — only ActivityKit + Foundation — so it compiles
/// cleanly into BOTH targets. Combined attributes + state must stay under 4 KB.
struct TrainActivityAttributes: ActivityAttributes {
    /// The moving parts, re-sent on every update.
    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable, Hashable {
            /// a waitlisted/RAC ticket counting down to (and through) chart
            /// preparation — the moment its fate is sealed
            case charting
            case preDeparture, enRoute, arrived
        }
        var phase: Phase
        /// destination delay in minutes (the number that decides the color)
        var delayMinutes: Int
        /// 0…1 along the route
        var progress: Double
        /// next halt the train reaches (or the boarding station pre-departure)
        var nextStopName: String
        var nextStopCode: String
        /// departure platform, when known
        var platform: String?
        var speedKmh: Int
        /// one-line "why" ("Late rake en route from BCT", "Running to time")
        var statusLine: String
        /// scheduled/expected departure, epoch seconds — drives the countdown
        var departISO: Double
        /// expected arrival, epoch seconds — drives the arrival countdown
        var arriveISO: Double
        /// chart-preparation time, epoch seconds — drives the .charting countdown
        var chartISO: Double = 0
        /// true once the reservation chart has been prepared (the fate is sealed)
        var chartPrepared: Bool = false
        /// pre-chart position shown while the chart counts down ("WL 12", "RAC 5")
        var waitlistStatus: String = ""
        /// resolved allotment shown once charted ("B2 · 34 LB")
        var berthAllotment: String = ""
        /// expected arrival at `nextStopName`, epoch seconds
        var nextStopISO: Double = 0

        var departDate: Date { Date(timeIntervalSince1970: departISO) }
        var arriveDate: Date { Date(timeIntervalSince1970: arriveISO) }
        var chartDate: Date { Date(timeIntervalSince1970: chartISO) }
        var nextStopDate: Date { Date(timeIntervalSince1970: nextStopISO) }
        var isLate: Bool { delayMinutes > 5 }

        /// "2h 33m", "45m". Indian long-distance runs lose hours, not minutes,
        /// so a raw minute count ("153m late") stops being readable fast.
        /// `fmtDuration` in the app does this too, but TimeUtil.swift isn't in
        /// the widget target — this file is the only one both targets compile.
        static func durationText(minutes: Int) -> String {
            let m = abs(minutes)
            let h = m / 60
            let rest = m % 60
            if h == 0 { return "\(rest)m" }
            if rest == 0 { return "\(h)h" }
            return "\(h)h \(rest)m"
        }

        /// The delay as the card states it.
        var delayText: String {
            isLate ? "\(Self.durationText(minutes: delayMinutes)) late" : "On time"
        }

        /// Tighter form for the Dynamic Island, where width is scarce.
        var delayShort: String {
            isLate ? "+\(Self.durationText(minutes: delayMinutes))" : "On time"
        }
    }

    // Fixed for the life of the run.
    var trainNumber: String
    var trainName: String
    var originCode: String
    var originCity: String
    var destinationCode: String
    var destinationCity: String
    /// two-letter class monogram for the badge ("RJ", "VB", "SF"…)
    var monogram: String
    /// badge fill, packed as 0xRRGGBB so the widget can rebuild the Color
    var liveryHex: UInt32
}
