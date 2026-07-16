import Foundation

/// The Indian Railways reservation layer: journey classes, quotas, seat
/// availability, waitlists, chart preparation, rake composition, and PNR
/// status — modeled to real IR rules (ARP, Tatkal windows, WL→RAC→CNF
/// laddering, berth numbering) so every string the app shows reads exactly
/// like the PRS would print it.
///
/// Like Sim.swift, everything is a pure seeded function of its inputs, so a
/// PNR or an availability grid looks identical on every check. When the user
/// has an indianrailapi.com key the real PNR/availability endpoints win
/// (see IndianRailAPI); this engine is the always-working offline stand-in.

// MARK: - Journey classes

enum JClass: String, CaseIterable, Codable {
    case ac1 = "1A", ac2 = "2A", ac3 = "3A", ac3e = "3E", sleeper = "SL"
    case chair = "CC", execChair = "EC", execAnubhuti = "EA", vistadome = "EV"
    case second = "2S", general = "GN"

    var label: String {
        switch self {
        case .ac1: return "AC First"
        case .ac2: return "AC 2 Tier"
        case .ac3: return "AC 3 Tier"
        case .ac3e: return "AC 3 Economy"
        case .sleeper: return "Sleeper"
        case .chair: return "AC Chair Car"
        case .execChair: return "Executive Chair"
        case .execAnubhuti: return "Anubhuti"
        case .vistadome: return "Vistadome"
        case .second: return "Second Sitting"
        case .general: return "Unreserved"
        }
    }

    /// Overnight berth classes get berth-type suffixes; day coaches get seats.
    var isBerthed: Bool {
        switch self {
        case .ac1, .ac2, .ac3, .ac3e, .sleeper: return true
        default: return false
        }
    }

    /// Berths/seats in one coach (LHB rakes, the current fleet standard).
    var berthsPerCoach: Int {
        switch self {
        case .ac1: return 24
        case .ac2: return 54
        case .ac3: return 72
        case .ac3e: return 80
        case .sleeper: return 80
        case .chair: return 78
        case .execChair: return 56
        case .execAnubhuti: return 56
        case .vistadome: return 44
        case .second: return 108
        case .general: return 100
        }
    }

    /// Booking UIs list classes top-down by fare.
    var order: Int {
        switch self {
        case .ac1: return 0
        case .execAnubhuti: return 1
        case .execChair: return 2
        case .vistadome: return 3
        case .ac2: return 4
        case .ac3: return 5
        case .ac3e: return 6
        case .chair: return 7
        case .sleeper: return 8
        case .second: return 9
        case .general: return 10
        }
    }

    /// Classes a reservation can actually be made in (GN is walk-on).
    static func reservable(from codes: [String]) -> [JClass] {
        codes.compactMap { JClass(rawValue: $0) }
            .filter { $0 != .general }
            .sorted { $0.order < $1.order }
    }

    /// What a traveller most likely books on this rake — 3A, then Sleeper,
    /// then Chair Car — used as the pre-selected class in pickers.
    static func defaultPick(_ list: [JClass]) -> JClass? {
        list.first { $0 == .ac3 } ?? list.first { $0 == .sleeper }
            ?? list.first { $0 == .chair } ?? list.first
    }
}

// MARK: - Quotas

enum Quota: String, CaseIterable, Codable {
    case general = "GN", tatkal = "TQ", ladies = "LD", lowerBerth = "SS"
    case divyangjan = "HP"

    var label: String {
        switch self {
        case .general: return "General"
        case .tatkal: return "Tatkal"
        case .ladies: return "Ladies"
        case .lowerBerth: return "Lower Berth"
        case .divyangjan: return "Divyangjan"
        }
    }

    var note: String? {
        switch self {
        case .general: return nil
        case .tatkal: return "Opens 10AM (AC) / 11AM (non-AC), one day before"
        case .ladies: return "Women travelling alone or with children"
        case .lowerBerth: return "Senior citizens & women 45+"
        case .divyangjan: return "Passengers with disability concession"
        }
    }

    /// Share of a class's berths earmarked for this quota.
    var share: Double {
        switch self {
        case .general: return 0.80
        case .tatkal: return 0.13
        case .ladies: return 0.03
        case .lowerBerth: return 0.03
        case .divyangjan: return 0.01
        }
    }
}

