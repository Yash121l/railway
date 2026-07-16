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

        var departDate: Date { Date(timeIntervalSince1970: departISO) }
        var arriveDate: Date { Date(timeIntervalSince1970: arriveISO) }
        var chartDate: Date { Date(timeIntervalSince1970: chartISO) }
        var isLate: Bool { delayMinutes > 5 }
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
