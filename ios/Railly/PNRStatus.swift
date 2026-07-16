import Foundation

/// PNR status — the single most-checked piece of information in Indian rail
/// travel. Any 10-digit PNR resolves to a full, stable booking picture:
/// journey, class, quota, per-passenger booking → current status ladder
/// (WL → RAC → CNF as cancellations clear), and chart state. Deterministic
/// per PNR, and the queue positions improve as the journey approaches —
/// exactly the arc a real waitlisted ticket follows.

enum SeatStatus: Equatable {
    case cnf(coach: String?, berth: Int?, type: BerthType?)
    case rac(Int, coach: String?, berth: Int?)
    case waitlist(WLKind, Int)
    /// NOSB — a child travelling without their own berth; the ticket is fine.
    case noSeat
    case notConfirmed

    /// PRS rendering: "CNF B4 32 (LB)", "RAC 12", "GNWL 34".
    var text: String {
        switch self {
        case .cnf(let coach, let berth, let type):
            guard let coach, let berth else { return "CNF" }
            let suffix = type.map { " (\($0.rawValue))" } ?? ""
            return "CNF \(coach) \(berth)\(suffix)"
        case .rac(let pos, let coach, let berth):
            if let coach, let berth { return "RAC \(coach) \(berth)" }
            return pos > 0 ? "RAC \(pos)" : "RAC"
        case .waitlist(let kind, let pos):
            return pos > 0 ? "\(kind.rawValue) \(pos)" : kind.rawValue
        case .noSeat: return "NOSB"
        case .notConfirmed: return "NOT CNF"
        }
    }

    var isConfirmed: Bool {
        switch self {
        // NOSB rides on the family's berths — never drag the banner red
        case .cnf, .noSeat: return true
        default: return false
        }
    }
}

struct PNRPassenger: Identifiable {
    let number: Int
    let booking: SeatStatus
    let current: SeatStatus
    /// live confirmation-chance text for unconfirmed passengers ("67% Chance")
    var prediction: String? = nil

    var id: Int { number }
}

/// Where a PNR answer came from — drives the footer label and how the fare
/// is captioned.
enum PNRSource {
    case simulated
    case confirmTkt
    case easeMyTrip
    case indianRail
}

struct PNRInfo {
    let pnr: String
    let train: Train
    let runDate: String
    let fromIdx: Int
    let toIdx: Int
    let jClass: JClass
    let quota: Quota
    let chartPrepared: Bool
    let passengers: [PNRPassenger]
    /// Which PRS printed this PNR — encoded in the first digit.
    let issuedBy: String
    let fare: Int
    let source: PNRSource
    /// true when `fare` is the charged amount from the live ticket, not a model
    var fareExact: Bool = false
    /// live rake formation from the chart, when the source provides one
    var realRake: [CoachSlot]? = nil
    /// set when the ticket's boarding/deboarding point isn't on the resolved
    /// route — the journey falls back to the full run and callers should not
    /// present the from/to as an authoritative booked segment
    var routeNote: String? = nil

    var from: Stop { train.stops[fromIdx] }
    var to: Stop { train.stops[toIdx] }

    var departure: Date {
        istDateTime(runDate, minutes: parseHM(train.departureTime) + from.depMin)
    }
    var arrival: Date {
        istDateTime(runDate, minutes: parseHM(train.departureTime) + to.arrMin)
    }

    var allConfirmed: Bool { passengers.allSatisfy { $0.current.isConfirmed } }

    var tripId: String { "\(train.number)_\(runDate)" }
}

/// First PNR digit → the PRS centre that issued it.
func prsRegion(_ pnr: String) -> String {
    switch pnr.first {
    case "1": return "PRS Secunderabad"
    case "2", "3": return "PRS New Delhi"
    case "4", "5": return "PRS Chennai"
    case "6", "7": return "PRS Kolkata"
    case "8", "9": return "PRS Mumbai"
    default: return "PRS Special"
    }
}

/// How a lookup ended. Real sources are authoritative: a rejected PNR shows
/// as not-found — it is never papered over with simulated data.
enum PNROutcome {
    case found(PNRInfo)
    /// the live service answered and rejected the PNR
    case notFound(String)
    /// couldn't reach the live services
    case offline
}

/// Marketing/snapshot launches pin every screen to the deterministic engine.
func isSnapshotLaunch() -> Bool {
    let d = UserDefaults.standard
    return d.bool(forKey: "railly.demo")
        || d.string(forKey: "railly.detail") != nil
        || d.string(forKey: "railly.pnr") != nil
        || d.bool(forKey: "railly.onrails")
        || d.integer(forKey: "railly.tab") != 0
}

