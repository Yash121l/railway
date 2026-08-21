import Foundation

/// One held ticket: a specific train on a specific run date.
struct TripRecord: Codable, Identifiable, Equatable {
    let number: String
    /// "yyyy-MM-dd" IST
    let runDate: String
    var addedAt: Date
    /// Ticket details, only if the user actually entered a booking (or a demo
    /// seed set one). Optional (default nil) so older saved trips decode fine
    /// and tracked-only trips carry no fabricated ticket.
    var coach: String? = nil
    var seat: String? = nil
    var pnr: String? = nil
    /// Every confirmed berth on the PNR ("B4 · 34 LB"), kept when a booking is
    /// imported for a multi-passenger party. Optional (default nil) so existing
    /// Documents/trips.json still decodes.
    var berths: [String]? = nil

    var id: String { tripId(number, runDate) }

    var booking: Booking? {
        guard let coach, let seat, let pnr else { return nil }
        return Booking(coach: coach, seat: seat, pnr: pnr)
    }
}

struct MyTrips {
    let live: [HeldTrip]
    let upcoming: [HeldTrip]
    let past: [HeldTrip]

    var isEmpty: Bool { live.isEmpty && upcoming.isEmpty && past.isEmpty }
}

/// The user's own trips, persisted to Documents/trips.json. Snapshot/demo
/// launches seed an ephemeral copy instead so marketing runs never pollute
/// the real list.
@MainActor
final class TripStore: ObservableObject {
    static let shared = TripStore()

    @Published private(set) var records: [TripRecord] = []
    private var ephemeral = false

