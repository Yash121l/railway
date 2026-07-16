import SwiftUI

/// Flighty's Add Flight sheet, for rails: instant offline search over every
/// real IR train, find-by-route via live erail lookups, then a date pick and
/// one tap to hold the trip.

private enum AddRoute: Hashable {
    case train(String)
    case byRoute
    case byRouteVia(String)
    case byPNR
    case avail(String)
}

struct AddTripView: View {
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var focused: Bool
    @AppStorage("railly.recentTrains") private var recentCSV = ""

    private var recents: [CatalogTrain] {
        recentCSV.split(separator: ",").compactMap { no in
            Catalog.trains.first { $0.number == String(no) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if query.trimmingCharacters(in: .whitespaces).isEmpty {
                            suggestions
                        } else {
                            results
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .background(Color.white)
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.subGray)
                    }
                }
            }
            .navigationDestination(for: AddRoute.self) { route in
                switch route {
                case .train(let number):
                    TrainAddView(number: number, dismissAll: { dismiss() })
                case .byRoute:
                    RouteSearchView(dismissAll: { dismiss() })
                case .byRouteVia(let code):
                    RouteSearchView(dismissAll: { dismiss() }, initialFrom: code)
                case .byPNR:
                    PNRAddView()
                case .avail(let number):
                    AvailabilityView(number: number)
                }
            }
            .navigationDestination(for: PNRRoute.self) { route in
                PNRResultView(pnr: route.pnr, dismissAll: { dismiss() })
            }
        }
        .onAppear { focused = true }
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.fadedGray)
            TextField("Train number, name, or station", text: $query)
                .font(.system(size: 17))
                .focused($focused)
                .searchFieldStyle()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.fadedGray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 16))
    }

    private func eyebrow(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .bold))
            .kerning(0.8)
            .foregroundStyle(Color.fadedGray)
            .padding(.top, 20)
            .padding(.bottom, 4)
    }

    @ViewBuilder
    private var suggestions: some View {
        // utility rows stay above the fold even with the keyboard up
        NavigationLink(value: AddRoute.byPNR) {
            utilityRow(icon: "ticket", title: "Add by PNR",
                       subtitle: "Import your booking, coach and berth")
        }
        .buttonStyle(.pressableRow)

        NavigationLink(value: AddRoute.byRoute) {
            utilityRow(icon: "arrow.triangle.swap", title: "Find by Route",
                       subtitle: "Every train between two stations")
        }
        .buttonStyle(.pressableRow)

        if !recents.isEmpty {
            eyebrow("RECENTLY USED")
            ForEach(recents) { t in
                trainRow(t)
            }
        }

        eyebrow("POPULAR TRAINS")
        ForEach(bank.seedNumbers.prefix(6), id: \.self) { no in
            if let t = Catalog.trains.first(where: { $0.number == no }) {
                trainRow(t)
            }
        }

        Button {
            if let t = Catalog.trains.randomElement() {
                query = t.number
            }
        } label: {
            utilityRow(icon: "dice", title: "Random Train",
                       subtitle: "Somewhere on the network, something is moving")
        }
        .buttonStyle(.pressableRow)
    }

    @ViewBuilder
    private var results: some View {
        let matches = Catalog.searchTrains(query)
        let station = stationHit(query)
        if let station {
            stationBridgeRow(station)
        }
        if matches.isEmpty {
            if station == nil {
                VStack(spacing: 6) {
                    Text("No trains match “\(query)”")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.fadedGray)
                    Text("Try the 5-digit train number or a station name.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fadedGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 48)
            }
        } else {
            eyebrow("\(matches.count >= 30 ? "30+" : String(matches.count)) TRAINS")
            ForEach(matches) { t in
                trainRow(t)
            }
        }
    }

    /// The placeholder promises stations too: when the query lands on a real
    /// station, offer a jump into Find by Route pre-seeded with it.
    private func stationHit(_ query: String) -> CatalogStation? {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return nil }
        return Catalog.searchStations(q, limit: 1).first
    }

    private func stationBridgeRow(_ s: CatalogStation) -> some View {
        NavigationLink(value: AddRoute.byRouteVia(s.c)) {
            utilityRow(icon: "arrow.triangle.swap",
                       title: "Trains through \(s.n)",
                       subtitle: "Every train on a route via \(s.c)")
        }
        .buttonStyle(.pressableRow)
    }

    private func trainRow(_ t: CatalogTrain) -> some View {
        NavigationLink(value: AddRoute.train(t.number)) {
            HStack(spacing: 11) {
                TrainMark(category: t.category, size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text(t.number)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subGray)
                        .monospacedDigit()
                    Text(t.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.inkline)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.fadedGray)
            }
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.pressableRow)
    }

    private func utilityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.arcBlue)
                .frame(width: 34, height: 34)
                .background(Color(hex: 0xEAF3FF), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.inkline)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.subGray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.fadedGray)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Find by Route