/// Front door for PNR lookups. Real data first: the free ConfirmTkt feed
/// (richest — live statuses, charged fare, rake formation), then the paid
/// indianrailapi.com endpoint when a key is set. The deterministic simulation
/// only ever answers demo/snapshot launches.
enum PNRService {
    @MainActor
    static func lookup(_ pnr: String, now: Date) async -> PNROutcome {
        let digits = pnr.filter(\.isNumber)
        guard digits.count == 10 else { return .notFound("A PNR is exactly 10 digits") }

        if isSnapshotLaunch() {
            if let sim = PNRSim.lookup(digits, now: now) { return .found(sim) }
            return .notFound("No demo booking for this PNR")
        }

        do {
            let ticket = try await ConfirmTktAPI.pnrStatus(digits)
            if let info = await mapTicket(ticket, pnr: digits) {
                return .found(info)
            }
            // the booking is real but the schedule fetch failed
            return .offline
        } catch ConfirmTktAPI.LookupError.invalid(let reason) {
            return .notFound(reason)
        } catch is CancellationError {
            // view went away mid-fetch; the caller discards this
            return .offline
        } catch {
            // ConfirmTkt unreachable — try the free EaseMyTrip feed next
            if let ease = try? await EaseMyTripAPI.pnrStatus(digits),
               let mapped = await mapEase(ease, pnr: digits, now: now) {
                return .found(mapped)
            }
            // then the paid indianrailapi.com endpoint, when a key is set
            if IndianRailAPI.isConfigured,
               let real = try? await IndianRailAPI.pnrCheck(digits),
               let mapped = await map(real, pnr: digits, now: now) {
                return .found(mapped)
            }
            return .offline
        }
    }

    /// Fold an EaseMyTrip ticket onto the erail schedule — the same shape as
    /// the ConfirmTkt path, one tier down the ladder.
    @MainActor
    private static func mapEase(_ t: EaseMyTripAPI.EaseTicket,
                                pnr: String, now: Date) async -> PNRInfo? {
        guard let train = try? await TrainBank.shared.resolve(t.trainNumber)
        else { return nil }
        let fromCode = t.boardingCode ?? t.fromCode
        let toCode = t.resUptoCode ?? t.toCode
        let fromMatch = fromCode.flatMap { c in train.stops.firstIndex { $0.code == c } }
        let toMatch = toCode.flatMap { c in train.stops.lastIndex { $0.code == c } }
        let routeNote = (fromMatch == nil || toMatch == nil)
            ? "Boarding point isn't on this train's known route — showing the full run."
            : nil
        let fromIdx = fromMatch ?? 0
        let toIdx = toMatch ?? train.stops.count - 1
        let boardDayOffset = (parseHM(train.departureTime)
            + train.stops[fromIdx].depMin) / (24 * 60)
        let runDate = t.doj.map { addDaysISO($0, -boardDayOffset) } ?? istDateISO(now)
        let jClass = JClass(rawValue: t.journeyClass) ?? .sleeper
        let quota = t.quota.flatMap { Quota(rawValue: $0) } ?? .general

        let passengers = t.passengers.enumerated().map { i, p -> PNRPassenger in
            PNRPassenger(
                number: i + 1,
                booking: liveStatus(p.booking, coach: p.bookingCoach,
                                    berth: p.bookingBerth, jClass: jClass),
                current: liveStatus(p.current, coach: p.coach,
                                    berth: p.berth, jClass: jClass))
        }

        return PNRInfo(
            pnr: pnr, train: train, runDate: runDate,
            fromIdx: fromIdx, toIdx: max(fromIdx, min(toIdx, train.stops.count - 1)),
            jClass: jClass, quota: quota,
            chartPrepared: t.chartPrepared,
            passengers: passengers.isEmpty
                ? [PNRPassenger(number: 1, booking: .notConfirmed, current: .notConfirmed)]
                : passengers,
            issuedBy: prsRegion(pnr),
            fare: FareModel.fare(train, jClass, quota: quota) * max(1, passengers.count),
            source: .easeMyTrip,
            routeNote: routeNote
        )
    }

