import SwiftUI

/// Search & add. One field reads what you type (a PNR, a train, a station)
/// and a row of chips grows as you narrow down: station → station → train →
/// date. It ends on a summary card and one tap to add, the way Flighty's Add
/// Flight walks CGK → ICN → Wed 26 Nov.

private enum AddDestination: Hashable {
    case pnr(String)
    case availability(String)
}

struct AddTripView: View {
    let prefill: String?
    let pnrMode: Bool
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss

    /// `pnrMode` opens straight into PNR entry (number pad, PNR hints).
    init(prefill: String?, pnrMode: Bool = false) {
        self.prefill = prefill
        self.pnrMode = pnrMode
    }

    var body: some View {
        NavigationStack {
            AddFlow(prefill: prefill, startInPNR: pnrMode,
                    close: { dismiss() },
                    focusTrip: { router.focus($0) })
                .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationCornerRadius(DS.sheetRadius)
        .presentationBackground(DS.sheet)
    }
}

// MARK: - Flow

private struct PickedTrain: Equatable {
    let number: String
    let name: String
    let category: TrainCategory
    /// Boarding and alighting codes when the train came from a route search.
    var from: String? = nil
    var to: String? = nil
}

private struct RecentPNR: Identifiable {
    let pnr: String
    let train: String
    let runDate: String
    var id: String { pnr }
}

private let glyphFont = Font.system(size: 20, weight: .medium)
private let fieldHeight: CGFloat = 50
private let weekOrder: [Day] = [.mon, .tue, .wed, .thu, .fri, .sat, .sun]

private struct AddFlow: View {
    let prefill: String?
    let startInPNR: Bool
    let close: () -> Void
    let focusTrip: (String) -> Void

    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @AppStorage("railly.recentTrains") private var recentTrainsCSV = ""
    @AppStorage(PNRWatch.recentKey) private var recentPNRsCSV = ""

    private enum Mode { case any, pnr, stations }
    private enum Step { case search, route, date, confirm }

    private struct Token: Identifiable {
        let id: String
        let text: String
        let action: () -> Void
    }

    @State private var didSetup = false
    @State private var query = ""
    @State private var mode: Mode = .any
    @State private var stations: [CatalogStation] = []
    @State private var routeResults: [TrainSummary]?
    @State private var routeError: String?
    @State private var routeRetry = 0
    @State private var picked: PickedTrain?
    @State private var train: Train?
    @State private var trainError: String?
    @State private var trainRetry = 0
    /// The date the traveller boards, which differs from the train's run date
    /// when they join a day into the journey.
    @State private var boardingDate: String?
    @State private var showCalendar = false
    @State private var calendarPick = Date()
    @State private var calendarNote: String?
    @State private var ticketPNR = ""
    @State private var ticketCoach = ""
    @State private var ticketBerth = ""
    @State private var fillingFromPNR = false
    @State private var fillNote: String?
    @State private var added = false
    @State private var pushed: AddDestination?
    @FocusState private var searchFocused: Bool

    private var step: Step {
        if picked != nil { return boardingDate == nil ? .date : .confirm }
        return stations.count == 2 ? .route : .search
    }

    private var stationOnly: Bool { mode == .stations || stations.count == 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            tokenBar
            ScrollView {
                content
                    .padding(.horizontal, DS.gutter)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
        .background(DS.sheet)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if step == .confirm, let train, let d = boardingDate {
                confirmBar(train, d)
            }
        }
        .overlay {
            if added { AddedHUD() }
        }
        .sensoryFeedback(trigger: added) { _, isShowing in isShowing ? .success : nil }
        .sensoryFeedback(.selection, trigger: boardingDate)
        .navigationDestination(item: $pushed) { destination in
            switch destination {
            case .pnr(let pnr): PNRResultView(pnr: pnr)
            case .availability(let number): AvailabilityView(number: number)
            }
        }
        .onAppear(perform: setup)
        .task(id: "\(picked?.number ?? "")#\(trainRetry)") { await resolvePicked() }
        .task(id: routeKey) { await searchRoute() }
        .onChange(of: calendarPick) { _, date in pickFromCalendar(date) }
    }

    // MARK: Header & chips

    private var subtitle: String {
        switch step {
        case .search:
            if stations.count == 1 { return "Enter the destination station" }
            switch mode {
            case .pnr: return "Enter the 10-digit PNR"
            case .stations: return "Enter the departure station"
            case .any: return "Enter a train, route, or PNR"
            }
        case .route: return "Tap which train to add"
        case .date: return "Choose your travel date"
        case .confirm: return "Check the details and add"
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Trip")
                    .font(.dsLargeTitle)
                    .foregroundStyle(DS.ink)
                Text(subtitle)
                    .font(.dsBody)
                    .foregroundStyle(DS.secondary)
                    .contentTransition(.opacity)
                    .animation(.snappy(duration: 0.25), value: subtitle)
            }
            Spacer(minLength: 0)
            DSCircleButton(systemImage: "xmark", label: "Close", action: close)
        }
        .padding(.horizontal, DS.gutter)
        .padding(.top, 22)
    }

