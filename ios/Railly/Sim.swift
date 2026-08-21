import Foundation

/// Direct port of src/lib/sim.ts: the live network is a pure function of
/// (train, runDate, now) — seeded delay walks over the timetable, identical
/// on every platform.

/// minutes before scheduled departure that a run becomes the active one
private let boardingMin = 45.0
/// minutes after estimated arrival a run keeps showing as active
private let lingerMin = 25.0
/// how many days back a run can still be in progress (longest journey ~38h)
private let maxLookbackDays = 3

private struct DelayProfile {
    let down: Double
    let up: Double
    let incident: Double
    let max: Double
}

private let delayProfiles: [TrainCategory: DelayProfile] = [
    .vandeBharat: DelayProfile(down: 3, up: 5, incident: 0.15, max: 45),
    .shatabdi: DelayProfile(down: 3, up: 6, incident: 0.18, max: 60),
    .rajdhani: DelayProfile(down: 4, up: 8, incident: 0.24, max: 90),
    .duronto: DelayProfile(down: 4, up: 9, incident: 0.24, max: 90),
    .tejas: DelayProfile(down: 3, up: 7, incident: 0.18, max: 60),
    .superfast: DelayProfile(down: 4, up: 11, incident: 0.36, max: 150),
    .express: DelayProfile(down: 5, up: 14, incident: 0.45, max: 180),
]

private let topSpeedKmh: [TrainCategory: Double] = [
    .vandeBharat: 160, .shatabdi: 140, .rajdhani: 130, .duronto: 130,
    .tejas: 130, .superfast: 110, .express: 100,
]

private let delayReasons = [
    "Held at the outer signal",
    "Speed restriction over a maintenance block",
    "Awaiting a crossing on the single-line section",
    "Regulated for a late-running priority service",
    "Fog speed restriction in effect",
    "Extended halt for crew change",
    "Signal failure ahead cleared after inspection",
]

/// Arrival delay (minutes) at every stop for a given run. Real running data
/// from the live feed wins when present (see LiveFeed); otherwise a
/// deterministic seeded walk stands in so the app works offline.
private func delaysForRun(_ train: Train, _ runDate: String) -> [Int] {
    if let real = LiveFeed.shared.alignedDelays(
        number: train.number, runDate: runDate, stops: train.stops) {
        return real
    }
    let rng = SeededRng("\(train.number):\(runDate)")
    let profile = delayProfiles[train.category]!
    let n = train.stops.count

    // At most one "incident" (big jolt) per run, on a seeded segment.
    let incidentSeg = rng.next() < profile.incident ? rng.int(1, n - 1) : -1

    var delays = [rng.next() < 0.18 ? rng.int(2, 12) : 0]
    for i in 1..<n {
        let segMin = Double(train.stops[i].arrMin - train.stops[i - 1].depMin)
        var d = Double(delays[i - 1]) + (rng.next() * (profile.up + profile.down) - profile.down)
        if i == incidentSeg { d += Double(rng.int(12, 35)) }
        // Can't arrive earlier than physics allows relative to the previous departure.
        d = clamp(d, max(0, Double(delays[i - 1]) - max(0, segMin - 3)), profile.max)
        delays.append(Int(d.rounded()))
    }
    return delays
}

struct Run {
    let runDate: String
    let delays: [Int]
    let timings: [StopTiming]
    let departs: Date
    let departsEst: Date
    let arrivesSched: Date
    let arrivesEst: Date
}

/// Memoized runs, keyed by "number:runDate" plus the live-snapshot stamp that
/// fed the delay walk. A `Run` is a pure function of (train, runDate, snapshot)
/// and carries no `now`, so caching it is exact: the per-second UIs stop
/// rebuilding every delay walk each tick, and a new live snapshot (its `at`
/// changes) invalidates the entry on its own.
private final class RunCache: @unchecked Sendable {
    private let lock = NSLock()
    private var store: [String: (run: Run, stamp: Date?)] = [:]

