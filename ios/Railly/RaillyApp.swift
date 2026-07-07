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
    var body: some View {
        TabView {
            MyTripsView()
                .tabItem { Label("My Trips", systemImage: "tram.fill") }
            TrackView()
                .tabItem { Label("Track", systemImage: "dot.radiowaves.left.and.right") }
            LogbookView()
                .tabItem { Label("Logbook", systemImage: "book.closed") }
        }
        .tint(Color.inkline)
    }
}
