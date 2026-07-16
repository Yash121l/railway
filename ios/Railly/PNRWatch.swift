import BackgroundTasks
import Foundation
import OSLog
import UserNotifications

/// The retention engine: Railly re-checks your PNRs on its own — in the
/// background when iOS grants time, and opportunistically every time the app
/// comes forward — and pushes a local notification the moment a status moves
/// (WL climbs, RAC clears, CNF, chart prepared). No server, no account: the
/// same free ConfirmTkt feed the PNR screen already uses drives it, so it
/// works offline-first and in the simulator.
///
/// Watched set = every held trip carrying a real PNR + the recently looked-up
/// PNRs. Each is checked at most once per wake, and finished journeys are
/// skipped. The four Settings → Alerts toggles gate which kinds fire.
private let watchLog = Logger(subsystem: "com.yash121l.railly", category: "PNRWatch")

enum PNRWatch {
    /// Must match the entry in Info.plist's BGTaskSchedulerPermittedIdentifiers.
    static let taskId = "com.yash121l.railly.pnrwatch"

    private static let stateKey = "railly.pnrwatch.state"
    private static let lastRunKey = "railly.pnrwatch.lastRun"
    /// Foreground re-checks are throttled; a background wake always runs.
    private static let foregroundThrottle: TimeInterval = 10 * 60

    // Alert toggles (Settings → Alerts) that gate which notifications fire.
    private static let basicsKey = "railly.alert.basics"
    private static let arrivalKey = "railly.alert.arrival"

    /// Retains the delegate so status pushes surface as banners while the app
    /// is foregrounded (iOS suppresses them otherwise).
    private static let foregroundDelegate = ForegroundDelegate()

    // MARK: Lifecycle

