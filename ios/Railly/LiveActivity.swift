import ActivityKit
import Foundation
import OSLog
import SwiftUI

private let laLog = Logger(subsystem: "com.yash121l.railly", category: "LiveActivity")

/// Starts, updates, and ends the train Live Activity — Railly's answer to
/// Flighty's lock-screen / Dynamic Island tracking. The activity mirrors the
/// same live picture the app computes (Sim / real feed); it's local-only (no
/// push server), so everything works offline and in the simulator.
@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    /// train number of the run currently broadcasting, so the UI can show a
    /// live On/Off state
    @Published private(set) var activeNumber: String?

    private var activity: Activity<TrainActivityAttributes>?
    /// the run currently broadcasting, recomputed by the refresh loop
    private var activeTripId: String?
    /// drives the live picture on a 30s tick, so the activity keeps updating
    /// after the user leaves the detail screen
    private var refreshTask: Task<Void, Never>?
    /// fires once at chart-preparation time to flip a waitlisted ticket to CNF
    private var chartTask: Task<Void, Never>?

    private init() {
        // reattach to an activity that outlived a previous app launch
        if let existing = Activity<TrainActivityAttributes>.activities.first {
            activity = existing
            activeNumber = existing.attributes.trainNumber
        }
    }

    var isAvailable: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func isLive(_ number: String) -> Bool { activeNumber == number }

    // MARK: mapping

    private func attributes(_ trip: HeldTrip) -> TrainActivityAttributes {
        let t = trip.train
        return TrainActivityAttributes(
            trainNumber: t.number,
            trainName: t.displayName,
            originCode: t.origin.code,
            originCity: cityFor(t.origin.code, t.origin.name),
            destinationCode: t.destination.code,
            destinationCity: cityFor(t.destination.code, t.destination.name),
            monogram: t.category.monogram,
            liveryHex: t.category.liveryHex
        )
    }

    private func state(_ trip: HeldTrip) -> TrainActivityAttributes.ContentState {
        let live = trip.live
        let now = Date()
        var phase: TrainActivityAttributes.ContentState.Phase
        switch live.phase {
        case .scheduled, .boarding: phase = .preDeparture
        case .enroute: phase = .enRoute
        case .arrived: phase = .arrived
        }
        // destination delay is the number that matters
        let destDelay = live.stopTimings.last?.delayMin ?? live.delayMin
        let next = live.train.stops[live.nextStopIdx]
        let why: String
        switch phase {
        case .preDeparture:
            if let link = rakeLink(for: trip.train, runDate: live.runDate, now: now),
               link.delayMin > 5 {
                why = link.propagatedDelayMin > 5
                    ? "Inbound rake \(link.inbound.number) \(link.delayMin)m late — \(link.propagatedDelayMin)m late start likely"
                    : "Inbound rake \(link.inbound.number) \(link.delayMin)m late; turnaround holds the start"
            } else {
                why = "Inbound rake on schedule"
            }
        case .enRoute:
            why = destDelay > 5
                ? "Running \(destDelay)m behind — reaches \(trip.train.destination.code) late"
                : "Running to time"
        case .charting, .arrived:
            why = "Journey complete"
        }

        // A waitlisted/RAC ticket owns the pre-departure window: it counts down
        // to chart preparation, then flips to the resolved berth.
        var chartISO = 0.0
        var chartPrepared = false
        var waitlistStatus = ""
        var berthAllotment = ""
        if live.phase == .scheduled || live.phase == .boarding,
           let booking = trip.booking,
           let chart = chartingStatus(trip.train, runDate: live.runDate,
                                      booking: booking, now: now) {
            phase = .charting
            chartISO = chart.chartsAt.timeIntervalSince1970
            chartPrepared = chart.prepared
            waitlistStatus = chart.waitlistStatus
            berthAllotment = chart.allotment
        }

        let depPlatform = trip.train.origin.platform
        return TrainActivityAttributes.ContentState(
            phase: phase,
            delayMinutes: destDelay,
            progress: live.progress,
            nextStopName: next.name,
            nextStopCode: next.code,
            platform: phase == .preDeparture ? depPlatform : nil,
            speedKmh: live.speedKmh,
            statusLine: why,
            departISO: live.stopTimings[0].depEst.timeIntervalSince1970,
            arriveISO: live.arrivesEst.timeIntervalSince1970,
            chartISO: chartISO,
            chartPrepared: chartPrepared,
            waitlistStatus: waitlistStatus,
            berthAllotment: berthAllotment
        )
    }

    // MARK: control

    /// Begin (or replace) the live broadcast for a trip.
    func start(_ trip: HeldTrip) {
        laLog.info("start requested for \(trip.train.number, privacy: .public), enabled=\(self.isAvailable, privacy: .public)")
        guard isAvailable else {
            laLog.error("Live Activities not enabled on this device")
            return
        }
        // End any prior run BY VALUE — reading self.activity inside the async
        // end() would race and dismiss the new activity we're about to create.
        let previous = activity
        activity = nil
        if let previous {
            Task { await previous.end(nil, dismissalPolicy: .immediate) }
        }
        do {
            let act = try Activity.request(
                attributes: attributes(trip),
                content: .init(state: state(trip),
                               staleDate: Date().addingTimeInterval(20 * 60)),
                pushType: nil
            )
            activity = act
            activeNumber = trip.train.number
            activeTripId = trip.id
            startRefreshLoop()
            scheduleChartTransition(trip)
            Analytics.shared.log(.laStarted, ["train": trip.train.number])
            laLog.info("Live Activity started, id=\(act.id, privacy: .public)")
        } catch {
            // authorization / budget / size — degrade silently, app still works
            laLog.error("Live Activity start failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Push the latest live picture to the running activity.
    func refresh(_ trip: HeldTrip) async {
        guard let activity, trip.train.number == activeNumber else { return }
        let st = state(trip)
        await activity.update(
            ActivityContent(state: st,
                            staleDate: Date().addingTimeInterval(20 * 60))
        )
        if st.phase == .arrived {
            Analytics.shared.log(.journeyCompleted, ["train": trip.train.number])
            await end(final: st)
        }
    }

    /// Recompute the active run and push it to the running activity.
    private func pushCurrent() async {
        guard let id = activeTripId, let trip = getTrip(id, Date()) else { return }
        await refresh(trip)
    }

    /// Recompute the current run and push it, every 30s. Lives here (not in the
    /// detail view) so the broadcast keeps ticking once the user navigates away.
    private func startRefreshLoop() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                if Task.isCancelled { return }
                await self?.pushCurrent()
            }
        }
    }

    /// A waitlisted ticket's fate is sealed at chart preparation; fire an update
    /// the instant that happens so the activity flips to the CNF berth without
    /// waiting for the next 30s tick.
    private func scheduleChartTransition(_ trip: HeldTrip) {
        chartTask?.cancel()
        chartTask = nil
        guard let booking = trip.booking,
              let chart = chartingStatus(trip.train, runDate: trip.live.runDate,
                                        booking: booking, now: Date()),
              !chart.prepared else { return }
        let delay = chart.chartsAt.timeIntervalSinceNow
        guard delay > 0 else { return }
        chartTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            if Task.isCancelled { return }
            await self?.pushCurrent()
        }
    }

    func stop() { Task { await end() } }

    private func end(final: TrainActivityAttributes.ContentState? = nil) async {
        refreshTask?.cancel()
        refreshTask = nil
        chartTask?.cancel()
        chartTask = nil
        guard let activity else { return }
        let content = final.map { ActivityContent(state: $0, staleDate: nil) }
        await activity.end(content, dismissalPolicy: final == nil ? .immediate : .default)
        self.activity = nil
        activeNumber = nil
        activeTripId = nil
    }
}

extension TrainCategory {
    /// livery color as a packed hex, for the Codable Live Activity payload
    var liveryHex: UInt32 {
        switch self {
        case .rajdhani: return 0xC62828
        case .vandeBharat: return 0x0D47A1
        case .shatabdi: return 0x546E7A
        case .duronto: return 0x2E7D32
        case .tejas: return 0xEF6C00
        case .superfast: return 0x6A1B9A
        case .express: return 0x37474F
        }
    }
}
