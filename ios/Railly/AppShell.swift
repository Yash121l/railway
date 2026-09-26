import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Railly has one screen: a satellite globe with a white sheet floating over
/// it. The sheet shows My Trips, or — when a journey is focused — that trip's
/// detail, while the globe flies to its route. Everything else (add, PNR,
/// profile, settings) is a modal presented from the sheet.
@MainActor
final class Router: ObservableObject {
    enum Modal: Identifiable, Equatable {
        /// Search/add flow, optionally prefilled ("12951", "8524136972");
        /// `pnrMode` opens straight into PNR entry.
        case add(prefill: String?, pnrMode: Bool = false)
        /// A PNR result.
        case pnr(String)
        /// Look up any train by number and focus its current run.
        case train(String)
        case profile
        case settings
        /// First-launch welcome.
        case intro

        var id: String {
            switch self {
            case .add(let p, let pnr): return "add:\(p ?? ""):\(pnr)"
            case .pnr(let p): return "pnr:\(p)"
            case .train(let t): return "train:\(t)"
            case .profile: return "profile"
            case .settings: return "settings"
            case .intro: return "intro"
            }
        }
    }

    /// The trip whose detail fills the sheet; nil shows My Trips.
    @Published private(set) var focusedTripId: String?
    @Published var modal: Modal?
    @Published var detent: SheetDetent = Router.medium

    static let peek = SheetDetent.peek
    static let medium = SheetDetent.medium
    static let large = SheetDetent.large

    /// Opens a journey in the sheet and flies the globe to it. Closes any modal.
    func focus(_ tripId: String) {
        modal = nil
        withAnimation(.snappy(duration: 0.42)) { focusedTripId = tripId }
        if detent == Router.peek {
            withAnimation(SheetDetent.spring) { detent = Router.medium }
        }
    }

    func unfocus() {
        withAnimation(.snappy(duration: 0.42)) { focusedTripId = nil }
    }

    func present(_ modal: Modal) { self.modal = modal }

    /// Focuses a train's current run, or fetches its schedule first when it
    /// isn't cached. Cached trains skip the lookup modal entirely.
    func showTrain(_ number: String) {
        if let train = TrainBank.shared.cached(number) {
            focus(liveTripFor(train, Date()).id)
        } else {
            present(.train(number))
        }
    }

    /// Launch-time work that needs the sheet on screen before it can present:
    /// set by RootView, run once by the sheet.
    var pendingLaunch: (() -> Void)?

    func runPendingLaunch() {
        let work = pendingLaunch
        pendingLaunch = nil
        work?()
    }
}

/// The sheet's resting heights.
enum SheetDetent: CaseIterable {
    case peek, medium, large

    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.86)

    func height(screen: CGFloat, topInset: CGFloat) -> CGFloat {
        switch self {
        case .peek: return 118
        case .medium: return (screen * 0.54).rounded()
        // below the status bar with a sliver of globe showing; includes the
        // sheet's own 14pt grabber padding so the stack never outgrows the screen
        case .large: return screen - topInset - 26
        }
    }
}

@MainActor
struct HomeView: View {
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @EnvironmentObject private var router: Router

    /// A plain clock rather than a TimelineView, so router changes re-render
    /// the globe immediately instead of waiting for the next tick.
    @State private var now = Date()
    /// Measured once from the layout; reading UIKit window insets inside a body
    /// silently stopped SwiftUI from re-rendering the view.
    @State private var topInset: CGFloat = 54
    @GestureState private var drag: CGFloat = 0