struct RouteSearchView: View {
    let dismissAll: () -> Void
    var initialFrom: String? = nil
    @State private var fromQuery = ""
    @State private var toQuery = ""
    @State private var from: CatalogStation?
    @State private var to: CatalogStation?
    @State private var results: [TrainSummary]?
    @State private var searching = false
    @State private var errorText: String?
    @FocusState private var focusedField: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                stationField(tag: 0, placeholder: "From station", query: $fromQuery, pick: $from)
                    .padding(.top, 12)
                HStack {
                    Spacer()
                    Button {
                        swap(&from, &to)
                        swap(&fromQuery, &toQuery)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.arcBlue)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: 0xEAF3FF), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
                stationField(tag: 1, placeholder: "To station", query: $toQuery, pick: $to)

                if let s = suggestionsForFocusedField, !s.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(s) { station in
                            Button {
                                select(station)
                            } label: {
                                HStack {
                                    Text(station.c)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.arcBlue)
                                        .frame(width: 58, alignment: .leading)
                                    Text(station.n)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.inkline)
                                    Spacer()
                                }
                                .padding(.vertical, 9)
                                .overlay(alignment: .bottom) {
                                    Rectangle().fill(Color.hairline).frame(height: 1)
                                }
                            }
                            .buttonStyle(.pressableRow)
                        }
                    }
                    .padding(.top, 6)
                }

                Button {
                    Task { await search() }
                } label: {
                    HStack {
                        if searching { ProgressView().tint(.white) }
                        Text(searching ? "Searching…" : "Find Trains")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(from != nil && to != nil ? Color.arcBlue : Color.fadedGray)
                    )
                }
                .buttonStyle(.plain)
                .disabled(from == nil || to == nil || searching)
                .padding(.top, 18)

                if let errorText {
                    Text(errorText)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.lateRed)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                }

                if let results {
                    (Text("\(results.count)").fontWeight(.bold).foregroundStyle(Color.inkline)
                        + Text(" trains on this route").foregroundStyle(Color.subGray))
                        .font(.system(size: 14))
                        .padding(.top, 22)
                    ForEach(results) { r in
                        resultRow(r)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color.white)
        .navigationTitle("Find by Route")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let initialFrom, from == nil,
                  let s = Catalog.stations.first(where: { $0.c == initialFrom })
            else { return }
            from = s
            fromQuery = "\(s.n) (\(s.c))"
            focusedField = 1
        }
    }

    private var suggestionsForFocusedField: [CatalogStation]? {
        switch focusedField {
        case 0: return fromQuery.count >= 2 && from == nil ? Catalog.searchStations(fromQuery) : nil
        case 1: return toQuery.count >= 2 && to == nil ? Catalog.searchStations(toQuery) : nil
        default: return nil
        }
    }

    private func select(_ station: CatalogStation) {
        if focusedField == 0 {
            from = station
            fromQuery = "\(station.n) (\(station.c))"
            focusedField = to == nil ? 1 : nil
        } else {
            to = station
            toQuery = "\(station.n) (\(station.c))"
            focusedField = nil
        }
    }

    private func stationField(tag: Int, placeholder: String,
                              query: Binding<String>, pick: Binding<CatalogStation?>) -> some View {
        HStack(spacing: 9) {
            Image(systemName: tag == 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(pick.wrappedValue == nil ? Color.fadedGray : Color.arcBlue)
            TextField(placeholder, text: query)
                .font(.system(size: 17))
                .focused($focusedField, equals: tag)
                .searchFieldStyle()
                .onChange(of: query.wrappedValue) { _, _ in
                    // typing again invalidates the previous pick
                    if pick.wrappedValue != nil,
                       query.wrappedValue != "\(pick.wrappedValue!.n) (\(pick.wrappedValue!.c))" {
                        pick.wrappedValue = nil
                    }
                }
            if !query.wrappedValue.isEmpty {
                Button {
                    query.wrappedValue = ""
                    pick.wrappedValue = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.fadedGray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 16))
    }

    private func search() async {
        guard let from, let to else { return }
        searching = true
        errorText = nil
        results = nil
        do {
            results = try await RailAPI.shared.trainsBetween(from.c, to.c)
        } catch {
            errorText = railErrorText(error)
        }
        searching = false
    }

    private func resultRow(_ r: TrainSummary) -> some View {
        NavigationLink(value: AddRoute.train(r.number)) {
            HStack(spacing: 11) {
                TrainMark(category: r.category, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Text(r.number)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.subGray)
                            .monospacedDigit()
                        Text(runDaysLabel(r.days))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.fadedGray)
                    }
                    Text(r.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.inkline)
                        .lineLimit(1)
                    Text("\(r.departure) \(r.fromCode) → \(r.arrival) \(r.toCode) · \(r.travelTime)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subGray)
                        .monospacedDigit()
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.fadedGray)
            }
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.pressableRow)
    }
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

