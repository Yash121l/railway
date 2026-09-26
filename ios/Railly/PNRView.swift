import SwiftUI

/// PNR status, the front door of Indian rail travel. Ten digits in, the whole
/// booking out: the party's status in one line, chart state, the journey,
/// every passenger's booking → current status, and a one-tap import into My
/// Trips with the real coach and berths.

/// PNRs print with the conventional 3-7 split: "852-4136972".
func groupPNR(_ pnr: String) -> String {
    guard pnr.count > 3 else { return pnr }
    return pnr.prefix(3) + "-" + pnr.dropFirst(3)
}

private func seatTone(_ s: SeatStatus) -> Color {
    switch s {
    case .cnf, .noSeat: return DS.onTimeText
    case .rac: return DS.rac
    case .waitlist, .notConfirmed: return DS.lateText
    }
}

struct PNRResultView: View {
    let pnr: String
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PNRWatch.recentKey) private var recentCSV = ""
    @State private var outcome: PNROutcome?
    @State private var added = false

    var body: some View {
        Group {
            switch outcome {
            case .none:
                skeleton
            case .found(let info):
                loaded(info)
            case .notFound(let reason):
                failure(icon: "questionmark.folder",
                        title: "No booking found",
                        message: "\(reason).\nCheck the 10 digits. Flushed or very old PNRs stop resolving.",
                        secondary: ("Check Another PNR", { dismiss() }))
            case .offline:
                failure(icon: "wifi.exclamationmark",
                        title: "Couldn't reach the railway",
                        message: "The PNR services didn't answer. Check your connection and try again.",
                        secondary: nil)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.sheet)
        .navigationTitle("PNR \(groupPNR(pnr))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    if router.modal != nil { router.modal = nil } else { dismiss() }
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close")
            }
        }
        .presentationDetents([.large])
        // .task re-fires on every reappearance; keep a result we already have
        .task { if outcome == nil { await load() } }
    }

    private func load() async {
        outcome = nil
        let result = await PNRService.lookup(pnr, now: Date())
        // a cancelled fetch must not persist a bogus "offline" verdict
        guard !Task.isCancelled else { return }
        if case .found(let info) = result { remember(info) }
        withAnimation(.snappy(duration: 0.3)) { outcome = result }
    }

    private func remember(_ info: PNRInfo) {
        var list = recentCSV.split(separator: ",").map(String.init)
        list.removeAll { $0.hasPrefix("\(info.pnr):") }
        list.insert("\(info.pnr):\(info.train.number):\(info.runDate)", at: 0)
        recentCSV = list.prefix(5).joined(separator: ",")
        // this PNR is now watched: queue a background re-check window. Notification
        // permission is asked when the user turns an alert on, not on a lookup.
        PNRWatch.schedule()
        Analytics.shared.log(.pnrWatched, ["train": info.train.number])
    }

    // MARK: States

    private var skeleton: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous).fill(DS.fill).frame(height: 136)
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous).fill(DS.fill).frame(height: 150)
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous).fill(DS.fill).frame(height: 120)
            }
            .skeletonPulse()
            HStack(spacing: 8) {
                ProgressView()
                Text("Checking with the railway…")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding(.horizontal, DS.gutter)
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
    }

    private func failure(icon: String, title: String, message: String,
                         secondary: (String, () -> Void)?) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.dsTitle)
                .foregroundStyle(DS.secondary)
            Text(title)
                .font(.dsSection)
                .foregroundStyle(DS.ink)
            Text(message)
                .font(.dsCallout)
                .foregroundStyle(DS.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            DSButton(title: "Try Again", systemImage: "arrow.clockwise") {
                Task { await load() }
            }
            if let secondary {
                DSButton(title: secondary.0, style: .secondary, action: secondary.1)
            }
        }
        .padding(.horizontal, DS.gutter)
        .padding(.bottom, 12)
    }

    // MARK: Result

    private func loaded(_ info: PNRInfo) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero(info)
                if let note = info.routeNote {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(DS.rac)
                        Text(note)
                            .font(.dsFootnote)
                            .foregroundStyle(DS.ink2)
                    }
                    .font(.dsFootnote)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DS.amberWash, in: RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous))
                }
                trainCard(info)
                passengers(info)
                ticketFacts(info)
                if confirmedCoach(info) != nil || info.realRake != nil {
                    CoachPositionCard(train: info.train,
                                      highlight: confirmedCoach(info),
                                      rakeOverride: info.realRake)
                }
                Text(sourceNote(info.source))
                    .font(.dsCaption)
                    .foregroundStyle(DS.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.horizontal, DS.gutter)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar(info) }
        .overlay {
            if added { AddedHUD() }
        }
        .sensoryFeedback(trigger: added) { _, isShowing in isShowing ? .success : nil }
    }

    private func sourceNote(_ source: PNRSource) -> String {
        switch source {
        case .confirmTkt:
            return "Live PNR status via ConfirmTkt · journey data via erail.in"
        case .easeMyTrip:
            return "Live PNR status via EaseMyTrip · journey data via erail.in"
        case .indianRail:
            return "PNR status via indianrailapi.com · journey data via erail.in"
        case .simulated:
            return "Demo PNR: a deterministic simulation of PRS rules.\nReal PNRs resolve live in normal launches."
        }
    }

    // MARK: Hero

    /// The party's worst current status sets the hero, so one look says
    /// whether everyone boards.
    private func hero(_ info: PNRInfo) -> some View {
        let worst = info.passengers.map(\.current).min { rank($0) < rank($1) } ?? .notConfirmed
        let confirmed = info.passengers.filter { $0.current.isConfirmed }.count
        let color = seatTone(worst)
        let wash = worst.isConfirmed ? DS.onTimeWash : isRAC(worst) ? DS.amberWash : DS.lateWash

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(info.train.number) · \(fmtDay(info.departure))").eyebrow()
                Spacer()
                DSChip(text: "\(info.jClass.rawValue) · \(info.quota.rawValue)", color: DS.ink)
            }
            HStack(spacing: 10) {
                Image(systemName: heroIcon(worst))
                    .font(.dsSection)
                Text(headline(worst, info: info))
                    .font(.dsTitle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(color)
            if !info.allConfirmed && confirmed > 0 {
                Text("\(confirmed) of \(info.passengers.count) passengers confirmed")
                    .font(.dsSubhead)
                    .foregroundStyle(DS.ink2)
            }
            if isRAC(worst) {
                Text("You can board, sharing a side-lower berth.")
                    .font(.dsSubhead)
                    .foregroundStyle(DS.ink2)
            }
            Label {
                Text(info.chartPrepared
                    ? "Chart prepared. Statuses are final."
                    : "Chart expected around \(fmtTime(chartTime(departure: info.departure))), \(fmtDay(chartTime(departure: info.departure)))")
            } icon: {
                Image(systemName: info.chartPrepared ? "checkmark.seal.fill" : "clock")
            }
            .font(.dsCallout)
            .foregroundStyle(DS.ink2)

            if case .waitlist(let kind, let pos) = worst, !info.chartPrepared {
                Rectangle().fill(color.opacity(0.18)).frame(height: 1).padding(.vertical, 2)
                confidence(info, kind: kind, position: pos)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(wash, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
    }

    /// Railly's waitlist model beside ConfirmTkt's own prediction when the feed
    /// sent one, each labelled with its source.
    private func confidence(_ info: PNRInfo, kind: WLKind, position: Int) -> some View {
        let c = Reservation.wlConfidence(
            info.train, info.jClass, kind: kind, position: max(1, position),
            daysToGo: info.departure.timeIntervalSince(Date()) / 86_400)
        let tone = confidenceTone(c.percent)
        let ctPrediction = info.passengers.compactMap(\.prediction).first
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(c.percent)%")
                    .font(.dsStat)
                    .foregroundStyle(tone)
                    .monospacedDigit()
                Text("chance to confirm")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.ink2)
                Spacer()
                EstimateTag(text: "Railly estimate")
            }
            DSProgress(value: Double(c.percent) / 100, tint: tone)
            Text(c.rationale)
                .font(.dsFootnote)
                .foregroundStyle(DS.ink2)
            if let ctPrediction {
                (Text("ConfirmTkt prediction: ").foregroundStyle(DS.secondary)
                    + Text(ctPrediction).fontWeight(.semibold).foregroundStyle(DS.rac))
                    .font(.dsFootnote)
            }
        }
    }

    private func confidenceTone(_ pct: Int) -> Color {
        pct >= 68 ? DS.onTimeText : pct >= 32 ? DS.rac : DS.lateText
    }

    private func rank(_ s: SeatStatus) -> Int {
        switch s {
        case .notConfirmed: return 0
        case .waitlist: return 1
        case .rac: return 2
        case .cnf, .noSeat: return 3
        }
    }

    private func isRAC(_ s: SeatStatus) -> Bool {
        if case .rac = s { return true }
        return false
    }

    private func heroIcon(_ s: SeatStatus) -> String {
        switch s {
        case .cnf, .noSeat: return "checkmark.circle.fill"
        case .rac: return "person.2.fill"
        case .waitlist: return "hourglass"
        case .notConfirmed: return "xmark.circle.fill"
        }
    }

    private func headline(_ worst: SeatStatus, info: PNRInfo) -> String {
        let n = info.passengers.count
        switch worst {
        case .cnf, .noSeat:
            return n == 1 ? "Confirmed" : "All \(n) confirmed"
        case .rac(let pos, _, _):
            return pos > 0 ? "RAC \(pos)" : "RAC"
        case .waitlist(let kind, let pos):
            return pos > 0 ? "Waitlisted · \(kind.rawValue) \(pos)" : "Waitlisted · \(kind.rawValue)"
        case .notConfirmed:
            return "Not confirmed"
        }
    }

    // MARK: Cards

    private func trainCard(_ info: PNRInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                TrainMark(category: info.train.category, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(info.train.number) · \(info.train.category.label)")
                        .font(.dsCaption)
                        .foregroundStyle(DS.secondary)
                    Text(info.train.displayName)
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            JourneyTimesRow(departure: info.departure, arrival: info.arrival,
                            from: info.from, to: info.to,
                            detail: fmtDay(info.departure))
        }
        .dsCard()
    }

    private func passengers(_ info: PNRInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            DSSectionHeader(title: "Passengers",
                            subtitle: info.passengers.count == 1 ? "1 on this PNR" : "\(info.passengers.count) on this PNR")
            VStack(spacing: 0) {
                ForEach(info.passengers) { p in
                    passengerRow(p, info: info)
                    if p.number < info.passengers.count {
                        Rectangle().fill(DS.separator).frame(height: 1).padding(.leading, 56)
                    }
                }
            }
            .dsCard(padding: 0)
        }
    }

    private func passengerRow(_ p: PNRPassenger, info: PNRInfo) -> some View {
        HStack(spacing: 12) {
            Text("\(p.number)")
                .font(.dsSubhead)
                .foregroundStyle(DS.ink)
                .frame(width: 30, height: 30)
                .background(DS.fill, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Passenger \(p.number)")
                    .font(.dsHeadline)
                    .foregroundStyle(DS.ink)
                Text("Booked \(p.booking.text)")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
                    .monospacedDigit()
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                DSChip(text: shortStatus(p.current), color: seatTone(p.current))
                if let seat = seatLine(p.current, info: info) {
                    Text(seat)
                        .font(.dsFootnote)
                        .foregroundStyle(DS.ink2)
                        .monospacedDigit()
                } else if let prediction = p.prediction {
                    Text("ConfirmTkt: \(prediction)")
                        .font(.dsCaption)
                        .foregroundStyle(DS.rac)
                }
            }
        }
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    /// The chip keeps the status word; coach and berth get their own line.
    private func shortStatus(_ s: SeatStatus) -> String {
        switch s {
        case .cnf: return "CNF"
        case .rac(let pos, _, _): return pos > 0 ? "RAC \(pos)" : "RAC"
        default: return s.text
        }
    }

    private func seatLine(_ s: SeatStatus, info: PNRInfo) -> String? {
        switch s {
        case .cnf(.some(let coach), .some(let berth), let type):
            let kind = type.map { " · \($0.label) \(info.jClass.isBerthed ? "berth" : "seat")" } ?? ""
            return "\(coach) · \(berth)\(kind)"
        case .rac(_, .some(let coach), .some(let berth)):
            return "\(coach) · \(berth)"
        default:
            return nil
        }
    }

    private func ticketFacts(_ info: PNRInfo) -> some View {
        HStack(alignment: .top, spacing: 0) {
            fact("Class", info.jClass.rawValue, info.jClass.label)
            divider
            fact("Quota", info.quota.label, nil)
            divider
            fact(info.fareExact ? "Fare paid" : "Fare", "₹\(info.fare.formatted())",
                 info.fareExact ? nil : "Estimated")
            divider
            fact("Issued by", info.issuedBy.replacingOccurrences(of: "PRS ", with: ""), nil)
        }
        .dsCard(padding: 14)
    }

    private var divider: some View {
        Rectangle().fill(DS.separator).frame(width: 1, height: 40).padding(.horizontal, 8)
    }

    private func fact(_ label: String, _ value: String, _ note: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(DS.secondary)
            Text(value)
                .font(.dsHeadline)
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let note {
                Text(note)
                    .font(.dsCaption)
                    .foregroundStyle(DS.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func confirmedCoach(_ info: PNRInfo) -> String? {
        for p in info.passengers {
            if case .cnf(.some(let coach), _, _) = p.current { return coach }
        }
        return nil
    }

    // MARK: Actions

    private func actionBar(_ info: PNRInfo) -> some View {
        let held = store.isHeld(info.tripId)
        return HStack(spacing: 10) {
            DSButton(title: "Track", systemImage: "dot.radiowaves.left.and.right", style: .secondary) {
                router.focus(info.tripId)
            }
            .frame(maxWidth: 140)
            DSButton(title: held ? "View Trip" : "Add to My Trips",
                     systemImage: held ? "arrow.right" : "plus") {
                if held { router.focus(info.tripId) } else { addToTrips(info) }
            }
            .disabled(added)
        }
        .padding(.horizontal, DS.gutter)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(DS.sheet)
    }

    /// Import the booking: the trip lands in My Trips with the real PNR and
    /// (when confirmed) the whole party's coach/berths. An unassigned ticket
    /// carries the PNR alone, never a fabricated "— · —".
    private func addToTrips(_ info: PNRInfo) {
        let pnr = groupPNR(info.pnr)
        var berths: [String] = []
        var primary: Booking?
        for p in info.passengers {
            guard case .cnf(.some(let coach), .some(let berth), let type) = p.current else { continue }
            let seat = type.map { "\(berth) \($0.rawValue)" } ?? String(berth)
            berths.append("\(coach) · \(seat)")
            if primary == nil { primary = Booking(coach: coach, seat: seat, pnr: pnr) }
        }
        if let primary {
            store.add(info.train, runDate: info.runDate, booking: primary,
                      berths: berths.count > 1 ? berths : nil)
        } else {
            store.addPNROnly(info.train, runDate: info.runDate, pnr: pnr)
        }
        Analytics.shared.log(.tripAdded, ["source": "pnr", "train": info.train.number])
        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) { added = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { router.focus(info.tripId) }
    }
}