    /// Fold the live ConfirmTkt ticket onto the erail schedule so the result
    /// screen gets a full journey — times, stops, map — around real statuses.
    @MainActor
    private static func mapTicket(_ t: ConfirmTktAPI.RealTicket,
                                  pnr: String) async -> PNRInfo? {
        guard let train = try? await TrainBank.shared.resolve(t.trainNumber)
        else { return nil }
        let fromCode = t.boardingCode ?? t.fromCode
        let toCode = t.resUptoCode ?? t.toCode
        // a missing boarding/deboarding halt used to silently collapse to index
        // 0 / last, rendering a bogus segment — flag it and show the full run
        let fromMatch = fromCode.flatMap { c in train.stops.firstIndex { $0.code == c } }
        let toMatch = toCode.flatMap { c in train.stops.lastIndex { $0.code == c } }
        let routeNote = (fromMatch == nil || toMatch == nil)
            ? "Boarding point isn't on this train's known route — showing the full run."
            : nil
        let fromIdx = fromMatch ?? 0
        let toIdx = toMatch ?? train.stops.count - 1
        // doj is the date at the BOARDING point; runDate must be the origin
        // departure date, so roll back any midnights the train crosses before
        // the boarding halt
        let boardDayOffset = (parseHM(train.departureTime)
            + train.stops[fromIdx].depMin) / (24 * 60)
        let runDate = t.doj.map { addDaysISO($0, -boardDayOffset) }
            ?? istDateISO(Date())
        let jClass = JClass(rawValue: t.journeyClass) ?? .sleeper
        let quota = t.quota.flatMap { Quota(rawValue: $0) } ?? .general

        let passengers = t.passengers.enumerated().map { i, p -> PNRPassenger in
            let current = liveStatus(p.current, coach: p.coach,
                                     berth: p.berth, jClass: jClass)
            return PNRPassenger(
                number: i + 1,
                booking: liveStatus(p.booking, coach: p.bookingCoach,
                                    berth: p.bookingBerth, jClass: jClass),
                current: current,
                prediction: current.isConfirmed ? nil : p.prediction
            )
        }

        return PNRInfo(
            pnr: pnr, train: train, runDate: runDate,
            fromIdx: fromIdx, toIdx: max(fromIdx, min(toIdx, train.stops.count - 1)),
            jClass: jClass, quota: quota,
            chartPrepared: t.chartPrepared,
            passengers: passengers.isEmpty
                ? [PNRPassenger(number: 1, booking: .notConfirmed, current: .notConfirmed)]
                : passengers,
            issuedBy: prsRegion(pnr),
            fare: t.fare ?? FareModel.fare(train, jClass, quota: quota)
                * max(1, passengers.count),
            source: .confirmTkt,
            fareExact: t.fare != nil,
            realRake: t.coachPosition.flatMap(Reservation.parseRake),
            routeNote: routeNote
        )
    }

    /// ConfirmTkt statuses come as "CNF", "RAC 12", "GNWL  72" (spaces, not
    /// slashes) with coach/berth in separate fields.
    static func liveStatus(_ raw: String, coach: String?, berth: Int?,
                           jClass: JClass) -> SeatStatus {
        let tokens = raw.uppercased()
            .split(whereSeparator: { $0 == " " || $0 == "/" || $0 == "#" })
            .map(String.init)
        guard let head = tokens.first else { return .notConfirmed }
        let position = tokens.compactMap { Int($0) }.last
        let cleanCoach = (coach?.isEmpty == false && coach != "-") ? coach : nil
        let cleanBerth = berth.flatMap { $0 > 0 ? $0 : nil }
        switch head {
        case "CNF", "CONFIRMED":
            return .cnf(coach: cleanCoach, berth: cleanBerth,
                        type: cleanBerth.map { berthType(jClass, $0) })
        case "RAC":
            return .rac(position ?? 0, coach: cleanCoach, berth: cleanBerth)
        case "GNWL", "RLWL", "PQWL", "TQWL", "RSWL", "RLGN", "WL", "CKWL":
            let kind: WLKind = head == "RLGN" ? .rlwl
                : head == "CKWL" ? .tqwl
                : WLKind(rawValue: head) ?? .gnwl
            return .waitlist(kind, position ?? 0)
        case "NOSB":
            return .noSeat
        default:
            return .notConfirmed
        }
    }