// MARK: - Train + date pick

struct TrainAddView: View {
    let number: String
    let dismissAll: () -> Void

    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @AppStorage("railly.recentTrains") private var recentCSV = ""
    @State private var train: Train?
    @State private var errorText: String?
    @State private var selectedDate: String?
    @State private var selectedClass: JClass?
    @State private var justAdded = false
    @State private var showAllDates = false

    var body: some View {
        Group {
            if let train {
                loaded(train)
            } else if let errorText {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 30))
                        .foregroundStyle(Color.fadedGray)
                    Text(errorText)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.subGray)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        self.errorText = nil
                        Task { await load() }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.arcBlue)
                }
                .padding(30)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Fetching the live schedule…")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.subGray)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .navigationTitle(number)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        do {
            train = try await bank.resolve(number)
            if selectedDate == nil { selectedDate = dateOptions().first }
        } catch {
            errorText = railErrorText(error)
        }
    }

    /// Upcoming valid run dates (respecting the real run-day calendar). Six
    /// within a fortnight by default; the expander opens the full 60-day ARP
    /// window, the real advance-reservation horizon.
    private func dateOptions() -> [String] {
        guard let train else { return [] }
        let today = istDateISO(Date())
        let horizon = showAllDates ? 60 : 13
        let cap = showAllDates ? 60 : 6
        var future: [String] = []
        for offset in 0...horizon where future.count < cap {
            let d = addDaysISO(today, offset)
            if train.days.contains(istWeekday(d)) { future.append(d) }
        }
        return future
    }

    private func pastOptions() -> [String] {
        guard let train else { return [] }
        let today = istDateISO(Date())
        var past: [String] = []
        for offset in stride(from: -1, through: -10, by: -1) where past.count < 2 {
            let d = addDaysISO(today, offset)
            if train.days.contains(istWeekday(d)) { past.append(d) }
        }
        return past
    }

    private func loaded(_ train: Train) -> some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header(train)
                    daysStrip(train)
                        .padding(.top, 14)
                    if !train.classes.isEmpty {
                        classChips(train)
                            .padding(.top, 10)
                    }
                    if !JClass.reservable(from: train.classes).isEmpty {
                        availabilityLink(train)
                            .padding(.top, 12)
                    }

                    eyebrow("CHOOSE A DATE")
                    ForEach(dateOptions(), id: \.self) { d in
                        dateRow(d, train: train)
                    }
                    if !showAllDates {
                        moreDatesRow
                    }
                    eyebrow("ADD A PAST TRIP")
                    ForEach(pastOptions(), id: \.self) { d in
                        dateRow(d, train: train)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 130)
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()
                addButton(train)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(colors: [.white.opacity(0), .white, .white],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }

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
        .sensoryFeedback(.success, trigger: justAdded)
    }

    private func header(_ train: Train) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                TrainMark(category: train.category, size: 44)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 7) {
                        Text(train.number)
                            .font(.system(size: 12, weight: .semibold))
                            .kerning(0.5)
                            .foregroundStyle(Color.subGray)
                        Text(train.category.label.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .kerning(0.6)
                            .foregroundStyle(train.category.liveryColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(train.category.liveryColor.opacity(0.12), in: Capsule())
                    }
                    Text(train.displayName)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(Color.inkline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                }
            }
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(train.departureTime)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Color.inkline)
                        .monospacedDigit()
                    Text("\(train.origin.code) · \(cityFor(train.origin.code, train.origin.name))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.subGray)
                        .lineLimit(1)
                }
                VStack(spacing: 3) {
                    Text(fmtDuration(Double(train.destination.arrMin)))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.fadedGray)
                    Rectangle().fill(Color.hairline).frame(height: 1)
                    Text("\(Int(train.distanceKm)) km · \(train.stops.count) halts")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fadedGray)
                }
                .frame(maxWidth: .infinity)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(arrivalHM(train))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Color.inkline)
                        .monospacedDigit()
                    Text("\(train.destination.code) · \(cityFor(train.destination.code, train.destination.name))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.subGray)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 14)
    }

    private func arrivalHM(_ train: Train) -> String {
        let total = parseHM(train.departureTime) + train.destination.arrMin
        let plusDays = total / (24 * 60)
        let hm = String(format: "%02d:%02d", (total % (24 * 60)) / 60, total % 60)
        return plusDays > 0 ? "\(hm) +\(plusDays)" : hm
    }

    private func daysStrip(_ train: Train) -> some View {
        HStack(spacing: 6) {
            Text("RUNS")
                .font(.system(size: 10, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(Color.fadedGray)
            ForEach([Day.mon, .tue, .wed, .thu, .fri, .sat, .sun], id: \.self) { d in
                let runs = train.days.contains(d)
                Text(d.rawValue.prefix(1))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(runs ? .white : Color.fadedGray.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .background(
                        Circle().fill(runs ? Color.arcBlue : Color.fillGray)
                    )
            }
        }
    }

    /// Class chips double as the availability selector: the picked class
    /// drives the per-date status chips below.
    private func classChips(_ train: Train) -> some View {
        let reservable = JClass.reservable(from: train.classes)
        let selected = selectedClass ?? JClass.defaultPick(reservable)
        return HStack(spacing: 6) {
            Text("CLASSES")
                .font(.system(size: 10, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(Color.fadedGray)
            ForEach(train.classes, id: \.self) { c in
                let jc = JClass(rawValue: c)
                let selectable = jc.map { reservable.contains($0) } ?? false
                let isSel = jc != nil && jc == selected
                Button {
                    if let jc, reservable.contains(jc) { selectedClass = jc }
                } label: {
                    Text(c)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSel ? .white : Color.inkline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isSel ? Color.inkline : Color.fillGray,
                                    in: RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                .opacity(selectable ? 1 : 0.4)
                .disabled(!selectable)
            }
        }
        .sensoryFeedback(.selection, trigger: selectedClass)
    }

    private func availabilityLink(_ train: Train) -> some View {
        NavigationLink(value: AddRoute.avail(train.number)) {
            HStack(spacing: 8) {
                Image(systemName: "chair.lounge")
                    .font(.system(size: 13, weight: .semibold))
                Text("Seat availability & fares")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.fadedGray)
            }
            .foregroundStyle(Color.arcBlue)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color(hex: 0xEAF3FF), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func eyebrow(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .bold))
            .kerning(0.8)
            .foregroundStyle(Color.fadedGray)
            .padding(.top, 22)
            .padding(.bottom, 4)
    }

    private var moreDatesRow: some View {
        Button {
            withAnimation(.snappy) { showAllDates = true }
        } label: {
            HStack {
                Text("More dates").fontWeight(.semibold)
                    .foregroundStyle(Color.arcBlue)
                Text("up to 60 days out")
                    .foregroundStyle(Color.subGray)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.arcBlue)
            }
            .font(.system(size: 16))
            .padding(.vertical, 11)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.pressableRow)
    }

    private func dateRow(_ d: String, train: Train) -> some View {
        let today = istDateISO(Date())
        let label = d == today ? "Today"
            : d == addDaysISO(today, 1) ? "Tomorrow"
            : d == addDaysISO(today, -1) ? "Yesterday"
            : nil
        let pretty = fmtDay(istDateTime(d, minutes: 12 * 60))
        let held = store.isHeld(tripId(train.number, d))

        return Button {
            selectedDate = d
        } label: {
            HStack {
                Image(systemName: selectedDate == d ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selectedDate == d ? Color.arcBlue : Color(hex: 0xD8D8DC))
                if let label {
                    Text(label).fontWeight(.semibold)
                        .foregroundStyle(Color.inkline)
                    Text(pretty)
                        .foregroundStyle(Color.subGray)
                } else {
                    Text(pretty).fontWeight(.medium)
                        .foregroundStyle(Color.inkline)
                }
                Spacer()
                if held {
                    Text("ADDED")
                        .font(.system(size: 10, weight: .bold))
                        .kerning(0.6)
                        .foregroundStyle(Color.onTime)
                } else {
                    availabilityChip(d, train: train)
                }
            }
            .font(.system(size: 16))
            .padding(.vertical, 11)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.pressableRow)
    }

    /// The IRCTC glance: every candidate date wears its seat status for the
    /// selected class (general quota).
    @ViewBuilder
    private func availabilityChip(_ d: String, train: Train) -> some View {
        let reservable = JClass.reservable(from: train.classes)
        if let jc = selectedClass ?? JClass.defaultPick(reservable) {
            let status = Reservation.availability(train, jc, .general, d, now: Date())
            switch status {
            case .departed, .noService, .charting:
                EmptyView()
            default:
                Text(status.chip)
                    .font(.system(size: 11, weight: .bold))
                    .kerning(0.3)
                    .monospacedDigit()
                    .foregroundStyle(chipTone(status))
            }
        }
    }

    private func chipTone(_ s: AvailStatus) -> Color {
        switch s {
        case .available: return .onTime
        case .rac: return Color(hex: 0xB58900)
        case .waitlist, .regret: return .lateRed
        default: return .fadedGray
        }
    }

    private func addButton(_ train: Train) -> some View {
        let held = selectedDate.map { store.isHeld(tripId(train.number, $0)) } ?? false
        return Button {
            guard let selectedDate, !held else { return }
            store.add(train, runDate: selectedDate)
            rememberRecent(train.number)
            withAnimation(.spring(duration: 0.35)) { justAdded = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismissAll() }
        } label: {
            Text(held ? "Already in My Trips" : "Add Trip")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(held ? Color.fadedGray : Color.arcBlue)
                )
        }
        .buttonStyle(.plain)
        .disabled(selectedDate == nil || held || justAdded)
    }

    private func rememberRecent(_ number: String) {
        var list = recentCSV.split(separator: ",").map(String.init)
        list.removeAll { $0 == number }
        list.insert(number, at: 0)
        recentCSV = list.prefix(5).joined(separator: ",")
    }
}

// MARK: - Add by PNR

/// The import move: type the PNR from a ticket, land on the full status
/// screen, add the trip with its real coach/berth in one tap.
struct PNRAddView: View {
    @State private var digits = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("The 10 digits on the top-left of your ticket or the IRCTC confirmation SMS.")
                .font(.system(size: 14))
                .foregroundStyle(Color.subGray)

            HStack(spacing: 9) {
                Image(systemName: "ticket")
                    .foregroundStyle(Color.fadedGray)
                TextField("10-digit PNR number", text: Binding(
                    get: { groupPNR(digits) },
                    set: { digits = String($0.filter(\.isNumber).prefix(10)) }
                ))
                .font(.system(size: 22, weight: .semibold))
                .monospacedDigit()
                .kerning(1.5)
                .focused($focused)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
            }
            .padding(.horizontal, 14)
            .frame(height: 60)
            .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 16))

            NavigationLink(value: PNRRoute(pnr: digits)) {
                Text("Check & Import")
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

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(Color.white)
        .navigationTitle("Add by PNR")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
    }
}