    func get(_ key: String, stamp: Date?) -> Run? {
        lock.lock(); defer { lock.unlock() }
        guard let c = store[key], c.stamp == stamp else { return nil }
        return c.run
    }

    func set(_ key: String, run: Run, stamp: Date?) {
        lock.lock(); defer { lock.unlock() }
        if store.count > 512 { store.removeAll(keepingCapacity: true) }
        store[key] = (run, stamp)
    }

    func invalidate(prefix: String) {
        lock.lock(); defer { lock.unlock() }
        for k in store.keys where k.hasPrefix(prefix) { store.removeValue(forKey: k) }
    }

    func invalidateAll() {
        lock.lock(); defer { lock.unlock() }
        store.removeAll()
    }
}

private let runCache = RunCache()

/// Drop memoized runs for a train after its schedule is refetched, so a new
/// route or timing takes effect immediately.
func invalidateRunCache(_ number: String) { runCache.invalidate(prefix: "\(number):") }

/// Drop every memoized run — used when the whole train cache is cleared.
func invalidateAllRunCache() { runCache.invalidateAll() }

func buildRun(_ train: Train, _ runDate: String) -> Run {
    let key = "\(train.number):\(runDate)"
    let stamp = LiveFeed.shared.snapshotStamp(train.number, runDate)
    if let cached = runCache.get(key, stamp: stamp) { return cached }
    let run = computeRun(train, runDate)
    runCache.set(key, run: run, stamp: stamp)
    return run
}

private func computeRun(_ train: Train, _ runDate: String) -> Run {
    let depTimeMin = parseHM(train.departureTime)
    let delays = delaysForRun(train, runDate)
    let timings: [StopTiming] = train.stops.enumerated().map { i, s in
        let arrSched = istDateTime(runDate, minutes: depTimeMin + s.arrMin)
        let depSched = istDateTime(runDate, minutes: depTimeMin + s.depMin)
        let shift = TimeInterval(delays[i] * 60)
        return StopTiming(
            arrSched: arrSched,
            arrEst: arrSched.addingTimeInterval(shift),
            depSched: depSched,
            depEst: depSched.addingTimeInterval(shift),
            delayMin: delays[i],
            passed: false,
            current: false
        )
    }
    let last = timings[timings.count - 1]
    return Run(
        runDate: runDate,
        delays: delays,
        timings: timings,
        departs: timings[0].depSched,
        departsEst: timings[0].depEst,
        arrivesSched: last.arrSched,
        arrivesEst: last.arrEst
    )
}

/// All runs currently inside their live window, newest first.
private func runsInWindow(_ train: Train, _ now: Date) -> [Run] {
    let today = istDateISO(now)
    var out: [Run] = []
    for offset in stride(from: 0, through: -maxLookbackDays, by: -1) {
        let runDate = addDaysISO(today, offset)
        guard train.days.contains(istWeekday(runDate)) else { continue }
        let run = buildRun(train, runDate)
        let from = run.departs.addingTimeInterval(-boardingMin * 60)
        let to = run.arrivesEst.addingTimeInterval(lingerMin * 60)
        if now >= from && now <= to { out.append(run) }
    }
    return out
}

/// The run a viewer cares about right now: an underway run beats one merely
/// boarding, else the next scheduled one, else the last completed.
private func resolveRun(_ train: Train, _ now: Date) -> Run {
    let inWindow = runsInWindow(train, now)
    if !inWindow.isEmpty {
        if let enroute = inWindow.first(where: { now >= $0.departsEst && now < $0.arrivesEst }) {
            return enroute
        }
        return inWindow[0]
    }

    let today = istDateISO(now)
    for offset in 0...7 {
        let runDate = addDaysISO(today, offset)
        guard train.days.contains(istWeekday(runDate)) else { continue }
        let run = buildRun(train, runDate)
        if run.departs > now { return run }
    }
    for offset in stride(from: -1, through: -14, by: -1) {
        let runDate = addDaysISO(today, offset)
        if train.days.contains(istWeekday(runDate)) { return buildRun(train, runDate) }
    }
    return buildRun(train, today)
}