    /// Register the background-refresh handler. Call once, at app launch,
    /// before the first scene is built.
    static func registerBackgroundTask() {
        UNUserNotificationCenter.current().delegate = foregroundDelegate
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskId, using: nil) { task in
            schedule()
            let work = Task { @MainActor in
                await runChecks(force: true)
                task.setTaskCompleted(success: true)
            }
            task.expirationHandler = { work.cancel() }
        }
    }

    /// Ask iOS for the next background window. Silently no-ops on the simulator,
    /// where BGTaskScheduler.submit is unavailable.
    static func schedule() {
        let req = BGAppRefreshTaskRequest(identifier: taskId)
        req.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        do {
            try BGTaskScheduler.shared.submit(req)
        } catch {
            watchLog.debug("BG submit skipped: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Called when a PNR first enters the watch set (looked up or held): claim
    /// notification permission and queue a background window.
    static func beginWatching() {
        requestAuthorizationIfNeeded()
        schedule()
    }

    static func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    // MARK: Re-check

    /// Re-check every watched PNR once, diffing per-passenger status against the
    /// last-seen snapshot and firing a notification on any transition.
    @MainActor
    static func runChecks(force: Bool) async {
        guard !isSnapshotLaunch() else { return }
        let now = Date()
        if !force {
            let last = UserDefaults.standard.double(forKey: lastRunKey)
            if last > 0, now.timeIntervalSince1970 - last < foregroundThrottle { return }
        }
        let watched = watchedPNRs()
        guard !watched.isEmpty else { return }
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastRunKey)

        var state = loadState()
        for w in watched {
            if Task.isCancelled { break }
            // skip journeys that have already finished
            if let number = w.number, let train = TrainBank.shared.cached(number),
               let rd = w.runDate,
               getLiveStatusForRun(train, runDate: rd, now: now).phase == .arrived {
                continue
            }
            if let rd = w.runDate, rd < addDaysISO(istDateISO(now), -1) { continue }

            guard let ticket = try? await ConfirmTktAPI.pnrStatus(w.pnr) else { continue }
            diffAndNotify(pnr: w.pnr, ticket: ticket, state: &state)
        }
        saveState(state)
    }

    @MainActor
    private static func diffAndNotify(pnr: String, ticket: ConfirmTktAPI.RealTicket,
                                      state: inout [String: WatchSnapshot]) {
        let current = WatchSnapshot(current: ticket.passengers.map(\.current),
                                    chart: ticket.chartPrepared,
                                    jClass: ticket.journeyClass)
        defer { state[pnr] = current }
        // first sighting: record the baseline, never announce
        guard let prev = state[pnr] else { return }

        let jClass = JClass(rawValue: ticket.journeyClass) ?? .sleeper
        let trainName = TrainBank.shared.cached(ticket.trainNumber)?.displayName
            ?? "Train \(ticket.trainNumber)"

        if !prev.chart && current.chart, alertEnabled(arrivalKey, default: true) {
            notify(id: "pnrchart.\(pnr)",
                   title: "Chart prepared",
                   body: "\(trainName): the chart is out — your PNR status and coach position are now final.")
        }

        let prevJClass = JClass(rawValue: prev.jClass) ?? jClass
        let before = prev.current.map {
            PNRService.liveStatus($0, coach: nil, berth: nil, jClass: prevJClass)
        }
        let after = ticket.passengers.map {
            PNRService.liveStatus($0.current, coach: $0.coach, berth: $0.berth, jClass: jClass)
        }
        if let msg = ladderMessage(before: before, after: after, trainName: trainName),
           alertEnabled(basicsKey, default: true) {
            notify(id: "pnrstatus.\(pnr)", title: msg.title, body: msg.body)
        }
    }

    /// The banner logic, applied to a diff: announce when the party's *worst*
    /// status improves a category, or when a waitlist position drops.
    private static func ladderMessage(before: [SeatStatus], after: [SeatStatus],
                                      trainName: String) -> (title: String, body: String)? {
        guard let worstBefore = worst(before), let worstAfter = worst(after) else { return nil }
        if rank(worstAfter) > rank(worstBefore) {
            switch worstAfter {
            case .cnf, .noSeat:
                let allConfirmed = after.allSatisfy { rank($0) >= 3 }
                let berth = after.compactMap { status -> String? in
                    if case .cnf(.some(let coach), .some(let b), _) = status { return "\(coach) \(b)" }
                    return nil
                }.first
                let where_ = berth.map { " — \($0)" } ?? ""
                return ("PNR confirmed",
                        allConfirmed
                            ? "\(trainName): all passengers confirmed\(where_)."
                            : "\(trainName): your ticket is confirmed\(where_).")
            case .rac(let n, _, _):
                return ("Moved to RAC",
                        "\(trainName): now RAC\(n > 0 ? " \(n)" : "") — you can board.")
            default:
                return ("Status updated", "\(trainName): your PNR status improved.")
            }
        }
        if case .waitlist(_, let nBefore) = worstBefore,
           case .waitlist(let kind, let nAfter) = worstAfter,
           nAfter >= 0, nAfter < nBefore {
            return ("Waitlist moving",
                    "\(trainName): \(kind.rawValue) \(nBefore) → \(kind.rawValue) \(nAfter).")
        }
        return nil
    }

    // MARK: Watched set

    private struct WatchedPNR {
        let pnr: String
        let number: String?
        let runDate: String?
    }

    @MainActor
    private static func watchedPNRs() -> [WatchedPNR] {
        var out: [WatchedPNR] = []
        var seen = Set<String>()
        for rec in TripStore.shared.records {
            guard let raw = rec.pnr else { continue }
            let digits = raw.filter(\.isNumber)
            guard digits.count == 10, seen.insert(digits).inserted else { continue }
            out.append(WatchedPNR(pnr: digits, number: rec.number, runDate: rec.runDate))
        }
        let csv = UserDefaults.standard.string(forKey: "railly.recentPNRs") ?? ""
        for entry in csv.split(separator: ",") {
            let parts = entry.split(separator: ":").map(String.init)
            guard let first = parts.first else { continue }
            let digits = first.filter(\.isNumber)
            guard digits.count == 10, seen.insert(digits).inserted else { continue }
            out.append(WatchedPNR(pnr: digits,
                                  number: parts.count >= 2 ? parts[1] : nil,
                                  runDate: parts.count >= 3 ? parts[2] : nil))
        }
        return out
    }

    // MARK: Status helpers

    private static func rank(_ s: SeatStatus) -> Int {
        switch s {
        case .notConfirmed: return 0
        case .waitlist: return 1
        case .rac: return 2
        case .cnf, .noSeat: return 3
        }
    }

    /// The party's worst status: lowest category, and within a category the
    /// deepest queue position.
    private static func worst(_ list: [SeatStatus]) -> SeatStatus? {
        list.min { a, b in
            let ra = rank(a), rb = rank(b)
            if ra != rb { return ra < rb }
            if case .waitlist(_, let na) = a, case .waitlist(_, let nb) = b { return na > nb }
            if case .rac(let na, _, _) = a, case .rac(let nb, _, _) = b { return na > nb }
            return false
        }
    }

    // MARK: Notifications

    private static func alertEnabled(_ key: String, default fallback: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? fallback
    }

    private static func notify(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: nil))
    }

    // MARK: Persistent snapshot

    private struct WatchSnapshot: Codable {
        /// raw per-passenger currentStatus, as ConfirmTkt returns it
        let current: [String]
        let chart: Bool
        let jClass: String
    }

    private static func loadState() -> [String: WatchSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let decoded = try? JSONDecoder().decode([String: WatchSnapshot].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func saveState(_ state: [String: WatchSnapshot]) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }

    private final class ForegroundDelegate: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification) async
            -> UNNotificationPresentationOptions {
            [.banner, .sound]
        }
    }
}

/// Tatkal-open reminders — scheduled straight from the Availability screen.
/// The window math (10:00 IST AC / 11:00 non-AC, the day before travel) lives
/// in Reservation; a reminder fires 15 minutes before the gate opens.
enum TatkalReminder {
    static func id(number: String, travelDateISO: String) -> String {
        "tatkal.\(number).\(travelDateISO)"
    }

    /// Schedule the reminder; returns false (nothing queued) when the window
    /// has already passed.
    @discardableResult
    static func schedule(number: String, trainName: String, travelDateISO: String,
                         jClass: JClass, now: Date) -> Bool {
        let opens = Reservation.tatkalOpen(travelDateISO: travelDateISO, jClass: jClass)
        let remindAt = opens.addingTimeInterval(-15 * 60)
        guard remindAt > now else { return false }
        PNRWatch.requestAuthorizationIfNeeded()

        let content = UNMutableNotificationContent()
        content.title = "Tatkal opens soon"
        content.body = "\(trainName): \(jClass.label) Tatkal opens at \(fmtTime(opens)) IST — be ready to book."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, remindAt.timeIntervalSince(now)), repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id(number: number, travelDateISO: travelDateISO),
                                  content: content, trigger: trigger))
        return true
    }

    static func cancel(number: String, travelDateISO: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id(number: number, travelDateISO: travelDateISO)])
    }
}