    /// Fold the wire response onto the local schedule so the result screen
    /// gets a full journey (times, stops, map) — not just status strings.
    @MainActor
    private static func map(_ real: IndianRailAPI.RealPNR, pnr: String,
                            now: Date) async -> PNRInfo? {
        guard let train = try? await TrainBank.shared.resolve(real.trainNumber)
        else { return nil }
        let runDate = real.journeyDate ?? istDateISO(now)
        let fromIdx = train.stops.firstIndex { $0.code == real.fromCode } ?? 0
        let toIdx = train.stops.lastIndex { $0.code == real.toCode }
            ?? train.stops.count - 1
        let jClass = JClass(rawValue: real.journeyClass) ?? .sleeper
        let passengers = real.passengers.enumerated().map { i, p in
            PNRPassenger(number: i + 1,
                         booking: parseStatus(p.booking, jClass: jClass),
                         current: parseStatus(p.current, jClass: jClass))
        }
        return PNRInfo(
            pnr: pnr, train: train, runDate: runDate,
            fromIdx: fromIdx, toIdx: min(toIdx, train.stops.count - 1),
            jClass: jClass,
            quota: .general,
            chartPrepared: real.chartPrepared,
            passengers: passengers.isEmpty
                ? [PNRPassenger(number: 1, booking: .notConfirmed, current: .notConfirmed)]
                : passengers,
            issuedBy: prsRegion(pnr),
            fare: FareModel.fare(train, jClass) * max(1, passengers.count),
            source: .indianRail
        )
    }

    /// PRS status strings pack everything into slashes: "CNF/S6/71/GN" is
    /// status/coach/berth/quota, "RLWL/-/16/GN" is list/-/position/quota.
    static func parseStatus(_ raw: String, jClass: JClass) -> SeatStatus {
        let parts = raw.split(separator: "/").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        guard let head = parts.first?.uppercased() else { return .notConfirmed }
        let numbers = parts.dropFirst().compactMap { Int($0) }
        switch head {
        case "CNF", "CONFIRMED":
            let coach = parts.count > 1 && parts[1] != "-" ? parts[1] : nil
            let berth = numbers.first
            return .cnf(coach: coach, berth: berth,
                        type: berth.map { berthType(jClass, $0) })
        case "RAC":
            let coach = parts.count > 2 && parts[1] != "-" ? parts[1] : nil
            return .rac(numbers.last ?? 0, coach: coach, berth: coach != nil ? numbers.first : nil)
        case "GNWL", "RLWL", "PQWL", "TQWL", "WL", "RSWL", "RLGN", "CKWL":
            let kind: WLKind = head == "RLGN" ? .rlwl
                : head == "CKWL" ? .tqwl
                : WLKind(rawValue: head) ?? .gnwl
            return .waitlist(kind, numbers.last ?? 0)
        case "NOSB":
            return .noSeat
        case "CAN", "CANCELLED":
            return .notConfirmed
        default:
            return .notConfirmed
        }
    }
}

enum PNRSim {
    /// RAC passengers per coach — mirrors Reservation's table.
    private static func racCapacity(_ train: Train, _ jClass: JClass) -> Int {
        let perCoach: [JClass: Int] = [.sleeper: 14, .ac3: 8, .ac3e: 10, .ac2: 6]
        return (perCoach[jClass] ?? 0) * Reservation.coachCount(train, jClass)
    }

