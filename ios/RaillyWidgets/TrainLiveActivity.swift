import ActivityKit
import SwiftUI
import WidgetKit

// The extension can't see DesignSystem.swift, so it mirrors the few tokens it
// needs. The card is dark, so the status colors are the brighter dark-surface
// variants of DS.onTime / DS.late; amber stays DS.platform.
private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
    static let laCard = Color(hex: 0x1C1C1E)
    static let laOnTime = Color(hex: 0x32D74B)
    static let laLate = Color(hex: 0xFF453A)
    static let laAmber = Color(hex: 0xFFCC00)
    static let laAmberInk = Color(hex: 0x1A1400)
    static let laSub = Color(hex: 0x98989F)
    static let laTrack = Color.white.opacity(0.16)
}

private typealias LAState = TrainActivityAttributes.ContentState

private let istClock: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.timeZone = TimeZone(identifier: "Asia/Kolkata")
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

private let istCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
    return cal
}()

private func delayCaption(_ minutes: Int) -> String {
    minutes > 5 ? "\(LAState.durationText(minutes: minutes)) late" : "On time"
}

private extension LAState {
    /// One color per journey, decided by the arrival delay. Charting owns its
    /// own pair: amber while the ticket's fate is open, green once confirmed.
    var tint: Color {
        if phase == .charting { return chartPrepared ? .laOnTime : .laAmber }
        return isLate ? .laLate : .laOnTime
    }

    var departTint: Color {
        if phase == .charting { return tint }
        return departDelayMinutes > 5 ? .laLate : .laOnTime
    }

    /// "+1" when the run lands on a later IST day than it leaves.
    var arrivalDayOffset: Int {
        let from = istCalendar.startOfDay(for: departDate)
        let to = istCalendar.startOfDay(for: arriveDate)
        return max(0, istCalendar.dateComponents([.day], from: from, to: to).day ?? 0)
    }
}

/// On the last leg the next stop is the destination itself.
private func onFinalLeg(_ attr: TrainActivityAttributes, _ state: LAState) -> Bool {
    state.nextStopCode == attr.destinationCode
}

/// "in 1 hr, 19 min" while the activity is fresh. Once iOS marks it stale the
/// app has stopped pushing, so a countdown could run past a departure that
/// never got reported; fall back to the clock time it was aiming at.
private func when(_ date: Date, stale: Bool) -> Text {
    stale ? Text("at \(istClock.string(from: date))") : Text("in \(Text(date, style: .relative))")
}

// MARK: - Parts

private struct Monogram: View {
    let attr: TrainActivityAttributes
    var size: CGFloat = 20

    var body: some View {
        Text(attr.monogram)
            .font(.system(size: size * 0.45, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color(hex: attr.liveryHex), in: Circle())
    }
}

/// Honest-data label, mirroring the app's EstimateTag on a dark surface.
private struct SourcePill: View {
    let state: LAState
    let stale: Bool

    var body: some View {
        if stale {
            label("Not updating", icon: "pause.circle.fill", color: .laAmber)
        } else if state.isEstimate {
            label("Estimated", icon: "waveform.path.ecg", color: .laSub)
        }
    }

    private func label(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 8, weight: .bold))
            Text(text).font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .frame(height: 16)
        .background(Color.white.opacity(0.1), in: Capsule())
        .lineLimit(1)
        .fixedSize()
    }
}

private struct PlatformBadge: View {
    let text: String
    var arrow = true
    var size: CGFloat = 15

    var body: some View {
        HStack(spacing: 2) {
            if arrow {
                Image(systemName: "arrow.up.right").font(.system(size: size * 0.75, weight: .black))
            }
            Text(text).font(.system(size: size, weight: .heavy))
        }
        .foregroundStyle(Color.laAmberInk)
        .padding(.horizontal, size * 0.55)
        .padding(.vertical, size * 0.3)
        .background(Color.laAmber, in: RoundedRectangle(cornerRadius: size * 0.55, style: .continuous))
        .lineLimit(1)
        .fixedSize()
    }
}

