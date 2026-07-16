import SwiftUI

/// PNR status check — the front door of Indian rail travel. A 10-digit
/// number in, the whole booking out: per-passenger WL→RAC→CNF ladder,
/// chart state, journey summary, coach position, and a one-tap import
/// into My Trips (Flighty's "add by confirmation code", for rails).

private func tone(_ s: SeatStatus) -> Color {
    switch s {
    case .cnf, .noSeat: return .onTime
    case .rac: return Color(hex: 0xB58900)
    case .waitlist: return .lateRed
    case .notConfirmed: return .lateRed
    }
}

/// Typed navigation tokens — PNR pushes and trip pushes must be distinct
/// types or the stack-root destination swallows both.
struct PNRRoute: Hashable { let pnr: String }
struct TripRoute: Hashable { let token: String }

struct PNRView: View {
    @State private var digits = ""
    // NavigationPath, not [PNRRoute]: the result screen pushes TripRoute and
    // AvailRoute values too, and a typed path silently swallows other types.
    @State private var path = NavigationPath()
    @FocusState private var focused: Bool
    @AppStorage("railly.recentPNRs") private var recentCSV = ""

    /// "852-4136972" — the conventional 3-7 split.
    private var grouped: String { groupPNR(digits) }

    private struct Recent: Identifiable {
        let pnr: String
        let trainNumber: String
        let runDate: String
        var id: String { pnr }
    }

    private var recents: [Recent] {
        recentCSV.split(separator: ",").compactMap { entry in
            let p = entry.split(separator: ":").map(String.init)
            guard p.count == 3 else { return nil }
            // a malformed stored date would trap istDateTime in the row
            let date = p[2].split(separator: "-").compactMap { Int($0) }
            guard date.count == 3 else { return nil }
            return Recent(pnr: p[0], trainNumber: p[1], runDate: p[2])
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    entryField
                        .padding(.top, 18)
                    checkButton
                        .padding(.top, 12)

                    if !recents.isEmpty {
                        eyebrow("RECENTLY CHECKED")
                        ForEach(recents) { r in
                            recentRow(r)
                        }
                    }

                    howItWorks
                        .padding(.top, 26)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
                .readableColumn()
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background(Color.white)
            .navigationDestination(for: PNRRoute.self) { route in
                PNRResultView(pnr: route.pnr)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("PNR Status")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Color.inkline)
            Text("Confirmed, RAC, or waitlisted — know where your ticket stands.")
                .font(.system(size: 14))
                .foregroundStyle(Color.subGray)
        }
    }

    private var entryField: some View {
        HStack(spacing: 9) {
            Image(systemName: "ticket")
                .foregroundStyle(Color.fadedGray)
            TextField("10-digit PNR number", text: Binding(
                get: { grouped },
                set: { digits = String($0.filter(\.isNumber).prefix(10)) }
            ))
            .font(.system(size: 22, weight: .semibold))
            .monospacedDigit()
            .focused($focused)
            .kerning(1.5)
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
            if !digits.isEmpty {
                Button {
                    digits = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.fadedGray)
                }
                .buttonStyle(.plain)
            } else {
                pasteButton
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 60)
        .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 16))
    }

    private var pasteButton: some View {
        Button {
            #if os(iOS)
            if let s = UIPasteboard.general.string {
                let nums = s.filter(\.isNumber)
                if nums.count >= 10 { digits = String(nums.prefix(10)) }
            }
            #endif
        } label: {
            Text("PASTE")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: 0x1D6FF2))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: 0xE7F0FF), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var checkButton: some View {
        Button {
            guard digits.count == 10 else { return }
            focused = false
            path.append(PNRRoute(pnr: digits))
        } label: {
            Text("Check Status")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(digits.count == 10 ? Color.arcBlue : Color.fadedGray)
                )
        }
        .buttonStyle(.plain)
        .disabled(digits.count != 10)
    }

    private func eyebrow(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .bold))
            .kerning(0.8)
            .foregroundStyle(Color.fadedGray)
            .padding(.top, 26)
            .padding(.bottom, 4)
    }

    private func recentRow(_ r: Recent) -> some View {
        let train = Catalog.trains.first { $0.number == r.trainNumber }
        return Button {
            path.append(PNRRoute(pnr: r.pnr))
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.subGray)
                    .frame(width: 34, height: 34)
                    .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 1) {
                    Text(groupPNR(r.pnr))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.inkline)
                        .monospacedDigit()
                    Text("\(train?.displayName ?? r.trainNumber) · \(fmtDay(istDateTime(r.runDate, minutes: 12 * 60)))")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subGray)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.fadedGray)
            }
            .padding(.vertical, 9)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.pressableRow)
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach([
                ("checkmark.seal", "CNF — a berth is yours", "Coach and berth show once the chart is prepared."),
                ("person.2", "RAC — you board, sharing a side lower", "Half a berth now; a full one if someone cancels."),
                ("hourglass", "WL — waitlisted, watch it climb", "GNWL clears best. Railly tracks it to charting."),
            ], id: \.0) { icon, title, sub in
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.arcBlue)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.inkline)
                        Text(sub)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.subGray)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.fillGray.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// PNRs print with the conventional 3-7 split: "852-4136972".
