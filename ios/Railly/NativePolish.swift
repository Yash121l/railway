import SwiftUI

/// Native-feel affordances. iOS-only modifiers are guarded so the whole
/// target still typechecks against the macOS SDK on a CLT-only Mac
/// (see topics/swift-port-without-xcode).

/// UITableView-style touch feedback: rows flash the fill gray and settle
/// back, instead of the inert `.plain` default.
struct PressableRow: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.fillGray)
                    .padding(.horizontal, -10)
                    .opacity(configuration.isPressed ? 0.85 : 0)
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableRow {
    static var pressableRow: PressableRow { PressableRow() }
}

extension View {
    /// Inline title with the bar itself hidden, so the map bleeds behind
    /// the back button — Flighty's detail-screen treatment.
    func mapDetailBar(title: String) -> some View {
        #if os(iOS)
        return navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        #else
        return navigationTitle(title)
        #endif
    }

    /// Search-field manners: no caps, no autocorrect, a Search return key.
    func searchFieldStyle() -> some View {
        #if os(iOS)
        return autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
        #else
        return autocorrectionDisabled()
            .submitLabel(.search)
        #endif
    }

    /// Ticking numerals roll digit-by-digit instead of snapping.
    func rollingNumbers(value: String) -> some View {
        contentTransition(.numericText())
            .animation(.snappy(duration: 0.4), value: value)
    }
}