/// The route as a rail: elapsed in the status color, the rest dim, a train
/// knob at the current fraction.
private struct RailTrack: View {
    let progress: Double
    let tint: Color
    var knob: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let p = min(1, max(0, progress))
            let x = knob / 2 + (geo.size.width - knob) * p
            ZStack(alignment: .leading) {
                Capsule().fill(Color.laTrack).frame(height: 3)
                Capsule().fill(tint).frame(width: max(3, x), height: 3)
                Circle().fill(Color.laSub).frame(width: 5, height: 5)
                    .position(x: geo.size.width - 2.5, y: geo.size.height / 2)
                Image(systemName: "train.side.front.car")
                    .font(.system(size: knob * 0.5, weight: .bold))
                    .foregroundStyle(Color.laCard)
                    .frame(width: knob, height: knob)
                    .background(tint, in: Circle())
                    .position(x: x, y: geo.size.height / 2)
            }
        }
        .frame(height: knob)
    }
}

/// "MMCT 17:00" with its status caption underneath; the arrival end mirrors it.
private struct RouteEnd: View {
    let code: String
    let time: Date
    var dayOffset = 0
    let tint: Color
    let caption: String?
    let trailing: Bool
    var codeSize: CGFloat = 20

    var body: some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                if trailing { clock }
                Text(code)
                    .font(.system(size: codeSize, weight: .heavy))
                    .foregroundStyle(.white)
                if !trailing { clock }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .layoutPriority(1)
            if let caption {
                Text(caption)
                    .font(.system(size: codeSize * 0.65, weight: .medium))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
    }

    private var clock: some View {
        let t = Text(istClock.string(from: time))
        let full = dayOffset > 0
            ? Text("\(t)\(Text("+\(dayOffset)").font(.system(size: codeSize * 0.5, weight: .bold)).baselineOffset(codeSize * 0.4))")
            : t
        return full
            .font(.system(size: codeSize, weight: .medium))
            .foregroundStyle(tint)
            .monospacedDigit()
    }
}

private struct RouteRow: View {
    let attr: TrainActivityAttributes
    let state: LAState
    let captions: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            RouteEnd(code: attr.originCode, time: state.departDate,
                     tint: state.departTint,
                     caption: captions ? delayCaption(state.departDelayMinutes) : nil,
                     trailing: false)
                .layoutPriority(1)
            HStack(spacing: 4) {
                dots
                Image(systemName: "train.side.front.car")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.laSub)
                dots
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            RouteEnd(code: attr.destinationCode, time: state.arriveDate,
                     dayOffset: state.arrivalDayOffset,
                     tint: state.tint,
                     caption: captions ? state.delayText : nil,
                     trailing: true)
                .layoutPriority(1)
        }
    }

    private var dots: some View {
        HStack(spacing: 4) {
            Circle().frame(width: 3, height: 3)
            Circle().frame(width: 3, height: 3)
        }
        .foregroundStyle(Color.laSub.opacity(0.6))
    }
}

// MARK: - Bottom zone

/// What the traveller needs next, per phase. The headline is the one line
/// every density keeps; the subline goes first when height runs out.
private struct PhaseLines: View {
    let attr: TrainActivityAttributes
    let state: LAState
    let stale: Bool
    let showSubline: Bool
    var headlineSize: CGFloat = 16

