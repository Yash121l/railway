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
    @State private var tab = 0

    var body: some View {
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
