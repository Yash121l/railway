import SwiftUI

/// The sheet's resting content: My Trips. The header and search field are
/// pinned above the list and together fill exactly the 118pt peek detent, so
/// a lowered sheet still reads as a finished screen.
@MainActor
struct TripsSheet: View {
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @EnvironmentObject private var router: Router
    // seeded by the -railly.onrails snapshot arg; false in normal launches
    @State private var onRailsOnly = UserDefaults.standard.bool(forKey: "railly.onrails")
    @State private var showPast = false
    @State private var deleteCandidate: HeldTrip?
    @State private var deleteCount = 0
    @AppStorage("railly.profileName") private var profileName = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header chrome lives OUTSIDE the ticking TimelineView: rebuilding
            // an open Menu's anchor every tick dismisses the menu before a
            // selection can land. Only the rows tick.
            header
                .padding(.top, 16)
            searchField
                .padding(.top, 10)

            ScrollView {
                // per-second only matters while a train is moving; idle lists
                // coast on a 10s tick. The outer 30s tick re-decides the rate,
                // so a departure or arrival while idle switches it.
                TimelineView(.periodic(from: .now, by: 30)) { outer in
                    TimelineView(.periodic(from: .now, by: anyEnroute(outer.date) ? 1 : 10)) { ctx in
                        VStack(alignment: .leading, spacing: 0) {
                            sections(now: ctx.date)
                        }
                        .animation(.snappy(duration: 0.35), value: onRailsOnly)
                        .animation(.snappy(duration: 0.35), value: showPast)
                    }
                }
                .padding(.horizontal, DS.gutter)
                .padding(.top, 4)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)
            .refreshable { await refresh() }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .tint(DS.action)
        .sensoryFeedback(.selection, trigger: onRailsOnly)
        .confirmationDialog(
            "Delete \(deleteCandidate?.train.displayName ?? "this trip")?",
            isPresented: Binding(
                get: { deleteCandidate != nil },
                set: { if !$0 { deleteCandidate = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Trip", role: .destructive) {
                if let trip = deleteCandidate {
                    withAnimation(.snappy) { store.remove(trip.id) }
                    deleteCount += 1
                }
                deleteCandidate = nil
            }
        }
        .sensoryFeedback(.warning, trigger: deleteCount)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            Menu {
                Picker("Show", selection: $onRailsOnly) {
                    Text("All trips").tag(false)
                    Text("On rails now").tag(true)
                }
            } label: {
                HStack(spacing: 7) {
                    Text(onRailsOnly ? "On Rails" : "My Trips")
                        .font(.dsLargeTitle)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(DS.secondary)
                }
                .foregroundStyle(DS.ink)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(onRailsOnly ? "On Rails, filter" : "My Trips, filter")

            Spacer()

            Button {
                router.present(.profile)
            } label: {
                ProfileAvatar(name: profileName, size: 36)
            }
            .buttonStyle(DSPressStyle())
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal, DS.gutter)
    }

    // the search field IS the add flow, Flighty-style
    private var searchField: some View {
        Button {
            router.present(.add(prefill: nil))
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DS.secondary)
                Text("Train, station or PNR")
                    .font(.dsHeadline.weight(.regular))
                    .foregroundStyle(DS.secondary)
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.action)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .dsWell()
            .contentShape(Rectangle())
        }
        .buttonStyle(DSPressStyle())
        .padding(.horizontal, DS.gutter)
        .accessibilityLabel("Search trains, stations or PNR")
        .accessibilityHint("Adds a trip")
    }

    // MARK: Sections

    /// The filter must be legible at the top of the list: both modes lead with
    /// the same live trains, so without the count line and eyebrows the switch
    /// looks like a no-op.
    @ViewBuilder
    private func sections(now: Date) -> some View {
        let trips = store.myTrips(now, bank: bank)

        if onRailsOnly {
            let moving = trips.live.filter { $0.live.phase == .enroute }
            (Text("\(moving.count)").fontWeight(.bold).foregroundStyle(DS.onTimeText)
                + Text(moving.count == 1 ? " train moving right now" : " trains moving right now")
                .foregroundStyle(DS.secondary))
                .font(.dsSubhead.weight(.regular))
                .padding(.top, 14)

            if moving.isEmpty {
                Text("Nothing on rails right now.")
                    .font(.dsBody)
                    .foregroundStyle(DS.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            }
            rows(moving, now: now)
        } else if trips.isEmpty {
            emptyState
        } else {
            if !trips.live.isEmpty {
                sectionLabel("Live now")
                rows(trips.live, now: now)
            }
            if !trips.upcoming.isEmpty {
                sectionLabel("Up next")
                rows(trips.upcoming, now: now)
            }
            if trips.live.isEmpty && trips.upcoming.isEmpty {
                nothingAhead
            }
            if !trips.past.isEmpty {
                pastToggle(count: trips.past.count)
                if showPast {
                    rows(trips.past, now: now)
                        .transition(.opacity)
                }
            }
        }
    }

    private func sectionLabel(_ s: String) -> some View {
        Text(s)
            .eyebrow()
            .padding(.top, 20)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func rows(_ trips: [HeldTrip], now: Date) -> some View {
        ForEach(Array(trips.enumerated()), id: \.element.id) { i, trip in
            Button {
                router.focus(trip.id)
            } label: {
                TripRowView(trip: trip, now: now, divider: i < trips.count - 1)
            }
            .buttonStyle(.pressableRow)
            .contextMenu {
                Button(role: .destructive) {
                    deleteCandidate = trip
                } label: {
                    Label("Delete Trip", systemImage: "trash")
                }
            }
        }
    }

    private func pastToggle(count: Int) -> some View {
        Button {
            showPast.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.secondary)
                Text("Past Trips")
                    .font(.dsHeadline)
                    .foregroundStyle(DS.ink)
                Spacer()
                Text("\(count)")
                    .font(.dsCallout)
                    .foregroundStyle(DS.secondary)
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.tertiary)
                    .rotationEffect(.degrees(showPast ? 90 : 0))
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .dsWell()
            .contentShape(Rectangle())
        }
        .buttonStyle(DSPressStyle())
        .padding(.top, 24)
        .padding(.bottom, showPast ? 4 : 0)
        .accessibilityLabel("Past Trips, \(count)")
        .accessibilityValue(showPast ? "Expanded" : "Collapsed")
    }

    // MARK: Empty states

    private var trainCountLine: String {
        let n = Catalog.trains.count
        guard n > 0 else { return "Search any train or check a PNR" }
        return "Search any of \(n.formatted()) trains or check a PNR"
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().stroke(DS.fill2, lineWidth: 1.5).frame(width: 118, height: 118)
                Circle().fill(DS.fill).frame(width: 86, height: 86)
                Image(systemName: "tram.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(DS.ink2)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(DS.action, in: Circle())
                    .overlay(Circle().stroke(DS.sheet, lineWidth: 3))
                    .offset(x: 32, y: 30)
                Image(systemName: "ticket.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DS.platformInk)
                    .frame(width: 26, height: 26)
                    .background(DS.platform, in: Circle())
                    .overlay(Circle().stroke(DS.sheet, lineWidth: 3))
                    .offset(x: -40, y: -26)
            }
            .accessibilityHidden(true)
            .padding(.bottom, 22)

            Text("Let's Ride Somewhere")
                .font(.dsSection)
                .foregroundStyle(DS.ink)
            Text(trainCountLine)
                .font(.dsCallout)
                .foregroundStyle(DS.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 6)

            HStack(spacing: 10) {
                DSPill(title: "Add a train", systemImage: "plus", filled: false) {
                    router.present(.add(prefill: nil))
                }
                DSPill(title: "Check PNR", systemImage: "ticket", filled: false) {
                    router.present(.add(prefill: nil, pnrMode: true))
                }
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 36)
        .padding(.bottom, 12)
    }

    /// Only finished trips held: say so instead of leaving a bare list.
    private var nothingAhead: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DS.action)
                .frame(width: 44, height: 44)
                .background(DS.action.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Nothing coming up")
                    .font(.dsHeadline)
                    .foregroundStyle(DS.ink)
                Text("Add your next train to track it here.")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
            }
        }
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
    }

    // MARK: Refresh & tick gating

    private func refresh() async {
        // Only force-refetch schedules that have actually gone stale, at most
        // two erail calls in flight at once; a failed refetch keeps the cached
        // copy (bank.resolve swallows the error).
        let stale = store.records.filter { bank.isStale($0.number) }
        for chunk in stride(from: 0, to: stale.count, by: 2) {
            await withTaskGroup(of: Void.self) { group in
                for rec in stale[chunk..<min(chunk + 2, stale.count)] {
                    group.addTask { [bank] in
                        _ = try? await bank.resolve(rec.number, forceRefresh: true)
                    }
                }
            }
        }
        // live status is a single cheap call: refresh every held run
        for rec in store.records {
            await refreshLive(rec.number, rec.runDate)
        }
    }

    /// Is any held run actually moving right now? Uses the memoized `buildRun`
    /// and skips event synthesis, so it's cheap enough to gate the tick rate.
    private func anyEnroute(_ now: Date) -> Bool {
        for rec in store.records {
            guard let train = bank.cached(rec.number) else { continue }
            let run = buildRun(train, rec.runDate)
            if now >= run.departsEst && now < run.arrivesEst { return true }
        }
        return false
    }
}