    var body: some View {
        if state.phase == .enRoute && onFinalLeg(attr, state) && showSubline {
            finalLegCountdown
        } else {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    headline
                        .font(.system(size: headlineSize, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if showSubline, let subline {
                        subline
                            .font(.system(size: headlineSize * 0.75, weight: .medium))
                            .foregroundStyle(Color.laSub)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                Spacer(minLength: 0)
                trailing
            }
        }
    }

    private var tint: Color { state.tint }

    private var nextStopWhen: Text {
        state.nextStopISO > 0 ? Text(" \(when(state.nextStopDate, stale: stale))") : Text("")
    }

    private var nextStopLine: Text {
        Text("\(Text("Next ").foregroundStyle(Color.laSub))\(Text(state.nextStopCode).foregroundStyle(.white))\(nextStopWhen.foregroundStyle(tint))")
    }

    private var headline: Text {
        switch state.phase {
        case .charting:
            if state.chartPrepared {
                return Text("\(Image(systemName: "checkmark.seal.fill")) \(Text("You're CNF").foregroundStyle(.white))\(Text(state.berthAllotment.isEmpty ? "" : " · \(state.berthAllotment)").foregroundStyle(tint))")
                    .foregroundStyle(tint)
            }
            return Text("\(Text("Chart ").foregroundStyle(.white))\(when(state.chartDate, stale: stale).foregroundStyle(tint))")
        case .preDeparture:
            return Text("\(Text("Departs ").foregroundStyle(.white))\(when(state.departDate, stale: stale).foregroundStyle(tint))")
        case .enRoute:
            if showSubline || onFinalLeg(attr, state) {
                return Text("\(Text("Arriving ").foregroundStyle(.white))\(when(state.arriveDate, stale: stale).foregroundStyle(tint))")
            }
            return nextStopLine
        case .arrived:
            return Text("\(Image(systemName: "checkmark.seal.fill")) \(Text("Arrived at \(attr.destinationCity)").foregroundStyle(.white))")
                .foregroundStyle(tint)
        }
    }

    private var subline: Text? {
        switch state.phase {
        case .charting:
            return Text("Departs \(when(state.departDate, stale: stale))")
        case .preDeparture:
            return state.statusLine.isEmpty ? nil : Text(state.statusLine)
        case .enRoute:
            return Text("Next \(Text(state.nextStopName).foregroundStyle(.white))\(nextStopWhen)")
        case .arrived:
            return nil
        }
    }

    @ViewBuilder
    private var trailing: some View {
        switch state.phase {
        case .charting:
            if !state.chartPrepared && !state.waitlistStatus.isEmpty {
                PlatformBadge(text: state.waitlistStatus, arrow: false, size: headlineSize * 0.9)
            }
        case .preDeparture:
            if let pf = state.platform {
                PlatformBadge(text: "PF \(pf)", size: headlineSize * 0.9)
            }
        case .enRoute:
            Text("\(state.speedKmh) km/h")
                .font(.system(size: headlineSize * 0.75, weight: .semibold))
                .foregroundStyle(Color.laSub)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
        case .arrived:
            Text(state.delayText)
                .font(.system(size: headlineSize * 0.8, weight: .semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .fixedSize()
        }
    }

    /// Flighty's centered countdown, used on the last leg, where a next-stop
    /// line would only repeat the destination.
    private var finalLegCountdown: some View {
        VStack(spacing: 0) {
            Group {
                if stale {
                    Text("Due \(istClock.string(from: state.arriveDate))")
                } else {
                    Text(state.arriveDate, style: .relative)
                }
            }
            .font(.system(size: headlineSize * 1.25, weight: .bold))
            .foregroundStyle(tint)
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            Text("UNTIL ARRIVAL AT \(attr.destinationCode)")
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.6)
                .foregroundStyle(Color.laSub)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Lock screen / banner

/// The lock-screen and banner card. Internal so a harness can render and
/// measure it: iOS clips this presentation at a device-dependent height, and
/// there is no headless way to see the real lock screen.
struct LockScreenCard: View {
    let attr: TrainActivityAttributes
    let state: TrainActivityAttributes.ContentState
    var isStale = false

    /// How much of the card survives the height iOS allows. Every density
    /// keeps the header (it carries the Estimated label), the route, and the
    /// phase headline.
    enum Detail {
        case full, compact, minimal
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            card(.full)
            card(.compact)
            card(.minimal)
        }
        .activityBackgroundTint(Color.laCard)
        .activitySystemActionForegroundColor(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11yLabel)
    }

    func card(_ detail: Detail) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: detail == .minimal ? 4 : 7) {
                header
                RouteRow(attr: attr, state: state, captions: detail != .minimal)
            }
            .padding(.horizontal, 16)
            .padding(.top, detail == .minimal ? 10 : 12)
            .padding(.bottom, detail == .minimal ? 6 : 10)
            .background(
                LinearGradient(colors: [state.tint.opacity(0), state.tint.opacity(0.24)],
                               startPoint: .top, endPoint: .bottom)
            )
            seam(detail)
            PhaseLines(attr: attr, state: state, stale: isStale,
                       showSubline: detail == .full)
                .padding(.horizontal, 16)
                .padding(.top, detail == .minimal ? 6 : 9)
                .padding(.bottom, detail == .minimal ? 9 : 11)
        }
    }

    private var header: some View {
        HStack(spacing: 7) {
            Monogram(attr: attr)
            Text(attr.trainNumber)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.laSub)
                .monospacedDigit()
            SourcePill(state: state, stale: isStale)
            Spacer(minLength: 4)
            Text("RAILLY")
                .font(.system(size: 12, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(Color.laSub)
        }
        .lineLimit(1)
    }

    /// En route the seam between the zones is the rail itself; otherwise a
    /// hairline, as on Flighty's card.
    @ViewBuilder
    private func seam(_ detail: Detail) -> some View {
        if state.phase == .enRoute && detail != .minimal {
            RailTrack(progress: state.progress, tint: state.tint, knob: 12)
                .padding(.horizontal, 16)
        } else {
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }

    private var a11yLabel: String {
        let route = "Train \(attr.trainNumber), \(attr.originCity) to \(attr.destinationCity)"
        let est = state.isEstimate ? " Times are estimated." : ""
        switch state.phase {
        case .charting:
            return state.chartPrepared
                ? "\(route). Confirmed, \(state.berthAllotment).\(est)"
                : "\(route). \(state.waitlistStatus), chart not yet prepared.\(est)"
        case .preDeparture:
            let pf = state.platform.map { ", platform \($0)" } ?? ""
            return "\(route). Departs \(istClock.string(from: state.departDate)), \(delayCaption(state.departDelayMinutes).lowercased())\(pf).\(est)"
        case .enRoute:
            return "\(route). Running \(state.delayText.lowercased()), next stop \(state.nextStopName), arrives \(istClock.string(from: state.arriveDate)).\(est)"
        case .arrived:
            return "\(route). Arrived at \(attr.destinationCity), \(state.delayText.lowercased()).\(est)"
        }
    }
}

// MARK: - Dynamic Island

/// Compact/minimal glyph: a status-tinted disc before departure, a progress
/// ring once the train is moving.
private struct IslandGlyph: View {
    let state: LAState

    var body: some View {
        ZStack {
            if state.phase == .enRoute {
                Circle().stroke(state.tint.opacity(0.3), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: min(1, max(0.02, state.progress)))
                    .stroke(state.tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "train.side.front.car")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Circle().fill(state.tint)
                Image(systemName: state.phase == .arrived ? "checkmark" : "train.side.front.car")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.laCard)
            }
        }
        .frame(width: 22, height: 22)
    }
}

struct TrainLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainActivityAttributes.self) { context in
            LockScreenCard(attr: context.attributes, state: context.state,
                           isStale: context.isStale)
        } dynamicIsland: { context in
            let attr = context.attributes
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RouteEnd(code: attr.originCode, time: state.departDate,
                             tint: state.departTint,
                             caption: delayCaption(state.departDelayMinutes),
                             trailing: false, codeSize: 17)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    RouteEnd(code: attr.destinationCode, time: state.arriveDate,
                             dayOffset: state.arrivalDayOffset,
                             tint: state.tint, caption: state.delayText,
                             trailing: true, codeSize: 17)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 3) {
                        HStack(spacing: 5) {
                            Monogram(attr: attr, size: 16)
                            Text(attr.trainNumber)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.laSub)
                                .monospacedDigit()
                        }
                        SourcePill(state: state, stale: context.isStale)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        if state.phase == .enRoute {
                            RailTrack(progress: state.progress, tint: state.tint, knob: 14)
                        }
                        PhaseLines(attr: attr, state: state, stale: context.isStale,
                                   showSubline: state.phase == .enRoute && !onFinalLeg(attr, state),
                                   headlineSize: 15)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                IslandGlyph(state: state)
            } compactTrailing: {
                compactValue(state)
            } minimal: {
                IslandGlyph(state: state)
            }
            .keylineTint(state.tint)
            .widgetURL(URL(string: "railly://trip/\(attr.trainNumber)"))
        }
    }

    /// The one glance value: the ticket's fate while charting, the platform
    /// before departure, the arrival delay after.
    @ViewBuilder
    private func compactValue(_ state: LAState) -> some View {
        switch state.phase {
        case .charting:
            if state.chartPrepared {
                Text("CNF")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.laOnTime)
            } else {
                Text(state.waitlistStatus)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.laAmber)
                    .lineLimit(1)
            }
        case .preDeparture:
            if let pf = state.platform {
                PlatformBadge(text: "PF \(pf)", arrow: false, size: 12)
            } else {
                Text(delayCaption(state.departDelayMinutes))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(state.departTint)
            }
        case .enRoute, .arrived:
            Text(state.delayShort)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(state.tint)
                .monospacedDigit()
        }
    }
}