/// Live pictures of every run currently in its window.
func getActiveStatuses(_ train: Train, _ now: Date) -> [LiveStatus] {
    runsInWindow(train, now).map { statusForRun(train, $0, now) }
}

/// The next run that hasn't entered its boarding window yet.
func getScheduledStatus(_ train: Train, _ now: Date) -> LiveStatus? {
    let today = istDateISO(now)
    for offset in 0...7 {
        let runDate = addDaysISO(today, offset)
        guard train.days.contains(istWeekday(runDate)) else { continue }
        let run = buildRun(train, runDate)
        if run.departs.addingTimeInterval(-boardingMin * 60) > now {
            return statusForRun(train, run, now)
        }
    }
    return nil
}

private func eventsForRun(_ train: Train, _ run: Run, _ now: Date) -> [TrainEvent] {
    let rng = SeededRng("\(train.number):\(run.runDate):events")
    let stops = train.stops

    // Every RNG draw happens unconditionally, in a fixed order, so past
    // events never mutate as the clock advances.
    let pfStop = rng.next() < 0.3 ? rng.int(1, stops.count - 1) : -1
    let pfOldFallback = rng.int(1, 6)
    let pfNewRaw = rng.int(1, 8)
    let reasons = stops.map { _ in rng.pick(delayReasons) }

    var events: [TrainEvent] = []

    events.append(TrainEvent(
        time: run.departsEst,
        kind: .departed,
        text: "Departed \(stops[0].name)",
        detail: run.delays[0] > 0 ? "\(run.delays[0])m late" : "On time"
    ))

    if pfStop > 0 {
        let announceAt = run.timings[pfStop].arrEst.addingTimeInterval(-40 * 60)
        if announceAt >= run.departs {
            let oldPf = stops[pfStop].platform ?? String(pfOldFallback)
            var newPf = String(pfNewRaw)
            if newPf == oldPf { newPf = String((Int(oldPf) ?? 1) + 1) }
            events.append(TrainEvent(
                time: announceAt,
                kind: .platform,
                text: "Platform change at \(stops[pfStop].name)",
                detail: "PF \(oldPf) → PF \(newPf)"
            ))
        }
    }

    for i in 1..<stops.count {
        let t = run.timings[i]
        let jump = run.delays[i] - run.delays[i - 1]

        if jump >= 8 {
            let mid = Date(timeIntervalSince1970:
                (run.timings[i - 1].depEst.timeIntervalSince1970 + t.arrEst.timeIntervalSince1970) / 2)
            events.append(TrainEvent(
                time: mid,
                kind: .delay,
                text: reasons[i],
                detail: "+\(jump)m near \(stops[i].name)"
            ))
        } else if jump <= -8 {
            events.append(TrainEvent(
                time: t.arrEst,
                kind: .recovery,
                text: "Made up time approaching \(stops[i].name)",
                detail: "\(jump)m"
            ))
        }

        if i < stops.count - 1 {
            events.append(TrainEvent(
                time: t.depEst,
                kind: .stop,
                text: "Departed \(stops[i].name)",
                detail: run.delays[i] > 5 ? "+\(run.delays[i])m" : "On time"
            ))
        }
    }

    let last = run.timings[run.timings.count - 1]
    let lastDelay = run.delays[run.delays.count - 1]
    events.append(TrainEvent(
        time: last.arrEst,
        kind: .arrived,
        text: "Arrived \(stops[stops.count - 1].name)",
        detail: lastDelay > 5 ? "\(lastDelay)m late" : "On time"
    ))

    // Journey-companion grammar for the long overnighters (30h+): scheduled
    // long halts and a morning position summary, then quiet hours that mute the
    // routine chatter while the coach sleeps.
    if train.destination.arrMin >= 30 * 60 {
        appendLongHaulEvents(train, run, &events)
        events = events.filter { keepThroughQuietHours($0) }
    }

    return events
        .filter { $0.time <= now }
        .sorted { $0.time > $1.time }
        .prefix(14)
        .map { $0 }
}

