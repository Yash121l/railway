import Foundation

/// Port of src/lib/trips.ts — the demo persona's tickets, derived live.

func tripId(_ trainNumber: String, _ runDate: String) -> String {
    "\(trainNumber)_\(runDate)"
}

private let coaches = ["A1", "B2", "B4", "C3", "C7", "E1"]
private let berths = ["LB", "UB", "SL", "SU", "WS", "MB"]

struct Booking {
    let coach: String
    let seat: String
    let pnr: String
}

/// Seeded booking details so a trip always shows the same seat and PNR.
func bookingFor(_ id: String) -> Booking {
    let rng = SeededRng("booking:\(id)")
    let chairCar = id.hasPrefix("2") || id.hasPrefix("120")
    let coach = chairCar ? "C\(rng.int(1, 8))" : rng.pick(coaches)
    let seat = chairCar
        ? "\(rng.int(1, 78))\(rng.pick(["A", "B", "C", "D", "E"]))"
        : "\(rng.int(1, 72)) \(rng.pick(berths))"
    // IR PNRs are exactly 10 digits — keep the middle term below 8e8.
    let pnr = String(2_000_000_000 + Int(rng.next() * 800_000_000) * 10 + rng.int(0, 9))
    return Booking(coach: coach, seat: seat, pnr: pnr)
}

func heldTrip(_ train: Train, _ live: LiveStatus) -> HeldTrip {
    let id = tripId(train.number, live.runDate)
    let booking = bookingFor(id)
    return HeldTrip(
        id: id, train: train, live: live,
        coach: booking.coach, seat: booking.seat, pnr: booking.pnr
    )
}

struct MyTrips {
    let live: [HeldTrip]
    let upcoming: [HeldTrip]
    let past: [HeldTrip]
}

func getMyTrips(_ now: Date) -> MyTrips {
    // Every run in its live window — a 38h overnight train can have a
    // mid-journey run and tonight's boarding run at once; both must show.
    var live: [HeldTrip] = allTrains.flatMap { train in
        getActiveStatuses(train, now)
            .filter { $0.phase == .enroute || $0.phase == .boarding }
            .map { heldTrip(train, $0) }
    }
    live.sort { a, b in
        if a.live.phase != b.live.phase { return a.live.phase == .enroute }
        return a.live.progress > b.live.progress
    }
    live = Array(live.prefix(4))
    let liveIds = Set(live.map(\.id))

    var upcoming: [HeldTrip] = allTrains.compactMap { train in
        guard let next = getScheduledStatus(train, now) else { return nil }
        let trip = heldTrip(train, next)
        return liveIds.contains(trip.id) ? nil : trip
    }
    upcoming.sort { $0.live.departsAt < $1.live.departsAt }
    upcoming = Array(upcoming.prefix(3))

    var past: [HeldTrip] = allTrains.compactMap { train in
        guard let runDate = lastCompletedRunDate(train, now) else { return nil }
        let status = getLiveStatusForRun(train, runDate: runDate, now: now)
        return status.phase == .arrived ? heldTrip(train, status) : nil
    }
    past.sort { $0.live.arrivesEst > $1.live.arrivesEst }
    past = Array(past.prefix(4))

    return MyTrips(live: live, upcoming: upcoming, past: past)
}

/// Wrap any train's current run as a trip — used by search and Track.
func liveTripFor(_ train: Train, _ now: Date) -> HeldTrip {
    heldTrip(train, getLiveStatus(train, now))
}

/// Resolve one trip by id ("trainNo_yyyy-MM-dd") — the detail screen's entry.
func getTrip(_ id: String, _ now: Date) -> HeldTrip? {
    let parts = id.split(separator: "_", maxSplits: 1).map(String.init)
    guard parts.count == 2,
          let train = allTrains.first(where: { $0.number == parts[0] })
    else { return nil }
    return heldTrip(train, getLiveStatusForRun(train, runDate: parts[1], now: now))
}
