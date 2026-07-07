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

private func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
    min(hi, max(lo, v))
}

/// Arrival delay (minutes) at every stop for a given run — deterministic.
private func delaysForRun(_ train: Train, _ runDate: String) -> [Int] {
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

func buildRun(_ train: Train, _ runDate: String) -> Run {
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

    return events
        .filter { $0.time <= now }
        .sorted { $0.time > $1.time }
        .prefix(14)
        .map { $0 }
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
    let cum = cumulativeKm(stops)
    let totalKm = cum[n - 1]

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

    let a = stops[prevStopIdx]
    let b = stops[nextStopIdx]
    let posLat = atStation || prevStopIdx == nextStopIdx ? a.lat : lerp(a.lat, b.lat, frac)
    let posLng = atStation || prevStopIdx == nextStopIdx ? a.lng : lerp(a.lng, b.lng, frac)
    let bearing = prevStopIdx == nextStopIdx ? 0 : bearingDeg(a.lat, a.lng, b.lat, b.lng)

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
