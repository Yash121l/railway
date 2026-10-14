import Foundation
import PostHog

/// Product-analytics event schema. Events append to a bounded on-device ring
/// buffer at Documents/analytics.json and, in release builds with analytics
/// switched on (Settings → Privacy, on by default and disclosed on the
/// privacy page), are also sent to PostHog. Props are train numbers, sources
/// and card kinds only: never a PNR, passenger status, or the user's trips.
enum AnalyticsEvent: String, Codable {
    case pnrCheckCompleted = "pnr_check_completed"
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

    /// Public PostHog project key (phc_ client key, safe to ship in the binary).
    private static let postHogKey = "phc_oLm8fb7L4CXDqGdJcc7a6boCtR8rVjf6dNx7G995eGdy"
    /// Mirrors the Settings → Privacy toggle. Missing means on.
    static let enabledDefaultsKey = "railly.analyticsEnabled"

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledDefaultsKey) as? Bool ?? true
    }

    /// Whether PostHog was set up this launch (release builds, real launches).
    private(set) var remoteStarted = false

    /// Starts PostHog. Skipped in debug builds and demo/snapshot launches so
    /// development and marketing runs never reach the shared project.
    func start() {
        #if !DEBUG
        guard !isSnapshotLaunch(), !remoteStarted else { return }
        let config = PostHogConfig(projectToken: Self.postHogKey, host: "https://us.i.posthog.com")
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = true
        config.errorTrackingConfig.autoCapture = true
        #if os(iOS)
        config.sessionReplay = true
        config.sessionReplayConfig.maskAllTextInputs = true
        config.sessionReplayConfig.maskAllImages = false
        #endif
        // A choice persisted by the SDK wins over this on later launches;
        // setEnabled keeps the two in step.
        config.optOut = !Self.isEnabled
        PostHogSDK.shared.setup(config)
        PostHogSDK.shared.register(["app": "railway"])
        remoteStarted = true
        #endif
    }

    /// Settings → Privacy toggle.
    func setEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: Self.enabledDefaultsKey)
        guard remoteStarted else { return }
        if on { PostHogSDK.shared.optIn() } else { PostHogSDK.shared.optOut() }
    }

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
        if remoteStarted {
            PostHogSDK.shared.capture(event.rawValue, properties: props)
        }
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
        // New anonymous id from here on. reset() also clears the SDK's stored
        // opt-out, so re-apply the user's choice.
        if remoteStarted {
            PostHogSDK.shared.reset()
            PostHogSDK.shared.register(["app": "railway"])
            if !Self.isEnabled { PostHogSDK.shared.optOut() }
        }
    }

    private func persist() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
