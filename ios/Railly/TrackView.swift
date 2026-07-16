import SwiftUI

/// Track any train on the network without holding a ticket — instant offline
/// search over the real catalog, live schedule fetch on selection.
struct TrackView: View {
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private func phaseRank(_ p: RunPhase) -> Int {
        switch p {
        case .enroute: return 0
        case .boarding: return 1
        case .scheduled: return 2
        case .arrived: return 3
        }
    }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                let now = ctx.date
                let q = query.trimmingCharacters(in: .whitespaces)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header(now: now)
                        searchField
                            .padding(.top, 14)

                        if q.isEmpty {
                            watchedSection(now: now)
                        } else {
                            resultsSection(q)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                .background(Color.white)
            }
            .navigationDestination(for: String.self) { token in
                ResolveDetailView(token: token)
            }
        }
    }

    private func header(now: Date) -> some View {
        let watched = watchedTrips(now: now)
        let running = watched.filter { $0.live.phase == .enroute }.count
        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text("Track")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(Color.inkline)
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Color.onTime).frame(width: 8, height: 8)
                    Text("\(running) running")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.onTime)
                        .rollingNumbers(value: "\(running)")
                }
            }
            Text("Follow any of \(Catalog.trains.count) real trains, ticket or not.")
                .font(.system(size: 14))
                .foregroundStyle(Color.subGray)
        }
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.fadedGray)
            TextField("Train number or name", text: $query)
                .font(.system(size: 17))
                .focused($searchFocused)
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

    /// Resolve a set of numbers to live trips, deduped and phase-sorted —
    /// everything already resolved locally.
    private func trips(_ numbers: [String], now: Date) -> [HeldTrip] {
        var seen = Set<String>()
        return numbers
            .filter { seen.insert($0).inserted }
            .compactMap { bank.cached($0) }
            .map { liveTripFor($0, now) }
            .sorted { a, b in
                let ra = phaseRank(a.live.phase)
                let rb = phaseRank(b.live.phase)
                if ra != rb { return ra < rb }
                return a.live.departsAt < b.live.departsAt
            }
    }

    /// The user's held trains plus the popular set, for the running count.
    private func watchedTrips(now: Date) -> [HeldTrip] {
        trips(store.records.map(\.number) + bank.seedNumbers, now: now)
    }

    @ViewBuilder
    private func watchedSection(now: Date) -> some View {
        let heldNumbers = Set(store.records.map(\.number))
        let held = trips(store.records.map(\.number), now: now)
        let popular = trips(bank.seedNumbers.filter { !heldNumbers.contains($0) }, now: now)

        if !held.isEmpty {
            sectionEyebrow("YOUR TRAINS")
            watchedRows(held, now: now)
        }
        if !popular.isEmpty {
            sectionEyebrow("POPULAR")
            watchedRows(popular, now: now)
        }
    }

    private func sectionEyebrow(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .bold))
            .kerning(0.8)
            .foregroundStyle(Color.fadedGray)
            .padding(.top, 18)
    }

    @ViewBuilder
    private func watchedRows(_ list: [HeldTrip], now: Date) -> some View {
        ForEach(Array(list.enumerated()), id: \.element.id) { i, trip in
            NavigationLink(value: trip.id) {
                TripRowView(trip: trip, now: now, divider: i < list.count - 1)
            }
            .buttonStyle(.pressableRow)
        }
    }

    @ViewBuilder
    private func resultsSection(_ q: String) -> some View {
        let matches = Catalog.searchTrains(q)
        if matches.isEmpty {
            Text("No trains match “\(q)”")
                .font(.system(size: 16))
                .foregroundStyle(Color.fadedGray)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else {
            ForEach(matches) { t in
                NavigationLink(value: t.number) {
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
        }
    }
}

/// Bridges a navigation token to the detail screen. Accepts either a trip id
/// ("12951_2026-07-08") or a bare train number ("12951", resolved to its
/// current run — fetching the schedule first if it isn't cached yet).
struct ResolveDetailView: View {
    let token: String
    @EnvironmentObject private var bank: TrainBank
    @State private var errorText: String?

    private var resolvedId: String? {
        if token.contains("_") { return token }
        guard let train = bank.cached(token) else { return nil }
        return liveTripFor(train, Date()).id
    }

    var body: some View {
        if let id = resolvedId {
            TripDetailView(id: id)
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
                    Task { await resolve() }
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
            .task { await resolve() }
        }
    }

    private func resolve() async {
        do {
            _ = try await bank.resolve(token)
        } catch {
            errorText = railErrorText(error)
        }
    }
}
