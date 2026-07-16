import Foundation

/// Trip identity and booking helpers. The trips themselves live in TripStore.

func tripId(_ trainNumber: String, _ runDate: String) -> String {
    "\(trainNumber)_\(runDate)"
}

struct Booking: Codable, Equatable {
    let coach: String
    let seat: String
    let pnr: String
}

/// Seeded booking for demo trips — drawn from the train's actual rake so the
/// coach exists in the coach-position strip and the berth number obeys the
/// class's real layout.
func bookingFor(_ train: Train, _ runDate: String) -> Booking {
    let rng = SeededRng("booking:\(tripId(train.number, runDate))")
    let reservable = JClass.reservable(from: train.classes)
    // demo persona rides mid-premium: 3A/CC first, then whatever the rake has
    let jc = reservable.first { $0 == .ac3 || $0 == .chair }
        ?? reservable.first ?? .sleeper
    let coaches = Reservation.rake(train).filter { $0.jClass == jc }
    let coach = coaches.isEmpty ? "B2" : rng.pick(coaches.map(\.code))
    let berth = rng.int(1, jc.berthsPerCoach)
    let seat = "\(berth) \(berthType(jc, berth).rawValue)"
    // IR PNRs are exactly 10 digits; keep the leading digit a real PRS code
    let pnr = "\(rng.int(1, 9))" + String(format: "%09d", Int(rng.next() * 1e9))
    return Booking(coach: coach, seat: seat, pnr: groupPNR(pnr))
}

func heldTrip(_ train: Train, _ live: LiveStatus, isHeld: Bool,
              booking: Booking? = nil) -> HeldTrip {
    HeldTrip(
        id: tripId(train.number, live.runDate),
        train: train, live: live,
        booking: booking,
        isHeld: isHeld
    )
}

/// Wrap any train's current run as a trip — used by Track and search. A tracked
/// train has no ticket, so its booking is looked up (nil unless the user holds
/// one for this run).
@MainActor
func liveTripFor(_ train: Train, _ now: Date) -> HeldTrip {
    let live = getLiveStatus(train, now)
    let id = tripId(train.number, live.runDate)
    return heldTrip(train, live, isHeld: TripStore.shared.isHeld(id),
                    booking: TripStore.shared.booking(forId: id))
}

/// Resolve one trip by id ("trainNo_yyyy-MM-dd") — the detail screen's entry.
/// Works for any train already in the bank (held, seeded, or fetched).
@MainActor
func getTrip(_ id: String, _ now: Date) -> HeldTrip? {
    let parts = id.split(separator: "_", maxSplits: 1).map(String.init)
    guard parts.count == 2,
          let train = TrainBank.shared.cached(parts[0])
    else { return nil }
    let status = getLiveStatusForRun(train, runDate: parts[1], now: now)
    return heldTrip(train, status, isHeld: TripStore.shared.isHeld(id),
                    booking: TripStore.shared.booking(forId: id))
}
