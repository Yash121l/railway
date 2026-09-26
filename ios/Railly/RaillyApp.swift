import OSLog
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct RaillyApp: App {
    init() {
        // Must register before the first scene is built.
        PNRWatch.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// Opaque white bar chrome for the light Flighty palette, applied once at
/// launch; per-screen treatments (see `mapDetailBar`) override it where the
/// map needs to bleed behind the bar.
private func configureBarAppearance() {
    #if canImport(UIKit)
    let bar = UINavigationBarAppearance()
    bar.configureWithOpaqueBackground()
    bar.backgroundColor = .white
    bar.shadowColor = .clear
    UINavigationBar.appearance().standardAppearance = bar
    UINavigationBar.appearance().scrollEdgeAppearance = bar
    UINavigationBar.appearance().compactAppearance = bar
    #endif
}

@MainActor
struct RootView: View {
    // Snapshot hooks (see `bootSnapshotHooks`): `-railly.demo 1` fills the
    // store with an ephemeral demo persona. Absent in normal launches, where
    // the user's own persisted trips load instead.
    @StateObject private var store: TripStore
    @StateObject private var bank: TrainBank
    @StateObject private var router = Router()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("railly.seenEstimatesIntro") private var seenEstimatesIntro = false
    private let detailTrain: String?
    private let pnrBoot: String?
    private let screenBoot: String?
    private let isSnapshot: Bool

    init() {
        configureBarAppearance()
        let defaults = UserDefaults.standard
        let bank = TrainBank.shared
        let store = TripStore.shared
        let snapshotRun = isSnapshotLaunch()
        if snapshotRun {
            store.seedDemo(bank: bank, now: Date())
        }
        _store = StateObject(wrappedValue: store)
        _bank = StateObject(wrappedValue: bank)
        screenBoot = defaults.string(forKey: "railly.screen")
        detailTrain = defaults.string(forKey: "railly.detail")
        pnrBoot = defaults.string(forKey: "railly.pnr")
        isSnapshot = snapshotRun
    }

    var body: some View {
        HomeView()
        .environmentObject(store)
        .environmentObject(bank)
        .environmentObject(router)
        // The palette is light-sheet-over-dark-globe; system dark mode would
        // turn the sheets black.
        .preferredColorScheme(.light)
        // First real launch: explain the color language and that the live
        // picture is an honest schedule projection. Never during snapshot runs.
        .onAppear {
            router.pendingLaunch = {
                if !seenEstimatesIntro && !isSnapshot {
                    seenEstimatesIntro = true
                    router.present(.intro)
                }
                bootSnapshotHooks()
            }
        }
        // A Live Activity tap opens railly://trip/<number>: focus that train's
        // live run on the globe, fetching the schedule first if needed.
        .onOpenURL { url in
            guard url.scheme == "railly", url.host == "trip" else { return }
            let number = url.lastPathComponent
            guard !number.isEmpty, number != "/" else { return }
            router.showTrain(number)
        }
        // Pull real running status for held trips on a slow tick (no-op until
        // an indianrailapi.com key is set in Settings → Live Data). Only runs
        // inside their live window are polled — arrived and far-future runs
        // never hit the wire.
        .task {
            while !Task.isCancelled {
                if IndianRailAPI.isConfigured {
                    let now = Date()
                    for rec in store.records where inLiveWindow(rec, now: now) {
                        await refreshLive(rec.number, rec.runDate)
                    }
                }
                try? await Task.sleep(for: .seconds(60))
            }
        }
        // `-railly.liveactivity 12951` boots a demo Live Activity for that
        // train's current run — for screenshots and demos.
        .task {
            let no = UserDefaults.standard.string(forKey: "railly.liveactivity")
            Logger(subsystem: "com.yash121l.railly", category: "LiveActivity")
                .info("boot hook: arg=\(no ?? "nil", privacy: .public) cached=\(no.flatMap { bank.cached($0) } != nil, privacy: .public)")
            guard let no, let train = bank.cached(no) else { return }
            // small delay so the scene is fully foreground before requesting
            try? await Task.sleep(for: .seconds(1))
            LiveActivityManager.shared.start(liveTripFor(train, Date()))
        }
        // Opportunistic PNR re-check whenever the app comes forward, so status
        // changes surface even before iOS grants a background window.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            PNRWatch.schedule()
            Task { await PNRWatch.runChecks(force: false) }
        }
    }

    /// True only while a held run is worth polling: boarding or en route, plus
    /// a short linger past arrival to catch the final on-platform update.
    /// Scheduled (far-future) and long-arrived runs return false.
    private func inLiveWindow(_ rec: TripRecord, now: Date) -> Bool {
        guard let train = bank.cached(rec.number) else { return false }
        let status = getLiveStatusForRun(train, runDate: rec.runDate, now: now)
        switch status.phase {
        case .boarding, .enroute:
            return true
        case .arrived:
            return now.timeIntervalSince(status.arrivesEst) < 25 * 60
        case .scheduled:
            return false
        }
    }

    /// Snapshot hooks for screenshots and UI tests:
    /// `-railly.detail 12951` focuses that train's live run,
    /// `-railly.pnr <10 digits>` opens a PNR result,
    /// `-railly.screen add|profile|settings|large` opens a modal or expands the sheet.
    private func bootSnapshotHooks() {
        if let no = detailTrain, let train = bank.cached(no) {
            router.focus(liveTripFor(train, Date()).id)
        }
        if let pnr = pnrBoot {
            router.present(.pnr(pnr))
        }
        switch screenBoot {
        case "add": router.present(.add(prefill: nil))
        case "profile": router.present(.profile)
        case "settings": router.present(.settings)
        case "large": router.detent = Router.large
        case "peek": router.detent = Router.peek
        default: break
        }
    }
}

extension View {
    /// iPad ships the iPhone single-column layout; on regular width, cap it to
    /// a phone-like reading column and center it instead of stretching edge to
    /// edge. A no-op on compact width (iPhone portrait).
    func readableColumn() -> some View {
        modifier(ReadableColumn())
    }
}

private struct ReadableColumn: ViewModifier {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    func body(content: Content) -> some View {
        #if os(iOS)
        if sizeClass == .regular {
            content
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
        } else {
            content
        }
        #else
        content
        #endif
    }
}
