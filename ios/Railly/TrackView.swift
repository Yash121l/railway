import SwiftUI

/// The whole network as a one-line-per-train live board.
struct TrackView: View {
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
                let trips = allTrains
                    .map { liveTripFor($0, now) }
                    .sorted { a, b in
                        let ra = phaseRank(a.live.phase)
                        let rb = phaseRank(b.live.phase)
                        if ra != rb { return ra < rb }
                        return a.live.departsAt < b.live.departsAt
                    }
                let running = trips.filter { $0.live.phase == .enroute }.count

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
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
                        Text("Every train Railly is watching right now.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.subGray)
                            .padding(.top, 2)

                        ForEach(Array(trips.enumerated()), id: \.element.id) { i, trip in
                            NavigationLink(value: trip.id) {
                                TripRowView(trip: trip, now: now, divider: i < trips.count - 1)
                            }
                            .buttonStyle(.pressableRow)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
                .background(Color.white)
            }
            .navigationDestination(for: String.self) { id in
                TripDetailView(id: id)
            }
        }
    }
}