/// Rail-native milestones the timetable already implies on a 30h+ run: the
/// scheduled long halts (crew change, loco reversal, watering) and a "where are
/// we?" summary at 06:30 each morning, when quiet hours lift.
private func appendLongHaulEvents(_ train: Train, _ run: Run,
                                  _ events: inout [TrainEvent]) {
    let stops = train.stops
    guard stops.count > 2 else { return }

    for i in 1..<(stops.count - 1) {
        let halt = stops[i].depMin - stops[i].arrMin
        guard halt >= 10 else { continue }
        events.append(TrainEvent(
            time: run.timings[i].arrEst,
            kind: .halt,
            text: "\(halt)m halt at \(stops[i].name)",
            detail: run.delays[i] > 5 ? "Running +\(run.delays[i])m" : "On time"
        ))
    }

    for offset in 0...3 {
        let morning = istDateTime(addDaysISO(run.runDate, offset), minutes: 6 * 60 + 30)
        guard morning > run.departsEst.addingTimeInterval(3600),
              morning < run.arrivesEst.addingTimeInterval(-1800) else { continue }
        // the last stop the train had cleared by this morning
        var idx = 0
        for i in 0..<stops.count where run.timings[i].depEst <= morning { idx = i }
        let d = run.delays[idx]
        events.append(TrainEvent(
            time: morning,
            kind: .summary,
            text: d > 5 ? "Running +\(d)m as of \(stops[idx].name)"
                        : "On time as of \(stops[idx].name)",
            detail: "Morning position · reaches \(stops[stops.count - 1].name) \(fmtTime(run.arrivesEst))"
        ))
    }
}

/// Overnight quiet hours (22:30–06:00 IST): the routine stop/recovery/halt
/// chatter is suppressed so an overnighter doesn't buzz all night; delays,
/// platform changes, the morning summary, and arrival always survive.
private func keepThroughQuietHours(_ event: TrainEvent) -> Bool {
    switch event.kind {
    case .stop, .recovery, .halt:
        return !isISTQuietHour(event.time)
    default:
        return true
    }
}

private func isISTQuietHour(_ date: Date) -> Bool {
    let secs = Int((date.timeIntervalSince1970 + Double(istOffsetMin * 60)).rounded(.down))
    let minute = (((secs % 86400) + 86400) % 86400) / 60
    return minute >= 22 * 60 + 30 || minute < 6 * 60
}

func getLiveStatus(_ train: Train, _ now: Date) -> LiveStatus {
    statusForRun(train, resolveRun(train, now), now)
}

func getLiveStatusForRun(_ train: Train, runDate: String, now: Date) -> LiveStatus {
    statusForRun(train, buildRun(train, runDate), now)
}