// MARK: - Waitlists & status

enum WLKind: String {
    /// Origin-to-destination bookings — clears best.
    case gnwl = "GNWL"
    /// From an intermediate ("remote") station — clears against local
    /// cancellations only.
    case rlwl = "RLWL"
    /// Short intermediate hops pooled across the route — weakest list.
    case pqwl = "PQWL"
    /// Tatkal waitlist — almost never moves after charting.
    case tqwl = "TQWL"
    /// Roadside-station waitlist — small allocation, slow.
    case rswl = "RSWL"
    /// Plain "WL n" as some feeds render the current position.
    case wl = "WL"
}

enum AvailStatus: Equatable {
    case available(Int)
    case rac(Int)
    case waitlist(WLKind, booking: Int, current: Int)
    case regret
    /// Tatkal before its booking window opens.
    case opens(Date)
    case charting
    case departed
    /// Train doesn't run on this date.
    case noService

    /// The PRS string, exactly as IRCTC renders it.
    var text: String {
        switch self {
        case .available(let n): return String(format: "AVAILABLE-%04d", n)
        case .rac(let n): return "RAC \(n)"
        case .waitlist(let kind, let booking, let current):
            return "\(kind.rawValue)\(booking)/WL\(current)"
        case .regret: return "REGRET"
        case .opens(let date): return "OPENS \(fmtDay(date).uppercased())"
        case .charting: return "CHART PREPARED"
        case .departed: return "TRAIN DEPARTED"
        case .noService: return "NO SERVICE"
        }
    }

    /// Short chip form ("AVL 42", "WL 23") for tight rows.
    var chip: String {
        switch self {
        case .available(let n): return "AVL \(n)"
        case .rac(let n): return "RAC \(n)"
        case .waitlist(_, _, let current): return "WL \(current)"
        case .regret: return "REGRET"
        case .opens: return "TATKAL"
        case .charting: return "CHART"
        case .departed: return "DEPARTED"
        case .noService: return "—"
        }
    }

    var isBookable: Bool {
        switch self {
        case .available, .rac, .waitlist: return true
        default: return false
        }
    }
}

struct DayAvailability: Identifiable {
    let dateISO: String
    let status: AvailStatus
    var id: String { dateISO }
}

// MARK: - Fares

/// Rough current fare math: base ₹/km per class, reservation + superfast
/// charges, 5% GST on AC classes, and the premium-service bump baked into
/// Rajdhani/Shatabdi/Vande Bharat fare tables. Close enough to read true.
enum FareModel {
    private static let perKm: [JClass: Double] = [
        .ac1: 2.40, .ac2: 1.45, .ac3: 1.00, .ac3e: 0.90, .sleeper: 0.40,
        .chair: 0.90, .execChair: 1.90, .execAnubhuti: 2.20, .vistadome: 2.60,
        .second: 0.30, .general: 0.18,
    ]
    private static let reservationFee: [JClass: Double] = [
        .ac1: 60, .ac2: 50, .ac3: 40, .ac3e: 40, .sleeper: 20,
        .chair: 40, .execChair: 60, .execAnubhuti: 60, .vistadome: 60,
        .second: 15, .general: 0,
    ]

    static func fare(_ train: Train, _ jClass: JClass, quota: Quota = .general) -> Int {
        let km = max(50, train.distanceKm)
        var f = perKm[jClass]! * km + reservationFee[jClass]!
        // superfast charge applies to 130+ km/h services
        switch train.category {
        case .express: break
        default:
            switch jClass {
            case .second: f += 15
            case .sleeper: f += 30
            case .ac1, .execChair, .execAnubhuti: f += 75
            default: f += 45
            }
        }
        // premium-train fare tables run higher than mail/express
        switch train.category {
        case .rajdhani, .duronto: f *= 1.20
        case .vandeBharat: f *= 1.40
        case .shatabdi, .tejas: f *= 1.25
        default: break
        }
        // catering built into premium day trains
        if train.category == .vandeBharat || train.category == .shatabdi {
            f += 155
        }
        // GST on AC classes
        if jClass != .sleeper && jClass != .second && jClass != .general {
            f *= 1.05
        }
        if quota == .tatkal {
            // official Tatkal charge: 10% of base for 2S, 30% otherwise,
            // clamped to the per-class min/max table
            let base = perKm[jClass]! * km
            let (pct, mn, mx): (Double, Double, Double)
            switch jClass {
            case .second: (pct, mn, mx) = (0.10, 10, 15)
            case .sleeper: (pct, mn, mx) = (0.30, 100, 200)
            case .chair: (pct, mn, mx) = (0.30, 125, 225)
            case .ac3, .ac3e: (pct, mn, mx) = (0.30, 300, 400)
            default: (pct, mn, mx) = (0.30, 400, 500)
            }
            f += min(mx, max(mn, base * pct))
        }
        return Int((f / 5).rounded()) * 5
    }
}

