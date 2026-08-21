import ActivityKit
import SwiftUI
import WidgetKit

// The widget extension can't see the app's Theme.swift, so it carries its own
// tiny palette — the same Flighty values used across Railly.
private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
    static let laOnTime = Color(hex: 0x30D158)
    static let laLate = Color(hex: 0xFF453A)
    static let laGate = Color(hex: 0xFFD426)
    static let laSub = Color(hex: 0x9A9A9E)
}

private func statusColor(_ s: TrainActivityAttributes.ContentState) -> Color {
    // charting owns its own cluster: amber while the fate is still open,
    // green once the chart prepares and the berth is confirmed
    if s.phase == .charting { return s.chartPrepared ? .laOnTime : .laGate }
    return s.isLate ? .laLate : .laOnTime
}

/// A stylized route-elevation line — Railly's answer to Flighty's terrain
/// silhouette. The elapsed portion is drawn in the status color, the rest in
/// grey, with a train dot at the current position.
private struct ProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.14))
                Capsule().fill(color)
                    .frame(width: max(3, geo.size.width * min(1, max(0, progress))))
            }
        }
        .frame(height: 4)
    }
}

/// The full lock-screen / banner card (also the Dynamic Island expanded body).
/// Internal rather than private so a harness can render and measure it: the
/// lock-screen height budget is not something you can eyeball from a simulator
/// (there is no way to reach its lock screen headlessly), and guessing at it is
/// what let the next-stop line ship clipped.
struct LockScreenCard: View {
    let attr: TrainActivityAttributes
    let state: TrainActivityAttributes.ContentState

    private var a11yLabel: String {
        let route = "\(attr.trainNumber), \(attr.originCity) to \(attr.destinationCity)"
        let delay = state.isLate ? "\(state.delayText.lowercased())" : "on time"
        switch state.phase {
        case .charting:
            return state.chartPrepared
                ? "\(route). Confirmed berth \(state.berthAllotment)."
                : "\(route). Waitlist \(state.waitlistStatus), chart not yet prepared."
        case .preDeparture:
            let pf = state.platform.map { ", platform \($0)" } ?? ""
            return "\(route). Departs \(delay)\(pf)."
        case .enRoute:
            return "\(route). Running \(delay), next stop \(state.nextStopName)."
        case .arrived:
            return "\(route). Arrived at \(attr.destinationCity), \(delay)."
        }
    }

    var body: some View {
        let tint = statusColor(state)
        // iOS gives the lock-screen presentation a fixed height and *clips*
        // anything taller — which is how the next-stop line ended up sliced in
        // half. The budget also differs across devices, so rather than tune the
        // card to one magic number, offer three densities and let SwiftUI take
        // the richest one that actually fits.
        ViewThatFits(in: .vertical) {
            card(tint: tint, detail: .full)
            card(tint: tint, detail: .compact)
            card(tint: tint, detail: .minimal)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .activityBackgroundTint(Color(hex: 0x161719))
        .activitySystemActionForegroundColor(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11yLabel)
    }

    /// One line of the bottom zone: a headline on the left, a stat on the
    /// right, neither allowed to wrap or push the other off the card.
    private func infoRow(lead: Text, leadSize: CGFloat,
                         trail: Text, trailSize: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            lead
                .font(.system(size: leadSize, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            trail
                .font(.system(size: trailSize, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .layoutPriority(1)
        }
    }

    /// How much of the card survives at the height iOS actually allowed.
    enum Detail {
        case full, compact, minimal
    }

    func card(tint: Color, detail: Detail) -> some View {
        VStack(spacing: detail == .full ? 7 : 5) {
            header
            routeRow(tint: tint)
            bottomZone(tint: tint, detail: detail)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(attr.monogram)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color(hex: attr.liveryHex), in: Circle())
            Text(attr.trainNumber)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.laSub)
                .monospacedDigit()
            Spacer()
            Text("RAILLY")
                .font(.system(size: 11, weight: .bold))
                .kerning(1.5)
                .foregroundStyle(Color.laSub)
        }
    }

    private func routeRow(tint: Color) -> some View {
        HStack(alignment: .center) {
            endBlock(code: attr.originCode, time: state.departDate,
                     tint: tint, align: .leading)
            Spacer(minLength: 8)
            VStack(spacing: 3) {
                Image(systemName: "train.side.front.car")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.laSub)
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { _ in
                        Circle().fill(Color.laSub.opacity(0.5)).frame(width: 2.5, height: 2.5)
                    }
                }
            }
            Spacer(minLength: 8)
            endBlock(code: attr.destinationCode, time: state.arriveDate,
                     tint: tint, align: .trailing)
        }
    }