func statusForRun(_ train: Train, _ run: Run, _ now: Date) -> LiveStatus {
    let stops = train.stops
    let n = stops.count
    // The drawn line and the tracked position are the same geometry — see
    // RailRoute. `stopKm` is real track distance (the feed's own, or measured
    // along the spliced polyline), not the straight chords this used to use.
    let route = RailRouteCache.route(for: train)
    let cum = route.stopKm
    let totalKm = route.totalKm

    let phase: RunPhase
    if now < run.departs.addingTimeInterval(-boardingMin * 60) {
        phase = .scheduled
    } else if now < run.departsEst {
        phase = .boarding
    } else if now < run.arrivesEst {
        phase = .enroute
    } else {
        phase = .arrived
    }

    var prevStopIdx = 0
    var nextStopIdx = min(1, n - 1)
    var atStation = true
    var frac = 0.0
    var delayMin = run.delays[0]
    var speedKmh = 0

    if phase == .arrived {
        prevStopIdx = n - 1
        nextStopIdx = n - 1
        delayMin = run.delays[n - 1]
    } else if phase == .enroute {
        for i in 0..<(n - 1) where now < run.timings[i + 1].arrEst {
            if now < run.timings[i].depEst {
                prevStopIdx = i
                nextStopIdx = i + 1
                atStation = true
                delayMin = run.delays[i]
            } else {
                prevStopIdx = i
                nextStopIdx = i + 1
                atStation = false
                let depMs = run.timings[i].depEst.timeIntervalSince1970
                let arrMs = run.timings[i + 1].arrEst.timeIntervalSince1970
                frac = clamp((now.timeIntervalSince1970 - depMs) / max(1, arrMs - depMs), 0, 1)
                delayMin = Int(lerp(Double(run.delays[i]), Double(run.delays[i + 1]), frac).rounded())

                let segKm = cum[i + 1] - cum[i]
                let segH = (arrMs - depMs) / 3600
                let base = segKm / max(0.05, segH)
                let wobblePhase = Double(hashSeed(train.number) % 360)
                let wobble = 1 + 0.12 * sin(now.timeIntervalSince1970 * 1000 / 120_000 + wobblePhase)
                speedKmh = Int(clamp(base * wobble, 28, topSpeedKmh[train.category]!).rounded())
            }
            break
        }
    }

    // Standing at a halt pins the marker to the halt itself; running places it
    // on the drawn track, heading where that track actually points.
    let onTrack = route.point(leg: prevStopIdx,
                              frac: atStation || prevStopIdx == nextStopIdx ? 0 : frac)
    let posLat = onTrack.coordinate.latitude
    let posLng = onTrack.coordinate.longitude
    let bearing = prevStopIdx == nextStopIdx ? 0 : onTrack.bearing

    let progressKm: Double
    switch phase {
    case .arrived: progressKm = totalKm
    case .enroute: progressKm = cum[prevStopIdx] + frac * (cum[nextStopIdx] - cum[prevStopIdx])
    default: progressKm = 0
    }

    var timings = run.timings.map { t -> StopTiming in
        var t2 = t
        t2.passed = phase == .arrived || (phase == .enroute && t.depEst <= now)
        t2.current = false
        return t2
    }
    if phase == .enroute && atStation { timings[prevStopIdx].current = true }
    if phase == .boarding { timings[0].current = true }

    return LiveStatus(
        train: train,
        runDate: run.runDate,
        phase: phase,
        delayMin: delayMin,
        positionLat: posLat,
        positionLng: posLng,
        bearing: bearing,
        speedKmh: speedKmh,
        prevStopIdx: prevStopIdx,
        nextStopIdx: nextStopIdx,
        legFraction: atStation || prevStopIdx == nextStopIdx ? 0 : frac,
        atStation: atStation,
        stopTimings: timings,
        progressKm: progressKm,
        totalKm: totalKm,
        progress: totalKm == 0 ? 0 : clamp(progressKm / totalKm, 0, 1),
        departsAt: run.departs,
        arrivesSched: run.arrivesSched,
        arrivesEst: run.arrivesEst,
        events: phase == .scheduled ? [] : eventsForRun(train, run, now)
    )
}

// MARK: - Charting

/// The chart-preparation picture for a booked run. A ticket that goes in
/// waitlisted or RAC has its fate sealed when the reservation chart prepares
/// (`chartTime`, see Reservation); this resolves that outcome deterministically,
/// like every other number in the sim.
struct ChartingStatus {
    /// when the reservation chart prepares for this run
    let chartsAt: Date
    /// chart has prepared — the WL/RAC fate is now sealed
    let prepared: Bool
    /// pre-chart position ("WL 12", "RAC 5")
    let waitlistStatus: String
    /// resolved allotment once charted ("B2 · 34 LB")
    let allotment: String
}