// MARK: - Chart timing

/// First reservation chart: 8 hours before departure (the Jul 2025 rule —
/// it was 4h for years); trains leaving 05:00–14:00 are charted the previous
/// evening at 21:00.
func chartTime(departure: Date) -> Date {
    let depMinIST = Int(departure.addingTimeInterval(TimeInterval(istOffsetMin * 60))
        .timeIntervalSince1970 / 60) % (24 * 60)
    if depMinIST >= 5 * 60 && depMinIST < 14 * 60 {
        let prevDay = addDaysISO(istDateISO(departure), -1)
        return istDateTime(prevDay, minutes: 21 * 60)
    }
    return departure.addingTimeInterval(-8 * 3600)
}

// MARK: - Availability engine

enum Reservation {
    /// Advance Reservation Period — 60 days since Nov 2024.
    static let arpDays = 60

    /// RAC passengers per coach — two share each earmarked side-lower
    /// (SL: 7 berths, 3A: 4, 2A: 3 per the Railway Board allocation).
    private static let racPerCoach: [JClass: Int] = [
        .sleeper: 14, .ac3: 8, .ac3e: 8, .ac2: 6,
    ]
    /// Beyond this waitlist the PRS refuses to queue more bookings.
    private static let regretWL: [JClass: Int] = [
        .ac1: 20, .ac2: 50, .ac3: 90, .ac3e: 90, .sleeper: 160,
        .chair: 90, .execChair: 30, .execAnubhuti: 30, .vistadome: 20,
        .second: 180, .general: 999,
    ]

    /// How many coaches of a class this train carries.
    static func coachCount(_ train: Train, _ jClass: JClass) -> Int {
        let rng = SeededRng("rake:\(train.number):\(jClass.rawValue)")
        switch jClass {
        case .ac1: return 1
        case .ac2: return train.category == .rajdhani || train.category == .duronto
            ? rng.int(2, 3) : 1
        case .ac3: return train.category == .rajdhani || train.category == .duronto
            ? rng.int(8, 11) : rng.int(2, 4)
        case .ac3e: return rng.int(1, 2)
        case .sleeper: return rng.int(5, 8)
        // Vande Bharat runs fixed trainsets: 8-car (7 CC + 1 EC) or
        // 16-car (14 CC + 2 EC); Shatabdis haul long all-chair rakes
        case .chair:
            switch train.category {
            case .vandeBharat: return rng.next() < 0.5 ? 7 : 14
            case .shatabdi, .tejas: return rng.int(8, 12)
            default: return rng.int(3, 5)
            }
        case .execChair, .execAnubhuti: return train.category == .vandeBharat
            ? max(1, coachCount(train, .chair) / 7) : 1
        case .vistadome: return 1
        case .second: return rng.int(2, 4)
        case .general: return rng.int(2, 4)
        }
    }

    static func capacity(_ train: Train, _ jClass: JClass) -> Int {
        coachCount(train, jClass) * jClass.berthsPerCoach
    }

