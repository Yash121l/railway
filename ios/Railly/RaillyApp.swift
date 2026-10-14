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
        Analytics.shared.start()
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
    // Snapshot hooks: `-railly.tab 2` opens a tab, `-railly.detail 12951`
    // boots straight into that train's live trip, `-railly.demo 1` fills the
    // store with an ephemeral demo persona. Absent in normal launches, where
    // the user's own persisted trips load instead.
    @StateObject private var store: TripStore
    @StateObject private var bank: TrainBank
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: Int
    @State private var deepLink: DeepLink?
    @AppStorage("railly.seenEstimatesIntro") private var seenEstimatesIntro = false
    @State private var showEstimatesIntro = false
    private let detailTrain: String?
    private let pnrBoot: String?
    private let isSnapshot: Bool

    /// A `railly://trip/<number>` open, carried into a full-screen detail.
    private struct DeepLink: Identifiable {
        let id = UUID()
        let token: String
    }

    init() {
        configureBarAppearance()
        let defaults = UserDefaults.standard
        let bank = TrainBank.shared
        let store = TripStore.shared
        let snapshotRun = defaults.bool(forKey: "railly.demo")
            || defaults.string(forKey: "railly.detail") != nil
            || defaults.string(forKey: "railly.pnr") != nil
            || defaults.bool(forKey: "railly.onrails")
            || defaults.integer(forKey: "railly.tab") != 0
        if snapshotRun {
            store.seedDemo(bank: bank, now: Date())
        }
        _store = StateObject(wrappedValue: store)
        _bank = StateObject(wrappedValue: bank)
        _tab = State(initialValue: defaults.integer(forKey: "railly.tab"))
        detailTrain = defaults.string(forKey: "railly.detail")
        pnrBoot = defaults.string(forKey: "railly.pnr")
        isSnapshot = snapshotRun
    }

    var body: some View {
        Group {
            if let no = detailTrain, let train = bank.cached(no) {
                NavigationStack {
                    TripDetailView(id: liveTripFor(train, Date()).id)
                }
            } else if let pnr = pnrBoot {
                // `-railly.pnr 8524136972` boots straight into a PNR result
                NavigationStack {
                    PNRResultView(pnr: pnr)
                }
            } else {
                tabs
            }
        }
        .environmentObject(store)
        .environmentObject(bank)
        // The whole palette is the light Flighty theme; without this the
        // TabView/nav chrome renders dark in system dark mode and reads as a
        // black bar under every screen.
        .preferredColorScheme(.light)
        // First real launch: explain the color language and that the live
        // picture is an honest schedule projection. Never during snapshot runs.
        .onAppear {
            if !seenEstimatesIntro && !isSnapshot { showEstimatesIntro = true }
        }
        .sheet(isPresented: $showEstimatesIntro, onDismiss: { seenEstimatesIntro = true }) {
            EstimatesIntroView()
                .preferredColorScheme(.light)
        }
        // A Live Activity tap opens railly://trip/<number>: land on My Trips
        // and push that train's live run, resolving/fetching it if needed.
        .onOpenURL { url in
            guard url.scheme == "railly", url.host == "trip" else { return }
            let number = url.lastPathComponent
            guard !number.isEmpty, number != "/" else { return }
            tab = 0
            deepLink = DeepLink(token: number)
        }
        .fullScreenCover(item: $deepLink) { link in
            NavigationStack {
                ResolveDetailView(token: link.token)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { deepLink = nil }
                                .fontWeight(.semibold)
                        }
                    }
            }
            .environmentObject(store)
            .environmentObject(bank)
            .preferredColorScheme(.light)
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

    private var tabs: some View {
        TabView(selection: $tab) {
            MyTripsView()
                .tabItem { Label("My Trips", systemImage: "tram.fill") }
                .tag(0)
            PNRView()
                .tabItem { Label("PNR", systemImage: "ticket") }
                .tag(1)
            TrackView()
                .tabItem { Label("Track", systemImage: "dot.radiowaves.left.and.right") }
                .tag(2)
            LogbookView()
                .tabItem { Label("Logbook", systemImage: "book.closed") }
                .tag(3)
        }
        .tint(Color.inkline)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.white, for: .tabBar)
        .sensoryFeedback(.selection, trigger: tab)
    }
}

/// First-launch primer: what green/red/amber mean, and why the live picture is
/// an honest schedule projection rather than a GPS feed.
struct EstimatesIntroView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Legend: Identifiable {
        let color: Color
        let title: String
        let detail: String
        var id: String { title }
    }

    private let legend: [Legend] = [
        Legend(color: .onTime, title: "Green is on time",
               detail: "Times run green while the train is keeping to its schedule."),
        Legend(color: .lateRed, title: "Red is running late",
               detail: "More than five minutes behind turns red, origin to destination."),
        Legend(color: .gateAmber, title: "Amber is your platform",
               detail: "Platform numbers wear amber — the one number you scan for on arrival."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.arcBlue)
                .frame(width: 52, height: 52)
                .background(Color(hex: 0xEAF3FF), in: RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 16)

            Text("Estimates, honestly")
                .font(.system(size: 27, weight: .heavy))
                .foregroundStyle(Color.inkline)
            Text("Railly reads the same public timetable the station boards do, then projects where every train should be right now.")
                .font(.system(size: 15))
                .foregroundStyle(Color.subGray)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 18) {
                ForEach(legend) { row in
                    HStack(alignment: .top, spacing: 12) {
                        Circle().fill(row.color)
                            .frame(width: 12, height: 12)
                            .padding(.top, 4)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.inkline)
                            Text(row.detail)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.subGray)
                        }
                    }
                }
            }
            .padding(.top, 26)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.arcBlue)
                Text("Live position, speed and delays are projected from the schedule — not a GPS feed. When a real feed is connected it takes over, and the source is always labelled.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: 0x374151))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 16))
            .padding(.top, 24)

            Spacer(minLength: 20)

            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.arcBlue))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
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