/// The charting picture for a held booking, or nil when the ticket was never
/// on a waitlist — a plain CNF ticket has no charting drama to broadcast.
func chartingStatus(_ train: Train, runDate: String, booking: Booking,
                    now: Date) -> ChartingStatus? {
    let rng = SeededRng("charting:\(booking.pnr)")
    // ~55% of held bookings went in on a waitlist or RAC; the rest were CNF
    // from the start and skip the charting phase entirely.
    guard rng.next() < 0.55 else { return nil }

    let chartsAt = chartTime(departure: buildRun(train, runDate).departs)
    let waitlistStatus = rng.next() < 0.4
        ? "RAC \(rng.int(1, 18))"
        : "WL \(rng.int(2, 26))"
    return ChartingStatus(
        chartsAt: chartsAt,
        prepared: now >= chartsAt,
        waitlistStatus: waitlistStatus,
        allotment: "\(booking.coach) · \(booking.seat)"
    )
}

// MARK: - Rake linkage

/// The paired return service whose rake turns around to become this train,
/// and how its inbound running bleeds into our departure. Indian trains run
/// as numbered pairs (12951 down ↔ 12952 up): the same physical rake turns
/// around at each terminus, so a rake that arrives late has to leave late.
struct RakeLink {
    let inbound: Train
    let runDate: String
    let arrivesSched: Date
    let arrivesEst: Date
    /// the inbound run's arrival delay at our origin, minutes
    let delayMin: Int
    /// how much of that delay survives the scheduled turnaround buffer to push
    /// out our own departure, minutes
    let propagatedDelayMin: Int
}

/// minutes a rake needs on the platform to turn around (clean, water, brake test)
private let rakeTurnaroundMin = 40.0

/// The rake linkage for a run, or nil when the paired service isn't known or
/// doesn't terminate where we begin (so there's no believable turnaround).
@MainActor
func rakeLink(for train: Train, runDate: String, now: Date) -> RakeLink? {
    guard let num = Int(train.number) else { return nil }
    // the pair: an odd number runs down, the next even runs back up
    let pairNum = num % 2 == 0 ? num - 1 : num + 1
    let pairStr = String(format: "%0\(train.number.count)d", pairNum)
    guard pairStr != train.number,
          let inbound = TrainBank.shared.cached(pairStr),
          // the return rake must terminate where we begin
          inbound.destination.code == train.origin.code
    else { return nil }

    let ourDep = istDateTime(runDate, minutes: parseHM(train.departureTime))
    // the inbound run that just came in: the latest arrival still before our
    // start, inside a day's turnaround window
    var chosen: Run?
    for offset in stride(from: 0, through: -maxLookbackDays, by: -1) {
        let d = addDaysISO(runDate, offset)
        guard inbound.days.contains(istWeekday(d)) else { continue }
        let run = buildRun(inbound, d)
        guard run.arrivesSched <= ourDep,
              run.arrivesSched > ourDep.addingTimeInterval(-24 * 3600) else { continue }
        if chosen == nil || run.arrivesSched > chosen!.arrivesSched { chosen = run }
    }
    guard let inRun = chosen else { return nil }

    let readyAt = inRun.arrivesEst.addingTimeInterval(rakeTurnaroundMin * 60)
    let propagated = max(0, readyAt.timeIntervalSince(ourDep) / 60)
    return RakeLink(
        inbound: inbound,
        runDate: inRun.runDate,
        arrivesSched: inRun.arrivesSched,
        arrivesEst: inRun.arrivesEst,
        delayMin: inRun.delays[inRun.delays.count - 1],
        propagatedDelayMin: Int(propagated.rounded())
    )
}

/// Most recent run that has fully arrived — for past-trips lists.
func lastCompletedRunDate(_ train: Train, _ now: Date) -> String? {
    let today = istDateISO(now)
    for offset in stride(from: 0, through: -14, by: -1) {
        let runDate = addDaysISO(today, offset)
        guard train.days.contains(istWeekday(runDate)) else { continue }
        let run = buildRun(train, runDate)
        if run.arrivesEst < now { return runDate }
    }
    return nil
}