    /// Demand pressure for one (train, date, class): >1 oversubscribes.
    private static func demand(_ train: Train, _ dateISO: String, _ jClass: JClass) -> Double {
        let rng = SeededRng("demand:\(train.number):\(dateISO):\(jClass.rawValue)")
        var d = 0.55 + rng.next() * 0.85
        switch istWeekday(dateISO) {
        case .fri: d *= 1.30
        case .sun: d *= 1.25
        case .sat: d *= 1.10
        case .mon: d *= 1.05
        default: d *= 0.95
        }
        switch jClass {
        case .sleeper: d *= 1.30
        case .ac3, .ac3e: d *= 1.20
        case .second: d *= 1.15
        case .chair: d *= 1.05
        case .ac2: d *= 0.95
        case .execChair, .execAnubhuti, .vistadome: d *= 0.80
        case .ac1: d *= 0.70
        case .general: d *= 1.0
        }
        switch train.category {
        case .rajdhani, .vandeBharat: d *= 1.10
        case .express, .superfast: d *= 1.12
        default: break
        }
        return d
    }

    /// Bookings trickle early in the ARP window and surge near the journey —
    /// a cubic ease-in over the 60 days matches how Indian trains fill.
    private static func fillFraction(daysToGo: Double, demand: Double) -> Double {
        let t = min(1, max(0, 1 - daysToGo / Double(arpDays)))
        return demand * (0.30 * t + 0.70 * t * t * t)
    }

    /// The one availability figure everything else derives from: how deep
    /// into (or clear of) a quota's capacity the booking queue sits.
    /// Positive = berths left, negative = queued beyond capacity.
    private static func headroom(_ train: Train, _ jClass: JClass, _ quota: Quota,
                                 _ dateISO: String, daysToGo: Double) -> Int {
        let cap = max(1, Int(Double(capacity(train, jClass)) * quota.share))
        let d = demand(train, dateISO, jClass)
            * (quota == .general ? 1.0 : 1.15) // small quotas drain faster
        let booked = Int((Double(cap) * fillFraction(daysToGo: daysToGo, demand: d)).rounded())
        return cap - booked
    }

    static func availability(_ train: Train, _ jClass: JClass, _ quota: Quota,
                             _ dateISO: String, now: Date) -> AvailStatus {
        guard train.days.contains(istWeekday(dateISO)) else { return .noService }
        guard train.classes.contains(jClass.rawValue) else { return .noService }

        let departure = istDateTime(dateISO, minutes: parseHM(train.departureTime))
        if departure < now { return .departed }
        if now >= chartTime(departure: departure) { return .charting }

        let daysToGo = departure.timeIntervalSince(now) / 86_400
        if daysToGo > Double(arpDays) { return .noService }

        if quota == .tatkal {
            return tatkalAvailability(train, jClass, dateISO,
                                      departure: departure, now: now)
        }

        let room = headroom(train, jClass, quota, dateISO, daysToGo: daysToGo)
        if room > 0 { return .available(room) }

        let over = -room
        let racCap = quota == .general
            ? (racPerCoach[jClass] ?? 0) * coachCount(train, jClass) : 0
        if over <= racCap { return .rac(over) }

        let wl = over - racCap
        if wl > regretWL[jClass]! { return .regret }
        // GNWL serials include cleared bookings, so the left number runs
        // ahead of the live position.
        let rng = SeededRng("wlserial:\(train.number):\(dateISO):\(jClass.rawValue)")
        let cleared = Int(Double(wl) * (0.2 + rng.next() * 0.8))
        return .waitlist(.gnwl, booking: wl + cleared, current: wl)
    }

    /// When Tatkal booking opens for a travel date: 10:00 IST for AC classes,
    /// 11:00 for Sleeper / Second Sitting, the day before travel.
    static func tatkalOpen(travelDateISO: String, jClass: JClass) -> Date {
        let openHour = jClass == .sleeper || jClass == .second ? 11 : 10
        return istDateTime(addDaysISO(travelDateISO, -1), minutes: openHour * 60)
    }

    /// Tatkal: opens the day before at 10:00 IST (AC) / 11:00 (non-AC) and is
    /// usually gone within the hour on busy trains.
    private static func tatkalAvailability(_ train: Train, _ jClass: JClass,
                                           _ dateISO: String, departure: Date,
                                           now: Date) -> AvailStatus {
        // no Tatkal in AC First or Executive Chair
        guard jClass != .ac1 && jClass != .execChair && jClass != .execAnubhuti
        else { return .noService }
        let opens = tatkalOpen(travelDateISO: dateISO, jClass: jClass)
        if now < opens { return .opens(opens) }

        let cap = max(1, Int(Double(capacity(train, jClass)) * Quota.tatkal.share))
        let rng = SeededRng("tatkal:\(train.number):\(dateISO):\(jClass.rawValue)")
        // berths sold per hour once the window opens
        let rate = Double(cap) * (0.35 + rng.next() * 0.9)
        let hoursOpen = now.timeIntervalSince(opens) / 3600
        let sold = Int(rate * hoursOpen)
        let room = cap - sold
        if room > 0 { return .available(room) }
        let wl = -room
        if wl > 30 { return .regret }
        return .waitlist(.tqwl, booking: wl + rng.int(0, 6), current: wl)
    }

