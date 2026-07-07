import SwiftUI

@main
struct RaillyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    // Snapshot hooks: `-railly.tab 2` opens a tab, `-railly.detail 12951`
    // boots straight into that train's live trip. Absent in normal launches.
    @State private var tab = UserDefaults.standard.integer(forKey: "railly.tab")
    private let detailTrain = UserDefaults.standard.string(forKey: "railly.detail")

    var body: some View {
        if let no = detailTrain, let train = allTrains.first(where: { $0.number == no }) {
            NavigationStack {
                TripDetailView(id: liveTripFor(train, Date()).id)
            }
        } else {
            tabs
        }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            MyTripsView()
                .tabItem { Label("My Trips", systemImage: "tram.fill") }
                .tag(0)
            TrackView()
                .tabItem { Label("Track", systemImage: "dot.radiowaves.left.and.right") }
                .tag(1)
            LogbookView()
                .tabItem { Label("Logbook", systemImage: "book.closed") }
                .tag(2)
        }
        .tint(Color.inkline)
        .sensoryFeedback(.selection, trigger: tab)
    }
}