    private var tokens: [Token] {
        if let picked {
            var out = [Token(id: "train", text: picked.number) { backToTrain() }]
            if let d = boardingDate {
                out.append(Token(id: "date", text: prettyDay(d)) {
                    withAnimation(.snappy(duration: 0.3)) { boardingDate = nil }
                })
            }
            return out
        }
        return stations.enumerated().map { i, s in
            Token(id: "station-\(i)-\(s.c)", text: s.c) { backToStation(i) }
        }
    }

    private var tokenBar: some View {
        HStack(spacing: 8) {
            ForEach(tokens) { token in
                Button(action: token.action) {
                    Text(token.text)
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                        .monospacedDigit()
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                        .frame(height: fieldHeight)
                        .dsWell()
                }
                .buttonStyle(DSPressStyle())
                .accessibilityHint("Double-tap to change")
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
            trailingSlot
        }
        .padding(.horizontal, DS.gutter)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .animation(.snappy(duration: 0.3), value: tokens.map(\.id))
    }

    @ViewBuilder
    private var trailingSlot: some View {
        switch step {
        case .search:
            searchField
        case .route:
            Button(action: swapStations) {
                Label("Swap", systemImage: "arrow.left.arrow.right")
                    .font(.dsSubhead)
                    .foregroundStyle(DS.action)
                    .padding(.horizontal, 14)
                    .frame(height: fieldHeight)
                    .dsWell()
            }
            .buttonStyle(DSPressStyle())
            Spacer(minLength: 0)
        case .date:
            Button {
                withAnimation(.snappy(duration: 0.3)) { showCalendar.toggle() }
            } label: {
                HStack {
                    Text("Travel date").foregroundStyle(DS.tertiary)
                    Spacer(minLength: 4)
                    Image(systemName: "calendar").foregroundStyle(DS.secondary)
                }
                .font(.dsBody)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: fieldHeight)
                .dsWell()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pick from calendar")
        case .confirm:
            Spacer(minLength: 0)
        }
    }

    private var placeholder: String {
        if stations.count == 1 { return "To station" }
        switch mode {
        case .pnr: return "10-digit PNR"
        case .stations: return "From station"
        case .any: return "Train, station or PNR"
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            if tokens.isEmpty {
                Image(systemName: mode == .pnr ? "ticket" : "magnifyingglass")
                    .foregroundStyle(DS.tertiary)
            }
            TextField(placeholder, text: $query)
                .font(.dsBody)
                .foregroundStyle(DS.ink)
                .focused($searchFocused)
                .searchFieldStyle()
                #if os(iOS)
                .keyboardType(mode == .pnr ? .numberPad : .default)
                #endif
                .onSubmit(submitTop)
            if !query.isEmpty || mode != .any {
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(DS.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear")
            } else if tokens.isEmpty {
                PasteButton(payloadType: String.self) { strings in
                    guard let text = strings.first else { return }
                    Task { @MainActor in
                        query = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                .labelStyle(.iconOnly)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .tint(DS.action)
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: fieldHeight)
        .dsWell()
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch step {
        case .search: searchContent
        case .route: routeContent
        case .date: dateContent
        case .confirm: confirmContent
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        let q = query.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            results(q)
        } else if stationOnly {
            hint(stations.first.map { "From \($0.n) (\($0.c)). Now type where you're going." }
                ?? "Type a station name or code, like Mumbai or NDLS.")
        } else if mode == .pnr {
            VStack(alignment: .leading, spacing: 0) {
                hint("The 10 digits at the top-left of your ticket or in the IRCTC SMS.")
                recentPNRSection
            }
        } else {
            suggestions
        }
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.dsFootnote)
            .foregroundStyle(DS.secondary)
            .padding(.top, 8)
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { setMode(.pnr) } label: {
                FlowRow(title: "Check PNR status", subtitle: "Booking, berth and chart status") {
                    glyph("ticket")
                }
            }
            .buttonStyle(.pressableRow)
            Button { setMode(.stations) } label: {
                FlowRow(title: "Find trains between stations", subtitle: "Every train on a route") {
                    glyph("point.topleft.down.to.point.bottomright.curvepath")
                }
            }
            .buttonStyle(.pressableRow)

            recentPNRSection

            if !recentTrains.isEmpty {
                sectionLabel("Recently viewed")
                ForEach(recentTrains) { trainRow($0) }
            }
            if !popularTrains.isEmpty {
                sectionLabel("Popular trains")
                ForEach(popularTrains) { trainRow($0) }
            }

            sectionLabel("More")
            Button {
                if let t = Catalog.trains.randomElement() { query = t.number }
            } label: {
                FlowRow(title: "Surprise me", subtitle: "A random train from the whole network") {
                    glyph("dice")
                }
            }
            .buttonStyle(.pressableRow)
        }
    }

    @ViewBuilder
    private var recentPNRSection: some View {
        let recents = recentPNRs
        if !recents.isEmpty {
            sectionLabel("Recently checked")
            ForEach(recents) { r in
                Button { open(.pnr(r.pnr)) } label: {
                    FlowRow(title: groupPNR(r.pnr),
                            subtitle: "\(trainName(r.train)) · \(prettyDay(r.runDate))") {
                        glyph("clock.arrow.circlepath", tint: DS.secondary)
                    }
                }
                .buttonStyle(.pressableRow)
            }
        }
    }

    @ViewBuilder
    private func results(_ q: String) -> some View {
        let digits = q.filter(\.isNumber)
        let numeric = q.allSatisfy { $0.isNumber || $0 == " " || $0 == "-" }
        let showPNR = !stationOnly && numeric && digits.count == 10
        let showProgress = !stationOnly && numeric && digits.count < 10
            && (mode == .pnr || digits.count > 5)
        let stationHits = numeric || q.count < 2 ? []
            : Catalog.searchStations(q, limit: stationOnly ? 12 : 4)
                .filter { hit in !stations.contains { $0.c == hit.c } }
        let trainHits = stationOnly || mode == .pnr || digits.count >= 10 ? []
            : Catalog.searchTrains(q)

        VStack(alignment: .leading, spacing: 0) {
            if showPNR {
                Button { open(.pnr(digits)) } label: {
                    FlowRow(title: "Check PNR \(groupPNR(digits))", subtitle: "Live booking and chart status") {
                        glyph("ticket")
                    } trailing: {
                        Image(systemName: "arrow.right")
                            .font(.dsSubhead)
                            .foregroundStyle(DS.secondary)
                            .frame(width: 44, height: 28)
                            .overlay(Capsule().stroke(DS.separator, lineWidth: 1.5))
                    }
                }
                .buttonStyle(.pressableRow)
            } else if showProgress {
                FlowRow(title: "PNR · \(digits.count) of 10 digits",
                        subtitle: "Keep typing to check a booking", dimmed: true) {
                    glyph("ticket", tint: DS.tertiary)
                }
            }
            if !stationHits.isEmpty {
                sectionLabel("Stations")
                ForEach(stationHits) { stationRow($0) }
            }
            if !trainHits.isEmpty {
                sectionLabel(trainHits.count >= 30 ? "30+ trains" : trainHits.count == 1 ? "1 train" : "\(trainHits.count) trains")
                ForEach(trainHits) { trainRow($0) }
            }
            if !showPNR && !showProgress && stationHits.isEmpty && trainHits.isEmpty {
                VStack(spacing: 6) {
                    Text("Nothing matches “\(q)”")
                        .font(.dsCallout)
                        .foregroundStyle(DS.secondary)
                    Text(stationOnly
                        ? "Try a station name or its code, like NDLS."
                        : "Try a 5-digit train number, a station code like NDLS, or a 10-digit PNR.")
                        .font(.dsFootnote)
                        .foregroundStyle(DS.tertiary)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 36)
            }
        }
    }

    private func trainRow(_ t: CatalogTrain) -> some View {
        let subtitle = bank.cached(t.number).map {
            "\(t.number) · \($0.origin.code) → \($0.destination.code) · \(runDaysText($0.days))"
        } ?? t.number
        return Button {
            pick(PickedTrain(number: t.number, name: t.displayName, category: t.category))
        } label: {
            FlowRow(title: t.displayName, subtitle: subtitle) {
                TrainMark(category: t.category, size: 36)
            }
        }
        .buttonStyle(.pressableRow)
    }

    private func stationRow(_ s: CatalogStation) -> some View {
        Button { pickStation(s) } label: {
            FlowRow(title: s.n, subtitle: "\(s.c) · \(cityFor(s.c, s.n))") {
                glyph("mappin.and.ellipse")
            }
        }
        .buttonStyle(.pressableRow)
    }

    private func sectionLabel(_ s: String) -> some View {
        Text(s)
            .eyebrow()
            .padding(.top, 20)
            .padding(.bottom, 4)
    }

    private func glyph(_ name: String, tint: Color = DS.ink) -> some View {
        Image(systemName: name)
            .font(glyphFont)
            .foregroundStyle(tint)
    }

    // MARK: Route

    private var routeKey: String {
        stations.count == 2 ? "\(stations[0].c)>\(stations[1].c)#\(routeRetry)" : ""
    }

    @ViewBuilder
    private var routeContent: some View {
        if stations.count == 2 {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(cityFor(stations[0].c, stations[0].n)) to \(cityFor(stations[1].c, stations[1].n))")
                    .font(.dsSection)
                    .foregroundStyle(DS.ink)
                    .padding(.top, 8)
                if let routeError {
                    FlowError(message: routeError) { routeRetry += 1 }
                } else if let routeResults {
                    Text(routeResults.count == 1 ? "1 train" : "\(routeResults.count) trains")
                        .eyebrow()
                        .padding(.top, 14)
                        .padding(.bottom, 2)
                    ForEach(routeResults) { routeRow($0) }
                } else {
                    VStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { _ in SkeletonRow() }
                    }
                    .padding(.top, 10)
                    .skeletonPulse()
                }
            }
        }
    }

    private func routeRow(_ r: TrainSummary) -> some View {
        let duration = durationParts(r.travelTime)
        return Button {
            pick(PickedTrain(number: r.number, name: r.displayName, category: r.category,
                             from: r.fromCode, to: r.toCode))
        } label: {
            HStack(spacing: 14) {
                VStack(spacing: 1) {
                    Text(duration.value)
                        .font(.dsCountdown)
                        .foregroundStyle(DS.ink)
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                    Text(duration.unit).eyebrow()
                }
                .frame(width: 64)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        TrainMark(category: r.category, size: 18)
                        Text(r.number)
                            .font(.dsFootnote)
                            .foregroundStyle(DS.secondary)
                            .monospacedDigit()
                        Spacer(minLength: 4)
                        Text(runDaysLabel(r.days))
                            .font(.dsCaption)
                            .foregroundStyle(DS.secondary)
                    }
                    Text(r.displayName)
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                    HStack(spacing: 14) {
                        routeEndpoint(departing: true, code: r.fromCode, time: r.departure)
                        routeEndpoint(departing: false, code: r.toCode, time: r.arrival)
                    }
                }
            }
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) {
                Rectangle().fill(DS.separator).frame(height: 1).padding(.leading, 78)
            }
        }
        .buttonStyle(.pressableRow)
    }

    private func routeEndpoint(departing: Bool, code: String, time: String) -> some View {
        HStack(spacing: 5) {
            EndpointGlyph(departing: departing, tone: .scheduled, size: 16)
            Text("\(code) \(hmText(time))")
                .font(.dsSubhead)
                .foregroundStyle(DS.ink2)
                .monospacedDigit()
        }
    }

    // MARK: Date

    @ViewBuilder
    private var trainCard: some View {
        if let train {
            journeyCard(train, boarding: boardingDate)
        } else if let trainError {
            FlowError(message: trainError) { trainRetry += 1 }
        } else {
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.fill)
                .frame(height: 176)
                .skeletonPulse()
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var dateContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            trainCard
            if let train { dateRows(train) }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func dateRows(_ train: Train) -> some View {
        let today = istDateISO(Date())
        let jc = JClass.defaultPick(JClass.reservable(from: train.classes))
        let upcoming = runs(train, offsets: Array(2...Reservation.arpDays), limit: 4)
        let past = runs(train, offsets: Array(stride(from: -1, through: -10, by: -1)), limit: 2)

        VStack(alignment: .leading, spacing: 0) {
            if let jc {
                HStack(spacing: 6) {
                    Spacer()
                    Text("Seats in \(jc.rawValue), general quota")
                        .font(.dsCaption)
                        .foregroundStyle(DS.secondary)
                    EstimateTag()
                }
                .padding(.top, 16)
            }
            dateRow(train, today, title: "Today", icon: "calendar.badge.checkmark", jc: jc)
            dateRow(train, addDaysISO(today, 1), title: "Tomorrow", icon: "calendar.badge.plus", jc: jc)
            Button {
                withAnimation(.snappy(duration: 0.3)) { showCalendar.toggle() }
            } label: {
                FlowRow(title: "Pick from Calendar") {
                    glyph("calendar")
                } trailing: {
                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                        .font(.dsSubhead)
                        .foregroundStyle(DS.tertiary)
                }
            }
            .buttonStyle(.pressableRow)
            if showCalendar {
                calendarPicker(train)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if !upcoming.isEmpty {
                sectionLabel("Next runs")
                ForEach(upcoming, id: \.self) { d in
                    dateRow(train, d, title: prettyDay(d), subtitle: relativeDays(d),
                            icon: "calendar", jc: jc)
                }
            }
            if !past.isEmpty {
                sectionLabel("Past trips")
                ForEach(past, id: \.self) { d in
                    dateRow(train, d, title: prettyDay(d), subtitle: relativeDays(d),
                            icon: "clock.arrow.circlepath", jc: nil)
                }
            }
        }
    }

    private func dateRow(_ train: Train, _ d: String, title: String, subtitle: String? = nil,
                         icon: String, jc: JClass?) -> some View {
        let running = runsOn(train, boarding: d)
        let rd = runDate(forBoarding: d, train)
        let held = store.isHeld(tripId(train.number, rd))
        let sub = subtitle ?? prettyDay(d)
        return Button { choose(d) } label: {
            FlowRow(title: title, subtitle: running ? sub : "\(sub) · no service", dimmed: !running) {
                glyph(icon, tint: running ? DS.ink : DS.tertiary)
            } trailing: {
                if held {
                    DSChip(text: "ADDED", color: DS.onTimeText)
                } else if running, let jc {
                    availabilityChip(train, jc, rd)
                }
            }
        }
        .buttonStyle(.pressableRow)
        .disabled(!running)
    }

    @ViewBuilder
    private func availabilityChip(_ train: Train, _ jc: JClass, _ runDate: String) -> some View {
        let status = Reservation.availability(train, jc, .general, runDate, now: Date())
        switch status {
        case .available, .rac, .waitlist, .regret:
            DSChip(text: status.chip, color: availTone(status))
        default:
            EmptyView()
        }
    }

    private func calendarPicker(_ train: Train) -> some View {
        let now = Date()
        let range = now.addingTimeInterval(-30 * 86_400)...now.addingTimeInterval(Double(Reservation.arpDays) * 86_400)
        return VStack(alignment: .leading, spacing: 6) {
            DatePicker("Travel date", selection: $calendarPick, in: range, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(DS.action)
                .environment(\.timeZone, TimeZone(identifier: "Asia/Kolkata")!)
            Text(calendarNote ?? "Runs \(runDaysText(boardingDays(train))) from \(train.stops[boardIdx(train)].code).")
                .font(.dsFootnote)
                .foregroundStyle(calendarNote == nil ? DS.secondary : DS.lateText)
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .padding(8)
        .dsWell(radius: DS.cardRadius)
        .padding(.bottom, 8)
    }

    // MARK: Confirm

    @ViewBuilder
    private var confirmContent: some View {
        if let train, let d = boardingDate {
            let held = store.isHeld(tripId(train.number, runDate(forBoarding: d, train)))
            VStack(alignment: .leading, spacing: 22) {
                journeyCard(train, boarding: d)
                if held {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(DS.onTime)
                        Text("This run is already in My Trips")
                            .font(.dsSubhead)
                            .foregroundStyle(DS.ink)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DS.onTimeWash, in: RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous))
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        DSSectionHeader(title: "Your Ticket", subtitle: "Optional. You can add it later from the trip.")
                        TicketFields(pnrDigits: $ticketPNR, coach: $ticketCoach, berth: $ticketBerth)
                        if ticketPNR.count == 10 {
                            Button { Task { await fillFromPNR() } } label: {
                                Label(fillingFromPNR ? "Reading PNR…" : "Fill coach and berth from this PNR",
                                      systemImage: "arrow.down.circle")
                                    .font(.dsSubhead)
                                    .foregroundStyle(DS.action)
                            }
                            .buttonStyle(.plain)
                            .disabled(fillingFromPNR)
                            if let fillNote {
                                Text(fillNote).font(.dsFootnote).foregroundStyle(DS.secondary)
                            }
                        }
                    }
                }
                trainActions(train)
            }
            .padding(.top, 4)
        }
    }

    private func confirmBar(_ train: Train, _ d: String) -> some View {
        let id = tripId(train.number, runDate(forBoarding: d, train))
        let held = store.isHeld(id)
        let partialPNR = !ticketPNR.isEmpty && ticketPNR.count != 10
        return DSButton(title: held ? "View in My Trips" : "Add to My Trips",
                        systemImage: held ? "arrow.right" : "plus") {
            if held { focusTrip(id) } else { add(train, boarding: d) }
        }
        .disabled(partialPNR || added)
        .opacity(partialPNR ? 0.4 : 1)
        .padding(.horizontal, DS.gutter)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(DS.sheet)
    }

    private func trainActions(_ train: Train) -> some View {
        HStack(spacing: 8) {
            DSPill(title: "Live status", systemImage: "dot.radiowaves.left.and.right", filled: false) {
                focusTrip(liveTripFor(train, Date()).id)
            }
            if !JClass.reservable(from: train.classes).isEmpty {
                DSPill(title: "Seats & fares", systemImage: "chair.lounge", filled: false) {
                    open(.availability(train.number))
                }
            }
        }
    }

    /// The train, its times at the traveller's own boarding and alighting
    /// halts, and (before a date is chosen) its run days.
    private func journeyCard(_ train: Train, boarding: String?) -> some View {
        let b = boardIdx(train)
        let a = alightIdx(train)
        let rd = runDate(forBoarding: boarding ?? istDateISO(Date()), train)
        let base = parseHM(train.departureTime)
        let dep = istDateTime(rd, minutes: base + train.stops[b].depMin)
        let arr = istDateTime(rd, minutes: base + train.stops[a].arrMin)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                TrainMark(category: train.category, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(boarding.map { "\(train.number) · \(prettyDay($0))" }
                        ?? "\(train.number) · \(train.category.label)")
                        .font(.dsCaption)
                        .foregroundStyle(DS.secondary)
                    Text(train.displayName)
                        .font(.dsSection)
                        .foregroundStyle(DS.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            JourneyTimesRow(departure: dep, arrival: arr,
                            from: train.stops[b], to: train.stops[a],
                            detail: segmentDistance(train, b, a))
            if b != 0 || a != train.stops.count - 1 {
                Text("Runs \(train.origin.code) → \(train.destination.code) · you ride \(train.stops[b].code) → \(train.stops[a].code)")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
            }
            if boarding == nil {
                runDaysStrip(train)
                trainActions(train)
            }
        }
        .dsCard()
    }

    private func runDaysStrip(_ train: Train) -> some View {
        HStack(spacing: 6) {
            Text("Runs").eyebrow()
                .padding(.trailing, 4)
            ForEach(weekOrder, id: \.self) { d in
                let on = train.days.contains(d)
                Text(String(d.rawValue.prefix(1)))
                    .font(.dsCaption)
                    .foregroundStyle(on ? Color.white : DS.tertiary)
                    .frame(width: 24, height: 24)
                    .background(on ? DS.ink : DS.fill, in: Circle())
                    .accessibilityLabel("\(d.rawValue): \(on ? "runs" : "no service")")
            }
        }
    }

    // MARK: Actions

    private func setup() {
        guard !didSetup else { return }
        didSetup = true
        if startInPNR { mode = .pnr }
        query = prefill?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchFocused = true
    }

    /// Reads the PNR and copies the first passenger's allotted coach and berth.
    /// Unallotted tickets (WL, RAC without a berth) leave the fields alone and
    /// say why, rather than guessing.
    private func fillFromPNR() async {
        fillingFromPNR = true
        defer { fillingFromPNR = false }
        switch await PNRService.lookup(ticketPNR, now: Date()) {
        case .found(let info):
            guard let first = info.passengers.first else { fillNote = "No passengers on this PNR."; return }
            switch first.current {
            case .cnf(let coach?, let berth?, _), .rac(_, let coach?, let berth?):
                ticketCoach = coach
                ticketBerth = String(berth)
                fillNote = nil
            default:
                fillNote = "No berth allotted yet (\(first.current.text))."
            }
        case .notFound(let reason):
            fillNote = reason
        case .offline:
            fillNote = "Couldn't reach the PNR service."
        }
    }

    private func setMode(_ m: Mode) {
        mode = m
        // the keyboard type only changes on a fresh focus
        searchFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { searchFocused = true }
    }

    private func clearSearch() {
        if query.isEmpty {
            setMode(.any)
        } else {
            query = ""
        }
    }

    private func open(_ destination: AddDestination) {
        searchFocused = false
        pushed = destination
    }

    private func submitTop() {
        let q = query.trimmingCharacters(in: .whitespaces)
        let digits = q.filter(\.isNumber)
        if !stationOnly, digits.count == 10, q.allSatisfy({ $0.isNumber || $0 == " " || $0 == "-" }) {
            open(.pnr(digits))
        } else if stationOnly {
            if let s = Catalog.searchStations(q, limit: 4).first(where: { hit in !stations.contains { $0.c == hit.c } }) {
                pickStation(s)
            }
        } else if let t = Catalog.searchTrains(q, limit: 1).first {
            pick(PickedTrain(number: t.number, name: t.displayName, category: t.category))
        } else if let s = Catalog.searchStations(q, limit: 1).first {
            pickStation(s)
        }
    }

    private func pick(_ p: PickedTrain) {
        searchFocused = false
        withAnimation(.snappy(duration: 0.3)) {
            picked = p
            train = bank.cached(p.number)
            trainError = nil
            boardingDate = nil
            showCalendar = false
            calendarNote = nil
            query = ""
        }
        rememberTrain(p.number)
    }

    private func pickStation(_ s: CatalogStation) {
        withAnimation(.snappy(duration: 0.3)) {
            stations.append(s)
            query = ""
        }
        if stations.count == 2 {
            searchFocused = false
            mode = .any
        } else {
            searchFocused = true
        }
    }

    private func swapStations() {
        withAnimation(.snappy(duration: 0.3)) { stations.reverse() }
    }

    private func backToStation(_ index: Int) {
        withAnimation(.snappy(duration: 0.3)) {
            stations = Array(stations.prefix(index))
            query = ""
            routeResults = nil
        }
        searchFocused = true
    }

    private func backToTrain() {
        withAnimation(.snappy(duration: 0.3)) {
            picked = nil
            train = nil
            trainError = nil
            boardingDate = nil
            ticketPNR = ""
            ticketCoach = ""
            ticketBerth = ""
        }
        if stations.count < 2 { searchFocused = true }
    }

    private func choose(_ d: String) {
        searchFocused = false
        withAnimation(.snappy(duration: 0.3)) {
            boardingDate = d
            showCalendar = false
            calendarNote = nil
        }
    }

    private func pickFromCalendar(_ date: Date) {
        guard let train, picked != nil, boardingDate == nil else { return }
        let d = istDateISO(date)
        if runsOn(train, boarding: d) {
            choose(d)
        } else {
            calendarNote = "\(train.number) doesn't run on \(prettyDay(d)). Pick another day."
        }
    }

    private func add(_ train: Train, boarding d: String) {
        let rd = runDate(forBoarding: d, train)
        let id = tripId(train.number, rd)
        dismissKeyboard()
        store.add(train, runDate: rd)
        let coach = ticketCoach.trimmingCharacters(in: .whitespaces).uppercased()
        let berth = ticketBerth.trimmingCharacters(in: .whitespaces)
        let pnr = ticketPNR.count == 10 ? groupPNR(ticketPNR) : nil
        if !coach.isEmpty || !berth.isEmpty || pnr != nil {
            store.setBooking(id, coach: coach.isEmpty ? nil : coach,
                             seat: berth.isEmpty ? nil : berth, pnr: pnr)
        }
        Analytics.shared.log(.tripAdded, ["source": "search", "train": train.number])
        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) { added = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { focusTrip(id) }
    }

    private func resolvePicked() async {
        guard let number = picked?.number else { return }
        trainError = nil
        if train?.number != number { train = bank.cached(number) }
        do {
            let t = try await bank.resolve(number)
            guard picked?.number == number else { return }
            train = t
        } catch {
            guard picked?.number == number, train == nil, !Task.isCancelled else { return }
            trainError = railErrorText(error)
        }
    }

    private func searchRoute() async {
        routeResults = nil
        routeError = nil
        guard stations.count == 2 else { return }
        do {
            let rows = try await RailAPI.shared.trainsBetween(stations[0].c, stations[1].c)
            guard !Task.isCancelled else { return }
            routeResults = rows
        } catch {
            guard !Task.isCancelled else { return }
            routeError = railErrorText(error)
        }
    }

    private func rememberTrain(_ number: String) {
        var list = recentTrainsCSV.split(separator: ",").map(String.init)
        list.removeAll { $0 == number }
        list.insert(number, at: 0)
        recentTrainsCSV = list.prefix(5).joined(separator: ",")
    }

    private func dismissKeyboard() {
        searchFocused = false
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    // MARK: Data helpers

    private var recentTrains: [CatalogTrain] {
        recentTrainsCSV.split(separator: ",").compactMap { catalogTrain(String($0)) }
    }

    private var popularTrains: [CatalogTrain] {
        let recent = Set(recentTrainsCSV.split(separator: ",").map(String.init))
        return bank.seedNumbers.filter { !recent.contains($0) }.prefix(6).compactMap(catalogTrain)
    }

    private var recentPNRs: [RecentPNR] {
        recentPNRsCSV.split(separator: ",").compactMap { entry in
            let p = entry.split(separator: ":").map(String.init)
            guard p.count == 3 else { return nil }
            // a malformed stored date would trap istDateTime in the row
            guard p[2].split(separator: "-").compactMap({ Int($0) }).count == 3 else { return nil }
            return RecentPNR(pnr: p[0], train: p[1], runDate: p[2])
        }
    }

    private func catalogTrain(_ number: String) -> CatalogTrain? {
        if let t = bank.cached(number) { return CatalogTrain(number: t.number, rawName: t.name) }
        return Catalog.trains.first { $0.number == number }
    }

    private func trainName(_ number: String) -> String {
        catalogTrain(number)?.displayName ?? number
    }

    private func boardIdx(_ train: Train) -> Int {
        picked?.from.flatMap { code in train.stops.firstIndex { $0.code == code } } ?? 0
    }

    private func alightIdx(_ train: Train) -> Int {
        let b = boardIdx(train)
        let a = picked?.to.flatMap { code in train.stops.lastIndex { $0.code == code } }
        return max(b, a ?? train.stops.count - 1)
    }

    /// Days between the train leaving its origin and leaving the boarding halt.
    private func boardOffset(_ train: Train) -> Int {
        (parseHM(train.departureTime) + train.stops[boardIdx(train)].depMin) / (24 * 60)
    }

    private func runDate(forBoarding d: String, _ train: Train) -> String {
        addDaysISO(d, -boardOffset(train))
    }

    private func runsOn(_ train: Train, boarding d: String) -> Bool {
        train.days.contains(istWeekday(runDate(forBoarding: d, train)))
    }

    private func boardingDays(_ train: Train) -> [Day] {
        let shift = boardOffset(train)
        return weekOrder.filter { d in
            let i = weekOrder.firstIndex(of: d)!
            return train.days.contains(weekOrder[((i - shift) % 7 + 7) % 7])
        }
    }

    /// Boarding dates the train serves, walking `offsets` from today.
    private func runs(_ train: Train, offsets: [Int], limit: Int) -> [String] {
        let today = istDateISO(Date())
        var out: [String] = []
        for offset in offsets where out.count < limit {
            let d = addDaysISO(today, offset)
            if runsOn(train, boarding: d) { out.append(d) }
        }
        return out
    }

    private func segmentDistance(_ train: Train, _ b: Int, _ a: Int) -> String? {
        if b == 0 && a == train.stops.count - 1 {
            return "\(Int(train.distanceKm).formatted()) km"
        }
        guard let from = train.stops[b].distanceKm, let to = train.stops[a].distanceKm else { return nil }
        return "\(Int(to - from).formatted()) km"
    }
}

// MARK: - Formatting helpers

private func prettyDay(_ dateISO: String) -> String {
    fmtDay(istDateTime(dateISO, minutes: 12 * 60))
}

private func relativeDays(_ dateISO: String) -> String {
    let today = istDateTime(istDateISO(Date()), minutes: 12 * 60)
    let days = Int((istDateTime(dateISO, minutes: 12 * 60).timeIntervalSince(today) / 86_400).rounded())
    switch days {
    case 0: return "Today"
    case 1: return "Tomorrow"
    case -1: return "Yesterday"
    case let n where n > 1: return "In \(n) days"
    default: return "\(-days) days ago"
    }
}

/// "Daily", or "Mon, Wed, Fri".
private func runDaysText(_ days: [Day]) -> String {
    days.count == 7 ? "Daily" : weekOrder.filter(days.contains).map(\.rawValue).joined(separator: ", ")
}

/// A feed "HH:MM" rendered in the user's 12/24-hour preference.
private func hmText(_ hm: String) -> String {
    guard let minutes = parseHMOrNil(hm) else { return hm }
    return fmtTime(istDateTime(istDateISO(Date()), minutes: minutes))
}

/// "16:35" travel time → ("16h", "35 MIN"), the route list's left-rail numeral.
private func durationParts(_ hm: String) -> (value: String, unit: String) {
    let parts = hm.split(separator: ":").compactMap { Int($0) }
    guard parts.count >= 2 else { return (hm, "") }
    if parts[0] == 0 { return ("\(parts[1])", "MIN") }
    return ("\(parts[0])h", parts[1] == 0 ? "" : "\(parts[1]) MIN")
}

func runDaysLabel(_ days: [Day]) -> String {
    days.count == 7 ? "DAILY" : days.map { $0.rawValue.uppercased().prefix(1) }.joined(separator: " ")
}

/// RailError already carries a traveller-friendly message; anything else — a
/// dropped connection, a decode failure, a cancelled task — reads as a network
/// problem, not a raw NSError string.
func railErrorText(_ error: Error) -> String {
    if let rail = error as? RailError { return rail.errorDescription ?? "" }
    return "Couldn't reach the railway feed — check your connection."
}

// MARK: - Shared pieces

/// Icon, title, subtitle, optional trailing accessory: every list row in the
/// add flow.
private struct FlowRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var dimmed = false
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 14) {
            leading.frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.dsHeadline)
                    .foregroundStyle(dimmed ? DS.tertiary : DS.ink)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.dsFootnote)
                        .foregroundStyle(dimmed ? DS.tertiary : DS.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

extension FlowRow where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, dimmed: Bool = false,
         @ViewBuilder leading: () -> Leading) {
        self.init(title: title, subtitle: subtitle, dimmed: dimmed,
                  leading: leading, trailing: { EmptyView() })
    }
}