    /// The next `days` run dates with availability — the booking-grid strip.
    static func strip(_ train: Train, _ jClass: JClass, _ quota: Quota,
                      now: Date, days: Int = 7) -> [DayAvailability] {
        let today = istDateISO(now)
        var out: [DayAvailability] = []
        var offset = 0
        while out.count < days && offset <= arpDays {
            let d = addDaysISO(today, offset)
            offset += 1
            guard train.days.contains(istWeekday(d)) else { continue }
            out.append(DayAvailability(
                dateISO: d,
                status: availability(train, jClass, quota, d, now: now)
            ))
        }
        return out
    }
}

// MARK: - Rake composition

struct CoachSlot: Identifiable, Equatable {
    /// "B4", "S1", "PC" — what's painted on the coach.
    let code: String
    let jClass: JClass?
    let kind: Kind
    /// 1-based position from the engine, the number on platform boards.
    let position: Int

    enum Kind: Equatable {
        case loco, luggage, generator, general, pantry, reserved
    }

    var id: Int { position }
}

extension Reservation {
    /// The train's formation from the engine back, following IR marshalling
    /// convention: AC coaches in the middle, sleeper/general at the ends,
    /// pantry between the AC and sleeper blocks.
    static func rake(_ train: Train) -> [CoachSlot] {
        var slots: [(String, JClass?, CoachSlot.Kind)] = []
        let classes = Set(train.classes)
        let has = { (c: JClass) in classes.contains(c.rawValue) }

        if train.category == .vandeBharat {
            // self-propelled trainset, executive cars mid-rake
            let cc = coachCount(train, .chair)
            let ec = coachCount(train, .execChair)
            for i in 1...(cc + 1) / 2 { slots.append(("C\(i)", .chair, .reserved)) }
            for i in 1...ec { slots.append(("E\(i)", .execChair, .reserved)) }
            for i in ((cc + 1) / 2 + 1)...cc { slots.append(("C\(i)", .chair, .reserved)) }
            return slots.enumerated().map {
                CoachSlot(code: $1.0, jClass: $1.1, kind: $1.2, position: $0 + 1)
            }
        }

        slots.append(("LOCO", nil, .loco))
        slots.append(("EOG", nil, .generator))
        if has(.general) { slots.append(("GS1", .general, .general)) }
        if has(.second) {
            for i in 1...coachCount(train, .second) { slots.append(("D\(i)", .second, .reserved)) }
        }
        if has(.sleeper) {
            for i in 1...coachCount(train, .sleeper) { slots.append(("S\(i)", .sleeper, .reserved)) }
            // mixed rakes: pantry between the sleeper and AC blocks
            slots.append(("PC", nil, .pantry))
        }
        if has(.ac3e) {
            for i in 1...coachCount(train, .ac3e) { slots.append(("M\(i)", .ac3e, .reserved)) }
        }
        if has(.ac3) {
            for i in 1...coachCount(train, .ac3) { slots.append(("B\(i)", .ac3, .reserved)) }
        }
        // all-AC rakes (Rajdhani/Duronto): pantry between the 3A and 2A blocks
        if !has(.sleeper) && (has(.ac3) || has(.ac2) || has(.ac1)) {
            slots.append(("PC", nil, .pantry))
        }
        if has(.ac2) {
            for i in 1...coachCount(train, .ac2) { slots.append(("A\(i)", .ac2, .reserved)) }
        }
        if has(.ac1) { slots.append(("H1", .ac1, .reserved)) }
        if has(.chair) {
            // day rakes (Shatabdi/Jan Shatabdi): pantry splits the chair block
            let cc = coachCount(train, .chair)
            let pantryAt = has(.sleeper) || has(.ac3) ? 0 : (cc + 1) / 2
            for i in 1...cc {
                slots.append(("C\(i)", .chair, .reserved))
                if i == pantryAt { slots.append(("PC", nil, .pantry)) }
            }
        }
        if has(.execChair) { slots.append(("E1", .execChair, .reserved)) }
        if has(.execAnubhuti) { slots.append(("EA1", .execAnubhuti, .reserved)) }
        if has(.vistadome) { slots.append(("V1", .vistadome, .reserved)) }
        if has(.general) { slots.append(("GS2", .general, .general)) }
        // premium all-AC LHB rakes carry generator vans at both ends;
        // mixed rakes end on the seating-cum-luggage coach
        slots.append(has(.general) || has(.second) ? ("SLR", nil, .luggage)
                                                   : ("EOG", nil, .generator))

        return slots.enumerated().map {
            CoachSlot(code: $1.0, jClass: $1.1, kind: $1.2, position: $0 + 1)
        }
    }
}