func groupPNR(_ pnr: String) -> String {
    guard pnr.count > 3 else { return pnr }
    return pnr.prefix(3) + "-" + pnr.dropFirst(3)
}

// MARK: - Result

struct PNRResultView: View {
    let pnr: String
    /// Set when the result screen lives inside the Add-Trip sheet: importing
    /// then dismisses the whole flow, the way TrainAddView does.
    var dismissAll: (() -> Void)? = nil
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @Environment(\.dismiss) private var dismiss
    @AppStorage("railly.recentPNRs") private var recentCSV = ""
    @State private var outcome: PNROutcome?
    @State private var justAdded = false

    var body: some View {
        Group {
            switch outcome {
            case .none:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Checking with the railway…")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.subGray)
                }
            case .found(let info):
                loaded(info)
            case .notFound(let reason):
                VStack(spacing: 14) {
                    Image(systemName: "questionmark.folder")
                        .font(.system(size: 30))
                        .foregroundStyle(Color.fadedGray)
                    Text("No booking found")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.inkline)
                    Text("\(reason).\nCheck the 10 digits — flushed or very old PNRs stop resolving.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.subGray)
                        .multilineTextAlignment(.center)
                    Button("Check another PNR") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.arcBlue)
                        .padding(.top, 4)
                }
                .padding(30)
            case .offline:
                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 30))
                        .foregroundStyle(Color.fadedGray)
                    Text("Couldn't fetch the live booking data.\nCheck your connection and try again.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.subGray)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task { await load() }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.arcBlue)
                }
                .padding(30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .navigationTitle(groupPNR(pnr))
        .navigationBarTitleDisplayMode(.inline)
        // registered here, outside the ScrollView: destinations declared deep
        // in scroll content don't reliably register with the stack
        .navigationDestination(for: TripRoute.self) { route in
            ResolveDetailView(token: route.token)
        }
        // .task re-fires on every reappearance (e.g. popping back from Track
        // This Train) — don't wipe a result we already have
        .task { if outcome == nil { await load() } }
    }

    private func load() async {
        outcome = nil
        let result = await PNRService.lookup(pnr, now: Date())
        // a cancelled fetch (tab switch mid-flight) must not persist a bogus
        // "offline" verdict for the next appearance
        guard !Task.isCancelled else { return }
        if case .found(let info) = result { remember(info) }
        outcome = result
    }

    private func remember(_ info: PNRInfo) {
        var list = recentCSV.split(separator: ",").map(String.init)
        list.removeAll { $0.hasPrefix("\(info.pnr):") }
        list.insert("\(info.pnr):\(info.train.number):\(info.runDate)", at: 0)
        recentCSV = list.prefix(5).joined(separator: ",")
        // this PNR is now watched — claim notification permission (first time)
        // and queue a background re-check window
        PNRWatch.beginWatching()
        Analytics.shared.log(.pnrWatched, ["train": info.train.number])
    }

    // MARK: pieces

    private func loaded(_ info: PNRInfo) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                statusBanner(info)
                journeyCard(info)
                if let note = info.routeNote {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.gateAmber)
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.subGray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(hex: 0xFBF6E8), in: RoundedRectangle(cornerRadius: 12))
                }
                passengers(info)
                ticketFacts(info)
                if confirmedCoach(info) != nil || info.realRake != nil {
                    CoachPositionCard(train: info.train,
                                      highlight: confirmedCoach(info),
                                      rakeOverride: info.realRake)
                }
                actions(info)
                Text(sourceNote(info.source))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fadedGray)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 44)
            .readableColumn()
        }
        .scrollIndicators(.hidden)
        .overlay {
            if justAdded {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 74, height: 74)
                        .background(Color.onTime, in: Circle())
                    Text("Added to My Trips")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.inkline)
                }
                .padding(28)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        // condition form: fire on the rise only, not when the overlay
        // auto-dismisses a second later
        .sensoryFeedback(trigger: justAdded) { _, isShowing in
            isShowing ? .success : nil
        }
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
            return "Demo PNR — deterministic simulation of PRS rules.\nReal PNRs resolve live in normal launches."
        }
    }

    /// The party's worst current status decides the banner — one look tells
    /// the traveller whether they're boarding.
    private func statusBanner(_ info: PNRInfo) -> some View {
        let worst = info.passengers.map(\.current).min { rank($0) < rank($1) }
            ?? .notConfirmed
        let color = tone(worst)
        let bg = worst.isConfirmed ? Color(hex: 0xF2F8F4)
            : isRAC(worst) ? Color(hex: 0xFBF6E8) : Color(hex: 0xFBF0EE)

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Text(headline(worst, info: info))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)
                Spacer()
                Text(info.jClass.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.inkline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white, in: RoundedRectangle(cornerRadius: 7))
            }
            Text(info.chartPrepared
                ? "Chart prepared — statuses are final"
                : "Chart expected around \(fmtTime(chartTime(departure: info.departure)))")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: 0x374151))

            if case .waitlist(let kind, let pos) = worst, !info.chartPrepared {
                confidenceLine(info, kind: kind, position: pos)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(bg, in: RoundedRectangle(cornerRadius: 16))
    }

    /// Railly's waitlist-confirmation model for the banner — sits alongside
    /// ConfirmTkt's live prediction when the feed sent one, each labelled to
    /// its source.
    @ViewBuilder
    private func confidenceLine(_ info: PNRInfo, kind: WLKind, position: Int) -> some View {
        let c = Reservation.wlConfidence(
            info.train, info.jClass, kind: kind, position: max(1, position),
            daysToGo: info.departure.timeIntervalSince(Date()) / 86_400)
        let ctPrediction = info.passengers.compactMap(\.prediction).first
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 11, weight: .semibold))
                Text("\(c.percent)% confirm chance")
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                Text("· Railly model")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.subGray)
            }
            .foregroundStyle(confidenceTone(c.percent))
            Text(c.rationale)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0x374151))
            if let ctPrediction {
                Text("ConfirmTkt: \(ctPrediction)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xB58900))
            }
        }
        .padding(.top, 5)
    }

    private func confidenceTone(_ pct: Int) -> Color {
        pct >= 68 ? .onTime : pct >= 32 ? Color(hex: 0xB58900) : .lateRed
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

    private func headline(_ worst: SeatStatus, info: PNRInfo) -> String {
        switch worst {
        case .cnf: return info.passengers.count == 1
            ? "Confirmed" : "All \(info.passengers.count) confirmed"
        case .noSeat: return "Confirmed — child without berth"
        case .rac(let n, _, _):
            return n > 0 ? "RAC \(n) — you can board" : "RAC — you can board"
        case .waitlist(let kind, let n):
            return n > 0 ? "\(kind.rawValue) \(n) — waitlisted"
                         : "\(kind.rawValue) — waitlisted"
        case .notConfirmed: return "Not confirmed"
        }
    }

    private func journeyCard(_ info: PNRInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                TrainMark(category: info.train.category, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(info.train.number) • \(fmtDay(info.departure).uppercased())")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(0.5)
                        .foregroundStyle(Color.subGray)
                    Text(info.train.displayName)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Color.inkline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(fmtTime(info.departure))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Color.inkline)
                        .monospacedDigit()
                    Text("\(info.from.code) · \(cityFor(info.from.code, info.from.name))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.subGray)
                        .lineLimit(1)
                }
                VStack(spacing: 3) {
                    Text(fmtDuration(Double(info.to.arrMin - info.from.depMin)))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.fadedGray)
                    Rectangle().fill(Color.hairline).frame(height: 1)
                    Text(info.quota.label + " quota")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fadedGray)
                }
                .frame(maxWidth: .infinity)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(fmtTime(info.arrival))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Color.inkline)
                        .monospacedDigit()
                    Text("\(info.to.code) · \(cityFor(info.to.code, info.to.name))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.subGray)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func passengers(_ info: PNRInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Passengers")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Color.inkline)
            ForEach(info.passengers) { p in
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Passenger \(p.number)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.inkline)
                        Text("Booked \(p.booking.text)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.fadedGray)
                            .monospacedDigit()
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(p.current.text)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(tone(p.current))
                            .monospacedDigit()
                        if case .cnf(_, _, .some(let type)) = p.current {
                            Text(type.label + (info.jClass.isBerthed ? " berth" : " seat"))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.subGray)
                        } else if let prediction = p.prediction {
                            // ConfirmTkt's live confirmation odds
                            Text(prediction)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: 0xB58900))
                        }
                    }
                }
                .padding(.vertical, 4)
                .overlay(alignment: .bottom) {
                    if p.number < info.passengers.count {
                        Rectangle().fill(Color.hairline).frame(height: 1)
                            .offset(y: 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .stroke(Color(hex: 0xECECEE), lineWidth: 1)
        )
    }

    private func ticketFacts(_ info: PNRInfo) -> some View {
        HStack(spacing: 0) {
            fact(info.jClass.label, "Class")
            divider
            fact(info.quota.label, "Quota")
            divider
            fact("₹\(info.fare)", info.fareExact ? "Fare" : "Fare est.")
            divider
            fact(info.issuedBy.replacingOccurrences(of: "PRS ", with: ""), "Issued by")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .stroke(Color(hex: 0xECECEE), lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle().fill(Color.hairline).frame(width: 1, height: 30)
    }

    private func fact(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.subGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }

    private func confirmedCoach(_ info: PNRInfo) -> String? {
        for p in info.passengers {
            if case .cnf(.some(let coach), _, _) = p.current { return coach }
        }
        return nil
    }

    private func actions(_ info: PNRInfo) -> some View {
        let held = store.isHeld(info.tripId)
        return VStack(spacing: 10) {
            NavigationLink(value: TripRoute(token: info.tripId)) {
                HStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    Text("Track This Train")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.arcBlue))
            }
            .buttonStyle(.plain)

            Button {
                guard !held else { return }
                addToTrips(info)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: held ? "checkmark.circle" : "plus.circle")
                    Text(held ? "In My Trips" : "Add to My Trips")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(held ? Color.subGray : Color.arcBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: 0xEAF3FF).opacity(held ? 0 : 1))
                        .stroke(held ? Color.hairline : .clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(held)
        }
    }

    /// Import the booking: the trip lands in My Trips with the real PNR and
    /// (when confirmed) the whole party's coach/berths on the ticket card. An
    /// unassigned ticket carries the PNR alone — no fabricated "— · —".
    private func addToTrips(_ info: PNRInfo) {
        let pnr = groupPNR(info.pnr)
        // every confirmed passenger's coach·berth, so the ticket keeps the
        // whole party and the coach strip can light all the berths
        var berths: [String] = []
        var primary: Booking?
        for p in info.passengers {
            guard case .cnf(.some(let coach), .some(let berth), let type) = p.current
            else { continue }
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
        withAnimation(.spring(duration: 0.35)) { justAdded = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let dismissAll {
                dismissAll()
            } else {
                withAnimation { justAdded = false }
            }
        }
    }
}