private struct FlowError: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(glyphFont)
                .foregroundStyle(DS.secondary)
            Text(message)
                .font(.dsCallout)
                .foregroundStyle(DS.secondary)
                .multilineTextAlignment(.center)
            DSPill(title: "Try Again", systemImage: "arrow.clockwise", filled: false, action: retry)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

private struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(DS.fill).frame(width: 56, height: 44)
            VStack(alignment: .leading, spacing: 8) {
                Capsule().fill(DS.fill).frame(width: 90, height: 10)
                Capsule().fill(DS.fill).frame(width: 190, height: 14)
                Capsule().fill(DS.fill).frame(width: 150, height: 10)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .accessibilityHidden(true)
    }
}

private struct SkeletonPulse: ViewModifier {
    @State private var dim = false

    func body(content: Content) -> some View {
        content
            .opacity(dim ? 0.45 : 1)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: dim)
            .onAppear { dim = true }
    }
}

extension View {
    /// The loading shimmer for placeholder shapes.
    func skeletonPulse() -> some View { modifier(SkeletonPulse()) }
}

/// Departure and arrival times at two halts with codes, cities, and the
/// running time between them.
struct JourneyTimesRow: View {
    let departure: Date
    let arrival: Date
    let from: Stop
    let to: Stop
    /// Shown under the duration ("1,384 km").
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            endpoint(departure, stop: from, dayShift: 0, alignment: .leading)
            VStack(spacing: 5) {
                Text(fmtDuration(arrival.timeIntervalSince(departure) / 60))
                    .font(.dsCaption)
                    .foregroundStyle(DS.secondary)
                HStack(spacing: 0) {
                    Circle().fill(DS.tertiary).frame(width: 5, height: 5)
                    Rectangle().fill(DS.separator).frame(height: 2)
                    Circle().fill(DS.tertiary).frame(width: 5, height: 5)
                }
                if let detail {
                    Text(detail)
                        .font(.dsCaption)
                        .foregroundStyle(DS.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            endpoint(arrival, stop: to, dayShift: dayShift, alignment: .trailing)
        }
    }

    private var dayShift: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return cal.dateComponents([.day], from: cal.startOfDay(for: departure),
                                  to: cal.startOfDay(for: arrival)).day ?? 0
    }

    private func endpoint(_ date: Date, stop: Stop, dayShift: Int,
                          alignment: HorizontalAlignment) -> some View {
        let size: CGFloat = 22
        return VStack(alignment: alignment, spacing: 2) {
            (Text(fmtTime(date)).font(.system(size: size, weight: .bold))
                + Text(dayShift > 0 ? "+\(dayShift)" : "")
                    .font(.system(size: size * 0.55, weight: .bold))
                    .baselineOffset(size * 0.4))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
            Text(stop.code)
                .font(.dsSubhead)
                .foregroundStyle(DS.ink)
            Text(cityFor(stop.code, stop.name))
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
                .lineLimit(1)
        }
    }
}

/// The "Added to My Trips" confirmation: a big check on a frosted square that
/// springs in, shown for a beat before the trip takes focus.
struct AddedHUD: View {
    var title = "Added to My Trips"
    @State private var shown = false

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(DS.ink)
                .scaleEffect(shown ? 1 : 0.4)
            Text(title)
                .font(.dsHeadline)
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(width: 196, height: 176)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
        .scaleEffect(shown ? 1 : 0.85)
        .opacity(shown ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) { shown = true }
        }
        .accessibilityElement(children: .combine)
    }
}