extension Reservation {
    /// Parse a live formation string from the chart ("L SLR UR UR S7 S6 …
    /// B2 B1 A1 …") into coach slots. Tokens that aren't coaches (trailing
    /// station codes, noise) are skipped; nil when too little survives to be
    /// a believable rake.
    static func parseRake(_ s: String) -> [CoachSlot]? {
        var slots: [(String, JClass?, CoachSlot.Kind)] = []
        for raw in s.uppercased().split(separator: " ") {
            let tok = String(raw)
            let digits = tok.drop { !$0.isNumber }
            let prefix = tok.prefix { !$0.isNumber }
            switch tok {
            case "L", "LOCO", "ENG", "WAP", "WAG", "WDP", "WDM":
                slots.append(("LOCO", nil, .loco)); continue
            case "SLR", "SLRD", "SLRM", "GBS":
                slots.append((tok, nil, .luggage)); continue
            case "EOG", "PWR", "GNR":
                slots.append(("EOG", nil, .generator)); continue
            case "PC", "PAN", "BUF", "RMS":
                slots.append(("PC", nil, .pantry)); continue
            case "UR", "GEN", "GS":
                slots.append((tok, .general, .general)); continue
            case "D":
                // bare D on charts is a reserved Second Sitting coach
                slots.append((tok, .second, .reserved)); continue
            default: break
            }
            let jClass: JClass?
            switch prefix {
            case "S": jClass = .sleeper
            case "B": jClass = .ac3
            case "M": jClass = .ac3e
            case "A": jClass = .ac2
            case "H", "HA": jClass = .ac1
            case "C", "CC": jClass = .chair
            case "E", "EC": jClass = .execChair
            case "D": jClass = .second
            case "V": jClass = .vistadome
            case "GS", "UR": jClass = .general
            default: jClass = nil
            }
            if let jClass, !digits.isEmpty, tok.count <= 4 {
                slots.append((tok, jClass,
                              jClass == .general ? .general : .reserved))
            }
            // anything else (e.g. a trailing "VSKP" slip destination) is noise
        }
        guard slots.count >= 4 else { return nil }
        return slots.enumerated().map {
            CoachSlot(code: $1.0, jClass: $1.1, kind: $1.2, position: $0 + 1)
        }
    }
}

// MARK: - Berth numbering

enum BerthType: String {
    case lower = "LB", middle = "MB", upper = "UB"
    case sideLower = "SL", sideUpper = "SU"
    case window = "WS", aisle = "AS"

    var label: String {
        switch self {
        case .lower: return "Lower"
        case .middle: return "Middle"
        case .upper: return "Upper"
        case .sideLower: return "Side Lower"
        case .sideUpper: return "Side Upper"
        case .window: return "Window"
        case .aisle: return "Aisle"
        }
    }
}