    var body: some View {
        let screen = screenHeight
        let top = topInset
        let resting = router.detent.height(screen: screen, topInset: top)
        let live = min(SheetDetent.large.height(screen: screen, topInset: top),
                       max(SheetDetent.peek.height(screen: screen, topInset: top) * 0.8, resting - drag))
        let trips = store.myTrips(now, bank: bank)

        ZStack(alignment: .bottom) {
            HomeMapView(
                trips: trips.live + trips.upcoming,
                focused: router.focusedTripId.flatMap { getTrip($0, now) },
                now: now,
                bottomInset: resting,
                topInset: top
            )
            .ignoresSafeArea()

            // A custom sheet, not .sheet: a native sheet stops the views
            // beneath it from re-rendering on iOS 26+, which froze the globe.
            SheetRoot()
                .frame(maxWidth: .infinity)
                .frame(height: live, alignment: .top)
                .padding(.top, 14)
                .background(DS.sheet)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: DS.sheetRadius, topTrailingRadius: DS.sheetRadius, style: .continuous))
                .overlay(alignment: .top) { grabber(screen: screen, top: top) }
                .shadow(color: .black.opacity(0.18), radius: 24, y: -2)
                .scrollDisabled(router.detent != Router.large)
                // high priority: the sheet moves under the finger, so a drag
                // that starts on a button would otherwise end as its tap
                .highPriorityGesture(router.detent == Router.large ? nil : sheetDrag(screen: screen, top: top))
                .environment(\.colorScheme, .light)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { topInset = geo.safeAreaInsets.top }
                    .onChange(of: geo.safeAreaInsets.top) { _, new in topInset = new }
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                now = Date()
            }
        }
    }

    /// The grabber doubles as the drag handle at every detent, including
    /// large, where the content's own scrolling owns the rest of the sheet.
    private func grabber(screen: CGFloat, top: CGFloat) -> some View {
        Capsule()
            .fill(DS.fill2)
            .frame(width: 38, height: 5)
            .padding(.top, 7)
            .frame(maxWidth: .infinity)
            .frame(height: 30, alignment: .top)
            .contentShape(Rectangle())
            .gesture(sheetDrag(screen: screen, top: top))
            .accessibilityLabel("Sheet")
            .accessibilityValue(router.detent == Router.large ? "Expanded" : router.detent == Router.peek ? "Collapsed" : "Half height")
            .accessibilityAction(named: "Expand") { withAnimation(SheetDetent.spring) { router.detent = Router.large } }
            .accessibilityAction(named: "Collapse") { withAnimation(SheetDetent.spring) { router.detent = Router.peek } }
    }

    private func sheetDrag(screen: CGFloat, top: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .updating($drag) { value, state, _ in state = value.translation.height }
            .onEnded { value in
                let current = router.detent.height(screen: screen, topInset: top)
                let projected = current - value.predictedEndTranslation.height
                let next = SheetDetent.allCases.min {
                    abs($0.height(screen: screen, topInset: top) - projected)
                        < abs($1.height(screen: screen, topInset: top) - projected)
                } ?? router.detent
                withAnimation(SheetDetent.spring) { router.detent = next }
            }
    }

    private var screenHeight: CGFloat {
        #if canImport(UIKit)
        UIScreen.main.bounds.height
        #else
        874
        #endif
    }
}

/// The sheet's content: My Trips, or the focused trip's detail. Modals hang
/// off the sheet so they present above it.
@MainActor
private struct SheetRoot: View {
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            if let id = router.focusedTripId {
                TripDetailView(id: id)
                    .id(id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity))
            } else {
                TripsSheet()
                    .transition(.opacity)
            }
        }
        .sheet(item: $router.modal) { modal in
            Group {
                switch modal {
                case .add(let prefill, let pnrMode):
                    AddTripView(prefill: prefill, pnrMode: pnrMode)
                case .pnr(let pnr):
                    NavigationStack { PNRResultView(pnr: pnr) }
                case .train(let token):
                    TrainLookupView(token: token)
                case .profile:
                    ProfileView()
                case .settings:
                    SettingsView()
                case .intro:
                    EstimatesIntroView()
                }
            }
            .environmentObject(store)
            .environmentObject(bank)
            .environmentObject(router)
            .preferredColorScheme(.light)
        }
        .task {
            // let the sheet finish presenting before stacking a modal on it
            try? await Task.sleep(for: .milliseconds(600))
            router.runPendingLaunch()
        }
    }
}

/// Resolves a train number (fetching the schedule if it isn't cached) and
/// focuses its current run on the globe. Shown briefly while the fetch runs.
@MainActor
struct TrainLookupView: View {
    let token: String
    @EnvironmentObject private var bank: TrainBank
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss
    @State private var failure: String?
    @State private var attempt = 0

    var body: some View {
        VStack(spacing: 14) {
            if let failure {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30)).foregroundStyle(DS.late)
                Text("Couldn't load train \(token)").font(.dsHeadline).foregroundStyle(DS.ink)
                Text(failure).font(.dsFootnote).foregroundStyle(DS.secondary).multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    DSButton(title: "Close", style: .secondary) { dismiss() }
                    DSButton(title: "Try Again", systemImage: "arrow.clockwise") {
                        self.failure = nil
                        attempt += 1
                    }
                }
                .padding(.top, 8)
            } else {
                ProgressView().controlSize(.large)
                Text("Finding train \(token)…").font(.dsHeadline).foregroundStyle(DS.ink)
                Text("Fetching the live schedule").font(.dsFootnote).foregroundStyle(DS.secondary)
            }
        }
        .padding(DS.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationDetents([.height(280)])
        .task(id: attempt) {
            do {
                let train = try await bank.resolve(token)
                router.focus(liveTripFor(train, Date()).id)
            } catch {
                failure = railErrorText(error)
            }
        }
    }
}
