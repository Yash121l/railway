import MapKit
import SwiftUI

/// The ambient hero: every route as a blue arc, live trains as glowing dots.
struct NetworkMapView: View {
    let now: Date

    private var liveMarkers: [(String, CLLocationCoordinate2D)] {
        allTrains.compactMap { train in
            let s = getLiveStatus(train, now)
            guard s.phase == .enroute else { return nil }
            return (train.number, CLLocationCoordinate2D(latitude: s.positionLat, longitude: s.positionLng))
        }
    }

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 21.5, longitude: 79.5),
            span: MKCoordinateSpan(latitudeDelta: 24, longitudeDelta: 22)
        ))) {
            ForEach(allTrains) { train in
                MapPolyline(coordinates: train.stops.map {
                    CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng)
                })
                .stroke(
                    Color.arcBlue.opacity(0.85),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            ForEach(liveMarkers, id: \.0) { _, coordinate in
                Annotation("", coordinate: coordinate) {
                    Circle()
                        .fill(.white)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Color.arcBlue, lineWidth: 3).frame(width: 14, height: 14))
                        .shadow(color: Color.arcBlue.opacity(0.9), radius: 6)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .colorScheme(.dark)
    }
}

struct MyTripsView: View {
    @State private var query = ""
    // seeded by the -railly.onrails snapshot arg; false in normal launches
    @State private var onRailsOnly = UserDefaults.standard.bool(forKey: "railly.onrails")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // The map redraws on a slow tick; rows tick every second.
                    TimelineView(.periodic(from: .now, by: 30)) { ctx in
                        NetworkMapView(now: ctx.date)
                            .frame(height: 320)
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
            }
            .scrollIndicators(.hidden)
            .refreshable {
                // the network is simulated locally; the gesture is the point
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            .background(Color.black)
            .ignoresSafeArea(edges: .top)
            .navigationDestination(for: String.self) { id in
                TripDetailView(id: id)
            }
        }
    }

    /// The header menu and search field must live OUTSIDE the per-second
    /// TimelineView: rebuilding an open Menu's anchor every tick dismisses
    /// the menu before a selection can land. Only the rows tick.
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
                Text("Y")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.subGray)
                    .frame(width: 42, height: 42)
                    .background(Color.fillGray, in: Circle())
            }
            .padding(.top, 22)

            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.fadedGray)
                TextField("Search to add trains", text: $query)
                    .font(.system(size: 17))
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
            .padding(.top, 14)

            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                let q = query.trimmingCharacters(in: .whitespaces).lowercased()
                Group {
                    if q.isEmpty {
                        sections(now: ctx.date)
                    } else {
                        searchResults(q, now: ctx.date)
                    }
                }
                .animation(.snappy(duration: 0.35), value: onRailsOnly)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private func sections(now: Date) -> some View {
        let trips = getMyTrips(now)
        let current = (trips.live + trips.upcoming).filter {
            !onRailsOnly || $0.live.phase == .enroute
        }

        if current.isEmpty {
            Text("Nothing on rails right now.")
                .font(.system(size: 16))
                .foregroundStyle(Color.fadedGray)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        }
        ForEach(Array(current.enumerated()), id: \.element.id) { i, trip in
            NavigationLink(value: trip.id) {
                TripRowView(trip: trip, now: now, divider: i < current.count - 1)
            }
            .buttonStyle(.pressableRow)
        }

        if !trips.past.isEmpty && !onRailsOnly {
            Text("Past Trips")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.inkline)
                .padding(.top, 22)
            ForEach(Array(trips.past.enumerated()), id: \.element.id) { i, trip in
                NavigationLink(value: trip.id) {
                    TripRowView(trip: trip, now: now, divider: i < trips.past.count - 1)
                }
                .buttonStyle(.pressableRow)
            }
        }
    }

    @ViewBuilder
    private func searchResults(_ q: String, now: Date) -> some View {
        let matches = allTrains.filter { train in
            train.number.contains(q)
                || train.name.lowercased().contains(q)
                || train.stops.contains {
                    $0.name.lowercased().contains(q) || $0.code.lowercased() == q
                }
        }
        if matches.isEmpty {
            Text("No trains match “\(query)”")
                .font(.system(size: 16))
                .foregroundStyle(Color.fadedGray)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else {
            ForEach(Array(matches.enumerated()), id: \.element.number) { i, train in
                let trip = liveTripFor(train, now)
                NavigationLink(value: trip.id) {
                    TripRowView(trip: trip, now: now, divider: i < matches.count - 1)
                }
                .buttonStyle(.pressableRow)
            }
        }
    }
}