    private func endBlock(code: String, time: Date, tint: Color,
                          align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 1) {
            Text(code)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
            Text(time, format: .dateTime.hour().minute())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
    }

    private func bottomZone(tint: Color, detail: Detail) -> some View {
        VStack(spacing: detail == .full ? 6 : 4) {
            // En route the progress bar already separates the zones; the rule
            // is pure cost there, and its 8pt is what the next-stop line needs.
            if detail != .minimal && state.phase != .enRoute {
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
            }
            phaseContent(tint: tint, detail: detail)
        }
    }

    @ViewBuilder
    private func phaseContent(tint: Color, detail: Detail) -> some View {
        switch state.phase {
        case .charting:
            if state.chartPrepared {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.laOnTime)
                            Text("You're CNF")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text(state.berthAllotment)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.laOnTime)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(timerInterval: Date()...max(state.departDate, Date().addingTimeInterval(60)),
                             countsDown: true)
                            .font(.system(size: 15, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 88)
                        Text("TO DEPARTURE")
                            .font(.system(size: 9, weight: .semibold))
                            .kerning(0.4)
                            .foregroundStyle(Color.laSub)
                    }
                }
            } else {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        (Text("Chart prepares in ").foregroundStyle(.white)
                            + Text(timerInterval: Date()...max(state.chartDate, Date().addingTimeInterval(60)),
                                   countsDown: true).foregroundStyle(tint))
                            .font(.system(size: 16, weight: .bold))
                            .monospacedDigit()
                        Text("Current status \(state.waitlistStatus)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.laSub)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(state.waitlistStatus)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 9).padding(.vertical, 6)
                        .background(Color.laGate, in: RoundedRectangle(cornerRadius: 9))
                }
            }
        case .preDeparture:
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    (Text("Departs in ").foregroundStyle(.white)
                        + Text(timerInterval: Date()...max(state.departDate, Date().addingTimeInterval(60)),
                               countsDown: true)
                            .foregroundStyle(tint))
                        .font(.system(size: 16, weight: .bold))
                        .monospacedDigit()
                    Text(state.statusLine)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.laSub)
                        .lineLimit(1)
                }
                Spacer()
                if let pf = state.platform {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .black))
                        Text("PF \(pf)").font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 9).padding(.vertical, 6)
                    .background(Color.laGate, in: RoundedRectangle(cornerRadius: 9))
                }
            }
        case .enRoute:
            if detail != .minimal {
                ProgressBar(progress: state.progress, color: tint)
            }
            // Which halt is next, and how long until it, is the line people
            // actually plan around ("can I get off for chai at Dharmapuri?").
            // It is therefore the last thing dropped, not the first: the full
            // card leads with the arrival countdown, but every smaller variant
            // keeps the next stop.
            if detail == .full {
                infoRow(
                    lead: Text("Arriving in ").foregroundStyle(.white)
                        + Text(state.arriveDate, style: .relative).foregroundStyle(tint),
                    leadSize: 15,
                    trail: Text(state.delayText).foregroundStyle(tint),
                    trailSize: 13)
                infoRow(
                    lead: Text("NEXT \(state.nextStopCode) · ").foregroundStyle(Color.laSub)
                        + Text(state.nextStopName.uppercased()).foregroundStyle(.white)
                        + Text(" in ").foregroundStyle(Color.laSub)
                        + Text(state.nextStopDate, style: .relative).foregroundStyle(.white),
                    leadSize: 11,
                    trail: Text("\(state.speedKmh) km/h").foregroundStyle(Color.laSub),
                    trailSize: 11)
            } else {
                infoRow(
                    lead: Text("\(state.nextStopCode) ").foregroundStyle(.white)
                        + Text("in ").foregroundStyle(Color.laSub)
                        + Text(state.nextStopDate, style: .relative).foregroundStyle(.white),
                    leadSize: 15,
                    trail: Text(state.delayText).foregroundStyle(tint),
                    trailSize: 13)
            }
        case .arrived:
            HStack {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.laOnTime)
                Text("Arrived at \(attr.destinationCity)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(state.delayText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
    }
}

