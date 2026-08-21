import Foundation

/// MAJ product-analytics event schema — ON-DEVICE ONLY. Events append to a
/// bounded ring buffer at Documents/analytics.json and never touch the network:
/// the privacy page promises we disclose and ask before any analytics ship, so
/// this only records locally until that day. The schema is ready when it is.
enum AnalyticsEvent: String, Codable {
    case tripAdded = "trip_added"
    case pnrWatched = "pnr_watched"
    case liveWindowOpen = "live_window_open"
    case laStarted = "la_started"
    case notificationInteracted = "notification_interacted"
    case shareCardSent = "share_card_sent"
    case journeyCompleted = "journey_completed"
}

@MainActor
final class Analytics {
    static let shared = Analytics()

    /// One recorded event: what happened, when, and a few string props.
    struct Entry: Codable, Identifiable {
        let id: UUID
        let event: String
        let at: Date
        let props: [String: String]
    }

    /// Newest `capacity` events survive; the buffer never grows unbounded.
    private let capacity = 500
    private var entries: [Entry] = []

    private let fileURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("analytics.json")
    }()

    private init() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
            entries = decoded
        }
    }

    /// Record an event. Demo/snapshot launches are skipped so marketing runs
    /// never seed the buffer.
    func log(_ event: AnalyticsEvent, _ props: [String: String] = [:]) {
        guard !isSnapshotLaunch() else { return }
        entries.append(Entry(id: UUID(), event: event.rawValue, at: Date(), props: props))
        if entries.count > capacity {
            entries.removeFirst(entries.count - capacity)
        }
        persist()
    }

    /// Everything recorded so far, newest first — for the future in-app
    /// "what we've measured" disclosure screen.
    func recent() -> [Entry] { entries.reversed() }

    /// Drop every recorded event and the file behind it. Part of "delete all my
    /// data": this buffer holds train numbers and timestamps, so leaving it in
    /// place after a delete would contradict the privacy copy.
    func reset() {
        entries = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func persist() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