/// The physical berth for a number, per the coach's bay pattern. SL/3A bays
/// of eight: LB MB UB · LB MB UB · SL SU. 2A bays of six (no middle).
func berthType(_ jClass: JClass, _ berth: Int) -> BerthType {
    switch jClass {
    case .sleeper, .ac3, .ac3e:
        switch berth % 8 {
        case 1, 4: return .lower
        case 2, 5: return .middle
        case 3, 6: return .upper
        case 7: return .sideLower
        default: return .sideUpper
        }
    case .ac2:
        switch berth % 6 {
        case 1, 3: return .lower
        case 2, 4: return .upper
        case 5: return .sideLower
        default: return .sideUpper
        }
    case .ac1:
        return berth % 2 == 1 ? .lower : .upper
    default:
        // chair cars: window/aisle by row position (3+2 layout)
        switch berth % 5 {
        case 1, 0: return .window
        default: return .aisle
        }
    }
}

// MARK: - Waitlist confidence

extension Reservation {
    /// Railly's waitlist-confirmation model — the rail analogue of Flighty's
    /// delay prediction. Given a live WL position it estimates the odds the
    /// ticket clears to CNF by chart preparation and says why in one line.
    /// Tuned to how each list actually moves: GNWL clears against every
    /// cancellation on the route, RLWL/PQWL only against a slice of it, and
    /// TQWL barely moves at all once the chart is drawn.
    struct WLConfidence {
        /// 0…100 model estimate that the position confirms by charting
        let percent: Int
        /// plain-English "why", e.g. "GNWL from the originating station clears
        /// fast on this route"
        let rationale: String
    }

    /// Share of a quota's berths that typically free up before charting —
    /// cancellations plus the RAC buffer converting to CNF. Cheap, speculative
    /// classes churn hard; premium cabins barely move.
    private static let clearanceShare: [JClass: Double] = [
        .sleeper: 0.55, .ac3: 0.44, .ac3e: 0.44, .ac2: 0.34, .ac1: 0.22,
        .chair: 0.42, .execChair: 0.26, .execAnubhuti: 0.26, .vistadome: 0.22,
        .second: 0.55, .general: 0.60,
    ]

    static func wlConfidence(_ train: Train, _ jClass: JClass, kind: WLKind,
                             position: Int, daysToGo: Double) -> WLConfidence {
        let pos = max(1, position)
        let cap = max(1, Int(Double(capacity(train, jClass)) * Quota.general.share))

        // GNWL sees every cancellation on the route; the remote lists a slice
        let kindFactor: Double
        switch kind {
        case .gnwl: kindFactor = 1.00
        case .wl:   kindFactor = 0.75
        case .rlwl: kindFactor = 0.45
        case .rswl: kindFactor = 0.42
        case .pqwl: kindFactor = 0.30
        case .tqwl: kindFactor = 0.10
        }

        // more days to charting means more time for berths to free up, with
        // diminishing returns as the journey nears
        let t = min(1, max(0, daysToGo / Double(arpDays)))
        let windowFactor = 0.20 + 0.80 * (1 - (1 - t) * (1 - t))

        let expectedClears = Double(cap) * (clearanceShare[jClass] ?? 0.40)
            * kindFactor * windowFactor

        // logistic on how far the expected clears overshoot the position
        let margin = (expectedClears - Double(pos)) / max(2.5, Double(pos) * 0.55 + 2)
        var pct = 100.0 / (1 + exp(-margin))
        if kind == .tqwl { pct = min(pct, 20.0) } // sealed at charting, rarely moves
        let percent = Int(min(94.0, max(3.0, pct)).rounded())

        let confident = percent >= 68
        let slim = percent < 32
        let rationale: String
        switch kind {
        case .gnwl, .wl:
            rationale = confident
                ? "GNWL from the originating station clears fast on this route"
                : slim
                    ? "Deep in the general queue — needs heavy cancellations to clear"
                    : "General queue, clears steadily as cancellations come in"
        case .rlwl:
            rationale = confident
                ? "Remote-station list, but a short-enough position to clear"
                : "RLWL clears only against local cancellations — moves slowly"
        case .rswl:
            rationale = "Roadside-station list — a small berth pool that clears slowly"
        case .pqwl:
            rationale = confident
                ? "Pooled list but a short position — a few cancellations confirm it"
                : "Pooled-quota list is the weakest — it rarely clears fully"
        case .tqwl:
            rationale = "Tatkal waitlist barely moves once the chart prepares"
        }
        return WLConfidence(percent: percent, rationale: rationale)
    }
}