struct TrainLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainActivityAttributes.self) { context in
            LockScreenCard(attr: context.attributes, state: context.state)
        } dynamicIsland: { context in
            let tint = statusColor(context.state)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    islandEnd(context.attributes.originCode,
                              context.state.departDate, tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    islandEnd(context.attributes.destinationCode,
                              context.state.arriveDate, tint)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 1) {
                        Image(systemName: "train.side.front.car")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.laSub)
                        Text(context.attributes.trainNumber)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.laSub)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.phase == .charting {
                        if context.state.chartPrepared {
                            HStack {
                                (Text("CNF · ").foregroundStyle(Color.laOnTime)
                                    + Text(context.state.berthAllotment).foregroundStyle(.white))
                                    .font(.system(size: 14, weight: .bold))
                                    .lineLimit(1)
                                Spacer()
                                Text(timerInterval: Date()...max(context.state.departDate, Date().addingTimeInterval(60)),
                                     countsDown: true)
                                    .font(.system(size: 12, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(Color.laSub)
                                    .frame(maxWidth: 66)
                            }
                        } else {
                            HStack {
                                (Text("Chart in ").foregroundStyle(.white)
                                    + Text(timerInterval: Date()...max(context.state.chartDate, Date().addingTimeInterval(60)),
                                           countsDown: true).foregroundStyle(tint))
                                    .font(.system(size: 14, weight: .bold))
                                    .monospacedDigit()
                                Spacer()
                                Text(context.state.waitlistStatus)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Color.laGate, in: Capsule())
                            }
                        }
                    } else if context.state.phase == .enRoute {
                        ProgressBar(progress: context.state.progress, color: tint)
                        VStack(spacing: 3) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                (Text("Arriving in ").foregroundStyle(.white)
                                    + Text(context.state.arriveDate, style: .relative).foregroundStyle(tint))
                                    .font(.system(size: 14, weight: .bold))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Spacer(minLength: 4)
                                Text(context.state.delayText)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(tint)
                                    .lineLimit(1)
                                    .layoutPriority(1)
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                (Text("NEXT \(context.state.nextStopCode) ").foregroundStyle(Color.laSub)
                                    + Text("in ").foregroundStyle(Color.laSub)
                                    + Text(context.state.nextStopDate, style: .relative).foregroundStyle(.white))
                                    .font(.system(size: 11, weight: .semibold))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Spacer(minLength: 4)
                                Text("\(context.state.speedKmh) km/h")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.laSub)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .layoutPriority(1)
                            }
                        }
                    } else if context.state.phase == .preDeparture {
                        HStack {
                            (Text("Departs in ").foregroundStyle(.white)
                                + Text(timerInterval: Date()...max(context.state.departDate, Date().addingTimeInterval(60)),
                                       countsDown: true)
                                    .foregroundStyle(tint))
                                .font(.system(size: 14, weight: .bold))
                                .monospacedDigit()
                            Spacer()
                            if let pf = context.state.platform {
                                Text("PF \(pf)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Color.laGate, in: Capsule())
                            }
                        }
                    } else {
                        Text("Arrived at \(context.attributes.destinationCity)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            } compactLeading: {
                Image(systemName: "train.side.front.car")
                    .foregroundStyle(tint)
            } compactTrailing: {
                // the single glance value: charting outcome, then platform
                // pre-departure, else the live delay (a full HH:MM:SS timer
                // overflows this slot)
                if context.state.phase == .charting {
                    if context.state.chartPrepared {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.laOnTime)
                    } else {
                        Text(context.state.waitlistStatus)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.laGate)
                    }
                } else if let pf = context.state.platform, context.state.phase == .preDeparture {
                    Text("PF \(pf)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color.laGate, in: Capsule())
                } else {
                    Text(context.state.delayShort)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(tint)
                }
            } minimal: {
                Image(systemName: "train.side.front.car")
                    .foregroundStyle(tint)
            }
            .keylineTint(tint)
            .widgetURL(URL(string: "railly://trip/\(context.attributes.trainNumber)"))
        }
    }

    private func islandEnd(_ code: String, _ time: Date, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(code).font(.system(size: 15, weight: .heavy)).foregroundStyle(.white)
            Text(time, format: .dateTime.hour().minute())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
    }
}