    private let fileURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("trips.json")
    }()

    private init() {
        if let data = try? Data(contentsOf: fileURL),
           let recs = try? JSONDecoder().decode([TripRecord].self, from: data) {
            records = recs
        }
    }

    func isHeld(_ id: String) -> Bool { records.contains { $0.id == id } }

    /// The stored ticket for a trip, if the user has one (nil for tracked-only).
    func booking(forId id: String) -> Booking? {
        records.first { $0.id == id }?.booking
    }

    /// The full stored record for a trip — drives the booking card and editor.
    func record(forId id: String) -> TripRecord? {
        records.first { $0.id == id }
    }

    /// `booking` carries ticket details when the trip arrives via a PNR
    /// import; plain adds stay ticketless. `berths` keeps the whole party when
    /// a multi-passenger PNR is imported.
    func add(_ train: Train, runDate: String, booking: Booking? = nil,
             berths: [String]? = nil) {
        var rec = TripRecord(number: train.number, runDate: runDate, addedAt: Date())
        rec.coach = booking?.coach
        rec.seat = booking?.seat
        rec.pnr = booking?.pnr
        rec.berths = berths
        guard !isHeld(rec.id) else { return }
        records.append(rec)
        save()
    }

    /// Track a run carrying only its PNR — coach/berth stay unassigned until
    /// the chart prepares, so the detail screen shows the PNR alone (no
    /// fabricated "— · —" card).
    func addPNROnly(_ train: Train, runDate: String, pnr: String) {
        var rec = TripRecord(number: train.number, runDate: runDate, addedAt: Date())
        rec.pnr = pnr
        guard !isHeld(rec.id) else { return }
        records.append(rec)
        save()
    }

    /// Update the ticket on a held trip (from the booking editor). Empty fields
    /// clear that detail, so an unassigned coach/berth reverts to a PNR-only
    /// card.
    /// Edit the ticket fields the editor can actually express. `berths` is left
    /// alone on purpose: it is only ever populated by a multi-passenger PNR
    /// import, and the editor has no field for it, so writing nil here silently
    /// destroyed the whole party's berths when someone fixed a typo in a coach.
    func setBooking(_ id: String, coach: String?, seat: String?, pnr: String?) {
        guard let idx = records.firstIndex(where: { $0.id == id }) else { return }
        records[idx].coach = coach
        records[idx].seat = seat
        records[idx].pnr = pnr
        save()
    }

    func remove(_ id: String) {
        records.removeAll { $0.id == id }
        save()
    }

    /// Delete every trip, and everything else derived from them.
    ///
    /// This backs "Delete All Trips", whose own footer says Railly keeps no
    /// copy anywhere else. That was only true of trips.json, so watched PNRs,
    /// their status snapshots and the analytics buffer all had to be cleared
    /// here too.
    func removeAll() {
        records = []
        save()
        PNRWatch.forgetAll()
        Analytics.shared.reset()
    }

    private func save() {
        guard !ephemeral else { return }
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    /// JSON export for Settings → Account Data.
    func exportJSON(bank: TrainBank) -> String {
        struct Export: Codable {
            let exportedAt: String
            let app: String
            let trips: [ExportTrip]
        }
        struct ExportTrip: Codable {
            let train: String
            let name: String
            let from: String
            let to: String
            let runDate: String
            let addedAt: Date
        }
        let trips = records.map { rec -> ExportTrip in
            let t = bank.cached(rec.number)
            return ExportTrip(
                train: rec.number,
                name: t?.displayName ?? "",
                from: t?.origin.code ?? "",
                to: t?.destination.code ?? "",
                runDate: rec.runDate,
                addedAt: rec.addedAt
            )
        }
        let export = Export(
            exportedAt: istDateISO(Date()),
            app: "Railly",
            trips: trips
        )
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return String(data: (try? enc.encode(export)) ?? Data(), encoding: .utf8) ?? "{}"
    }

    // MARK: Derivation

    /// Classify every held trip by the phase of its own run.
    func myTrips(_ now: Date, bank: TrainBank) -> MyTrips {
        var live: [HeldTrip] = []
        var upcoming: [HeldTrip] = []
        var past: [HeldTrip] = []
        for rec in records {
            guard let train = bank.cached(rec.number) else { continue }
            let status = getLiveStatusForRun(train, runDate: rec.runDate, now: now)
            let trip = heldTrip(train, status, isHeld: true, booking: rec.booking)
            switch status.phase {
            case .enroute, .boarding: live.append(trip)
            case .scheduled: upcoming.append(trip)
            case .arrived: past.append(trip)
            }
        }
        live.sort { a, b in
            if a.live.phase != b.live.phase { return a.live.phase == .enroute }
            return a.live.progress > b.live.progress
        }
        upcoming.sort { $0.live.departsAt < $1.live.departsAt }
        past.sort { $0.live.arrivesEst > $1.live.arrivesEst }
        return MyTrips(live: live, upcoming: upcoming, past: past)
    }

    // MARK: Demo / snapshot seeding

    /// Fill the store from the seed trains the way the old demo persona did:
    /// whatever is on rails right now, the next few departures, and a few
    /// completed runs. In-memory only.
    func seedDemo(bank: TrainBank, now: Date) {
        ephemeral = true
        // demo trips carry a seeded ticket so the marketing screens still show
        // a PNR/berth; real user-added trips never fabricate one.
        func demoRec(_ train: Train, _ runDate: String) -> TripRecord {
            let b = bookingFor(train, runDate)
            return TripRecord(number: train.number, runDate: runDate, addedAt: now,
                              coach: b.coach, seat: b.seat, pnr: b.pnr)
        }
        var recs: [TripRecord] = []
        for number in bank.seedNumbers {
            guard let train = bank.cached(number) else { continue }
            for status in getActiveStatuses(train, now)
            where status.phase == .enroute || status.phase == .boarding {
                recs.append(demoRec(train, status.runDate))
            }
            if let next = getScheduledStatus(train, now) {
                recs.append(demoRec(train, next.runDate))
            }
            if let lastDate = lastCompletedRunDate(train, now) {
                recs.append(demoRec(train, lastDate))
            }
        }
        // dedupe, keep a Flighty-sized list
        var seen = Set<String>()
        records = recs.filter { seen.insert($0.id).inserted }
    }
}
