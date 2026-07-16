import SwiftUI
import WidgetKit

/// The widget extension's entry point. Exactly one @main WidgetBundle; it
/// offers only the Live Activity (no home-screen timeline widgets yet).
@main
struct RaillyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TrainLiveActivity()
    }
}
