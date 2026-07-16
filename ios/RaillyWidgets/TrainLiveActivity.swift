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
private struct RouteProfile: View {
    let progress: Double
    let color: Color

    private func shape(_ w: CGFloat, _ h: CGFloat) -> Path {
        // gentle depart-climb-cruise-arrive profile
        Path { p in
            p.move(to: CGPoint(x: 0, y: h * 0.82))
            p.addCurve(to: CGPoint(x: w * 0.28, y: h * 0.30),
                       control1: CGPoint(x: w * 0.10, y: h * 0.82),
                       control2: CGPoint(x: w * 0.18, y: h * 0.30))
            p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.30))
            p.addCurve(to: CGPoint(x: w, y: h * 0.82),
                       control1: CGPoint(x: w * 0.82, y: h * 0.30),
                       control2: CGPoint(x: w * 0.90, y: h * 0.82))
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let path = shape(w, h)
            ZStack(alignment: .leading) {
                path.stroke(Color.white.opacity(0.18),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                path
                    .trim(from: 0, to: max(0.001, min(1, progress)))
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                // origin + destination station ticks
                Circle().fill(Color.white.opacity(0.5)).frame(width: 5, height: 5)
                    .position(x: 1, y: h * 0.82)
                Circle().fill(Color.white.opacity(0.5)).frame(width: 5, height: 5)
                    .position(x: w - 1, y: h * 0.82)
            }
        }
        .frame(height: 26)
    }
}

/// The full lock-screen / banner card (also the Dynamic Island expanded body).
private struct LockScreenCard: View {
    let context: ActivityViewContext<TrainActivityAttributes>

    private var attr: TrainActivityAttributes { context.attributes }
    private var state: TrainActivityAttributes.ContentState { context.state }

    private var a11yLabel: String {
        let route = "\(attr.trainNumber), \(attr.originCity) to \(attr.destinationCity)"
        let delay = state.isLate ? "\(state.delayMinutes) minutes late" : "on time"
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
        VStack(spacing: 11) {
            header
            routeRow(tint: tint)
            bottomZone(tint: tint)
        }
        .padding(15)
        .activityBackgroundTint(Color(hex: 0x161719))
        .activitySystemActionForegroundColor(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11yLabel)
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
                .font(.system(size: 25, weight: .heavy))
                .foregroundStyle(.white)
            Text(time, format: .dateTime.hour().minute())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func bottomZone(tint: Color) -> some View {
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)

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
                        + Text(timerInterval: Date()...state.departDate, countsDown: true)
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
            RouteProfile(progress: state.progress, color: tint)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    (Text("Arriving in ").foregroundStyle(.white)
                        + Text(timerInterval: Date()...max(state.arriveDate, Date().addingTimeInterval(60)),
                               countsDown: true).foregroundStyle(tint))
                        .font(.system(size: 17, weight: .bold))
                        .monospacedDigit()
                    Text("NEXT \(state.nextStopCode) · \(state.nextStopName)".uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(0.4)
                        .foregroundStyle(Color.laSub)
                        .lineLimit(1)
                }
                Spacer()
                Text(state.isLate ? "\(state.delayMinutes)m late" : "On time")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }
        case .arrived:
            HStack {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.laOnTime)
                Text("Arrived at \(attr.destinationCity)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(state.isLate ? "\(state.delayMinutes)m late" : "On time")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
    }
}

struct TrainLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainActivityAttributes.self) { context in
            LockScreenCard(context: context)
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
                        RouteProfile(progress: context.state.progress, color: tint)
                        HStack {
                            (Text("Arriving in ").foregroundStyle(.white)
                                + Text(timerInterval: Date()...max(context.state.arriveDate, Date().addingTimeInterval(60)),
                                       countsDown: true).foregroundStyle(tint))
                                .font(.system(size: 14, weight: .bold))
                                .monospacedDigit()
                            Spacer()
                            Text("NEXT \(context.state.nextStopCode)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.laSub)
                        }
                    } else if context.state.phase == .preDeparture {
                        HStack {
                            (Text("Departs in ").foregroundStyle(.white)
                                + Text(timerInterval: Date()...context.state.departDate, countsDown: true)
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
                    Text(context.state.isLate ? "+\(context.state.delayMinutes)m" : "On time")
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
