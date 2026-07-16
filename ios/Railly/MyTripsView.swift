import MapKit
import SwiftUI

/// The ambient hero: the user's own routes as blue arcs, live trains as
/// glowing dots. In on-rails mode only the routes actually being run stay
/// lit, so the filter reads on the map before you ever reach the list.
struct NetworkMapView: View {
    let now: Date
    let trips: [HeldTrip]
    var onRailsOnly = false

    private var arcTrains: [Train] {
        var seen = Set<String>()
        return trips.compactMap { seen.insert($0.train.number).inserted ? $0.train : nil }
    }

    private var liveMarkers: [(String, CLLocationCoordinate2D)] {
        trips.compactMap { trip in
            guard trip.live.phase == .enroute else { return nil }
            return (trip.id, CLLocationCoordinate2D(
                latitude: trip.live.positionLat, longitude: trip.live.positionLng))
        }
    }

    private func isEnroute(_ train: Train) -> Bool {
        trips.contains { $0.train.number == train.number && $0.live.phase == .enroute }
    }

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 21.5, longitude: 79.5),
            span: MKCoordinateSpan(latitudeDelta: 24, longitudeDelta: 22)
        ))) {
            ForEach(arcTrains) { train in
                MapPolyline(coordinates: railDrawCoords(train.stops))
                .stroke(
                    Color.arcBlue.opacity(onRailsOnly && !isEnroute(train) ? 0.10 : 0.85),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            ForEach(liveMarkers, id: \.0) { id, coordinate in
                Annotation("", coordinate: coordinate) {
                    Circle()
                        .fill(.white)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Color.arcBlue, lineWidth: 3).frame(width: 14, height: 14))
                        .shadow(color: Color.arcBlue.opacity(0.9), radius: 6)
                        .accessibilityLabel("Train \(id.prefix(while: { $0 != "_" })) on rails now")
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .colorScheme(.dark)
    }
}

struct MyTripsView: View {
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    // seeded by the -railly.onrails snapshot arg; false in normal launches
    @State private var onRailsOnly = UserDefaults.standard.bool(forKey: "railly.onrails")
    // NavigationPath, not [String]: the detail screen pushes AvailRoute values
    // and a typed path silently drops pushes of any other type
    @State private var path = NavigationPath()
    @State private var showAdd = false
    @State private var showSettings = false
    @State private var deleteCandidate: HeldTrip?
    @State private var deleteCount = 0
    @AppStorage("railly.profileName") private var profileName = ""

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    // The map redraws on a slow tick; rows tick every second.
                    TimelineView(.periodic(from: .now, by: 30)) { ctx in
                        let trips = store.myTrips(ctx.date, bank: bank)
                        NetworkMapView(now: ctx.date,
                                       trips: trips.live + trips.upcoming,
                                       onRailsOnly: onRailsOnly)
                            .frame(height: 320)
                            .topMapScrim()
                    }

                    sheet
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 36, topTrailingRadius: 36
                            )
                            .fill(.white)
                        )
                        .offset(y: -28)
                }
                .readableColumn()
            }
            .scrollIndicators(.hidden)
            // white spinner reads over the dark map it pulls down onto
            .tint(.white)
            .refreshable {
                // Only force-refetch schedules that have actually gone stale,
                // at most two erail calls in flight at once; a failed refetch
                // keeps the cached copy (bank.resolve swallows the error).
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
                // live status is a single cheap call — refresh every held run
                for rec in store.records {
                    await refreshLive(rec.number, rec.runDate)
                }
            }
            // white, not black: the dark map bleeds up top on its own, and a
            // black scroll background showed through under the tab bar whenever
            // the list was short or empty.
            .background(Color.white)
            .ignoresSafeArea(edges: .top)
            .navigationDestination(for: String.self) { id in
                TripDetailView(id: id)
            }
            .sheet(isPresented: $showAdd) {
                AddTripView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
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
    }

    /// Header chrome lives OUTSIDE the per-second TimelineView: rebuilding an
    /// open Menu's anchor every tick dismisses the menu before a selection
    /// can land. Only the rows tick.
    private var sheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Menu {
                    Picker("Show", selection: $onRailsOnly) {
                        Text("All trips").tag(false)
                        Text("On rails now").tag(true)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(onRailsOnly ? "On Rails" : "My Trips")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundStyle(Color.inkline)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Color.inkline)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Text(profileAvatarInitial(profileName))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: 0x2563AB))
                        .frame(width: 42, height: 42)
                        .background(Color(hex: 0xCFE3F8), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
            .padding(.top, 22)

            // the search field is the add-trip flow, Flighty-style
            Button {
                showAdd = true
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.fadedGray)
                    Text("Search to add trains")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.fadedGray)
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.arcBlue)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.top, 14)

            // per-second only matters while a train is moving; idle lists coast
            // on a 10s tick so rows aren't rebuilt 60× a minute for nothing
            TimelineView(.periodic(from: .now, by: anyEnroute(Date()) ? 1 : 10)) { ctx in
                sections(now: ctx.date)
                    .animation(.snappy(duration: 0.35), value: onRailsOnly)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 120)
        .sensoryFeedback(.selection, trigger: onRailsOnly)
        // the white spinner tint is scoped to the scroll chrome; the sheet's
        // own controls (filter menu checkmark) keep a visible accent
        .tint(Color.arcBlue)
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

    /// Small all-caps section label, same voice as the row captions.
    private func eyebrow(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .bold))
            .kerning(0.8)
            .foregroundStyle(Color.subGray)
            .padding(.top, 18)
    }

    @ViewBuilder
    private func rows(_ trips: [HeldTrip], now: Date) -> some View {
        ForEach(Array(trips.enumerated()), id: \.element.id) { i, trip in
            NavigationLink(value: trip.id) {
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tram")
                .font(.system(size: 34))
                .foregroundStyle(Color.fadedGray)
                .padding(.bottom, 6)
            Text("Let's Ride Somewhere")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Color.inkline)
            Text("Tap the search bar to add your first train —\nevery real IR service is in there.")
                .font(.system(size: 14))
                .foregroundStyle(Color.subGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.bottom, 20)
    }

    /// The toggle must be legible at the top of the list — both modes lead
    /// with the same live trains, so without the count line and section
    /// eyebrows the switch used to look like a no-op.
    @ViewBuilder
    private func sections(now: Date) -> some View {
        let trips = store.myTrips(now, bank: bank)
        let live = trips.live.filter { !onRailsOnly || $0.live.phase == .enroute }

        if onRailsOnly {
            (Text("\(live.count)").fontWeight(.bold).foregroundStyle(Color.textGreen)
                + Text(live.count == 1 ? " train moving right now" : " trains moving right now")
                .foregroundStyle(Color.subGray))
                .font(.system(size: 14))
                .padding(.top, 14)

            if live.isEmpty {
                Text("Nothing on rails right now.")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.subGray)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            }
            rows(live, now: now)
        } else {
            if trips.isEmpty {
                emptyState
            }
            if !live.isEmpty {
                eyebrow("LIVE NOW")
                rows(live, now: now)
            }
            if !trips.upcoming.isEmpty {
                eyebrow("UP NEXT")
                rows(trips.upcoming, now: now)
            }
            if !trips.past.isEmpty {
                Text("Past Trips")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.inkline)
                    .padding(.top, 22)
                rows(trips.past, now: now)
            }
        }
    }
}