    /// Resolve a PNR against the locally known trains. Pure function of
    /// (pnr, pool, today) — checking again always shows the same booking,
    /// with queue positions advanced to now.
    @MainActor
    static func lookup(_ pnr: String, now: Date) -> PNRInfo? {
        let digits = pnr.filter(\.isNumber)
        guard digits.count == 10 else { return nil }

        let pool = TrainBank.shared.trains.values
            .filter { $0.stops.count >= 2 && !JClass.reservable(from: $0.classes).isEmpty }
            .sorted { $0.number < $1.number }
        guard !pool.isEmpty else { return nil }

        let rng = SeededRng("pnr:\(digits)")
        let train = pool[rng.int(0, pool.count - 1)]

        // journey date: mostly the near future, occasionally yesterday —
        // snapped to the train's real run-day calendar
        let today = istDateISO(now)
        let draw = rng.next()
        let wantOffset = draw < 0.15 ? -1 : draw < 0.60 ? rng.int(0, 2) : rng.int(3, 7)
        var runDate = addDaysISO(today, wantOffset)
        for _ in 0..<7 where !train.days.contains(istWeekday(runDate)) {
            runDate = addDaysISO(runDate, 1)
        }

        // 80% of PNRs ride the full route; the rest are segment journeys
        let n = train.stops.count
        var fromIdx = 0
        var toIdx = n - 1
        if rng.next() > 0.80 && n > 3 {
            fromIdx = rng.int(0, n / 3)
            toIdx = rng.int(max(fromIdx + 1, (2 * n) / 3), n - 1)
        }

        let classes = JClass.reservable(from: train.classes)
        // demand-weighted: most bookings live in SL/3A when the rake has them
        let weighted = classes.flatMap { c -> [JClass] in
            switch c {
            case .sleeper, .ac3: return [c, c, c]
            case .ac3e, .chair: return [c, c]
            default: return [c]
            }
        }
        let jClass = weighted[rng.int(0, weighted.count - 1)]

        let quotaDraw = rng.next()
        let quota: Quota = quotaDraw < 0.84 ? .general
            : quotaDraw < 0.95 ? .tatkal : .ladies

        let countDraw = rng.next()
        var partySize = countDraw < 0.42 ? 1 : countDraw < 0.72 ? 2
            : countDraw < 0.87 ? 3 : countDraw < 0.96 ? 4 : rng.int(5, 6)
        // Tatkal PNRs carry at most 4 passengers
        if quota == .tatkal { partySize = min(partySize, 4) }

        let departure = istDateTime(runDate, minutes: parseHM(train.departureTime))
        let chartAt = chartTime(departure: departure)
        let chartPrepared = now >= chartAt

        // Tatkal books the day before; general bookings cluster near the
        // journey (that late surge is why waitlists exist)
        let bdraw = rng.next()
        let bookedDaysBefore = quota == .tatkal ? 1
            : bdraw < 0.40 ? rng.int(1, 7)
            : bdraw < 0.75 ? rng.int(8, 21)
            : rng.int(22, Reservation.arpDays - 5)
        let bookedAt = departure.addingTimeInterval(TimeInterval(-bookedDaysBefore * 86_400))

        // queue depth at booking: how many berths short the party was
        let racCap = quota == .general ? racCapacity(train, jClass) : 0
        let cap = max(1, Int(Double(Reservation.capacity(train, jClass)) * quota.share))
        let demandRoll = 0.6 + rng.next() * 0.9
        let t0 = min(1, max(0, 1 - Double(bookedDaysBefore) / Double(Reservation.arpDays)))
        let bookedAhead = Int(Double(cap) * demandRoll * (0.30 * t0 + 0.70 * t0 * t0 * t0))
        let room = cap - bookedAhead

        // cancellations clear the queue as the chart approaches
        let maxClear = rng.int(max(2, racCap / 2), racCap + max(4, cap / 8))
        let span = max(1.0, chartAt.timeIntervalSince(bookedAt))
        let progress = min(1, max(0, now.timeIntervalSince(bookedAt) / span))
        let cleared = Int(Double(maxClear) * (0.2 * progress + 0.8 * progress * progress))

        let wlKind: WLKind = quota == .tatkal ? .tqwl
            : fromIdx == 0 && toIdx == n - 1 ? .gnwl
            : toIdx == n - 1 ? .rlwl : .pqwl

        let berthRng = SeededRng("berth:\(digits)")
        let coaches = Reservation.rake(train).filter { $0.jClass == jClass }
        let coach = coaches.isEmpty ? nil : coaches[berthRng.int(0, coaches.count - 1)]
        let firstBerth = berthRng.int(1, max(1, jClass.berthsPerCoach - partySize))

        func status(depth: Int, assignBerth: Bool, seat: Int) -> SeatStatus {
            if depth <= 0 {
                guard assignBerth, let coach else {
                    return .cnf(coach: nil, berth: nil, type: nil)
                }
                let berth = firstBerth + seat
                return .cnf(coach: coach.code, berth: berth,
                            type: berthType(jClass, berth))
            }
            if depth <= racCap {
                return .rac(depth, coach: nil, berth: nil)
            }
            return .waitlist(wlKind, depth - racCap)
        }

        let passengers = (1...partySize).map { i -> PNRPassenger in
            let depth0 = i - room
            let depthNow = depth0 - cleared
            // booked-CNF carries its berth from day one; upgrades get theirs
            // at charting
            let booking = status(depth: depth0, assignBerth: depth0 <= 0, seat: i - 1)
            var current = status(depth: depthNow,
                                 assignBerth: depth0 <= 0 || chartPrepared, seat: i - 1)
            // after the chart, whatever is still waitlisted stays unconfirmed
            if chartPrepared, case .waitlist = current {
                current = .notConfirmed
            }
            return PNRPassenger(number: i, booking: booking, current: current)
        }

        return PNRInfo(
            pnr: digits,
            train: train,
            runDate: runDate,
            fromIdx: fromIdx,
            toIdx: toIdx,
            jClass: jClass,
            quota: quota,
            chartPrepared: chartPrepared,
            passengers: passengers,
            issuedBy: prsRegion(digits),
            fare: FareModel.fare(train, jClass, quota: quota) * partySize,
            source: .simulated
        )
    }
}
