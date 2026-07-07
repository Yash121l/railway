import SwiftUI

/// One journey, one dense line — the Dec 2025 Flighty row anatomy.

/// Flighty's rule: ONE status color per trip, not per endpoint. Green when
/// running on time, red when late (or completed rows, muted), and neutral
/// gray circles with plain dark times for far-future scheduled trips.
private enum Tone {
    case neutral, ontime, late, muted

    var circleFill: Color {
        switch self {
        case .neutral: return Color(hex: 0xD8D8DC)
        case .ontime: return .onTime
        case .late: return .lateRed
        case .muted: return .fadedGray
        }
    }

    var codeColor: Color {
        switch self {
        case .neutral: return Color(hex: 0x8E8E93)
        case .muted: return Color.fadedGray.opacity(0.8)
        default: return circleFill.opacity(0.8)
        }
    }

    var timeColor: Color {
        switch self {
        case .neutral: return .inkline
        default: return circleFill
        }
    }
}

/// The dep/arr cell — the whole cluster inherits the trip's status color.
private struct TimeCell: View {
    let isDeparture: Bool
    let code: String
    let time: Date
    let tone: Tone
    var nextDay = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isDeparture ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(tone.circleFill, in: Circle())
            Text(code)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tone.codeColor)
            (Text(fmtTime(time)).font(.system(size: 16, weight: .bold))
                + Text(nextDay ? "+1" : "")
                .font(.system(size: 10, weight: .bold))
                .baselineOffset(6))
                .foregroundStyle(tone.timeColor)
                .monospacedDigit()
        }
    }
}

/// Left rail: huge countdown, or the ON RAILS / ARRIVED circle.
private struct Rail: View {
    let trip: HeldTrip
    let now: Date

    var body: some View {
        VStack(spacing: 5) {
            switch trip.live.phase {
            case .enroute, .boarding:
                Image(systemName: "tram.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.inkline)
                    .frame(width: 44, height: 44)
                    .background(Color.fillGray, in: Circle())
                caption(trip.live.phase == .enroute ? "ON RAILS" : "BOARDING")
            case .arrived:
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.subGray)
                    .frame(width: 44, height: 44)
                    .background(Color.fillGray, in: Circle())
                caption("ARRIVED")
            case .scheduled:
                let mins = max(0, trip.live.stopTimings[0].depEst.timeIntervalSince(now) / 60)
                if mins >= 48 * 60 {
                    let days = Int((mins / (24 * 60)).rounded())
                    big(String(days))
                    caption(days == 1 ? "DAY" : "DAYS")
                } else if mins >= 60 {
                    big("\(Int(mins / 60))h")
                    caption("\(Int(mins.truncatingRemainder(dividingBy: 60))) MINUTES")
                } else {
                    big(String(max(1, Int(mins.rounded()))))
                    caption("MINUTES")
                }
            }
        }
        .frame(width: 74)
    }

    private func big(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 30, weight: .heavy))
            .foregroundStyle(Color.inkline)
            .monospacedDigit()
            .rollingNumbers(value: s)
    }

    private func caption(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 9, weight: .bold))
            .kerning(0.8)
            .foregroundStyle(Color.fadedGray)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

private struct StatusText: View {
    let trip: HeldTrip
    let now: Date

    var body: some View {
        let live = trip.live
        let late = live.delayMin > 5
        switch live.phase {
        case .enroute:
            // gray regular label + colored semibold value, flighty-style
            let arrLate = live.stopTimings[live.stopTimings.count - 1].delayMin > 5
            let remaining = fmtDuration(max(0, live.arrivesEst.timeIntervalSince(now) / 60))
            (Text("Arriving in ").foregroundStyle(Color.subGray)
                + Text(remaining)
                .foregroundStyle(arrLate ? Color.lateRed : Color.onTime)
                .fontWeight(.semibold))
                .font(.system(size: 14))
                .rollingNumbers(value: remaining)
        case .arrived:
            Text(fmtDay(live.arrivesEst))
                .font(.system(size: 14))
                .foregroundStyle(Color.fadedGray)
        case .boarding, .scheduled:
            if live.departsAt.timeIntervalSince(now) > 24 * 3600 {
                Text(fmtDay(live.departsAt))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.subGray)
            } else {
                (Text("Departs ").foregroundStyle(Color.subGray)
                    + Text(late ? "\(live.delayMin)m late" : "On Time")
                    .foregroundStyle(late ? Color.lateRed : Color.onTime)
                    .fontWeight(.semibold))
                    .font(.system(size: 14))
            }
        }
    }
}

struct TripRowView: View {
    let trip: HeldTrip
    let now: Date
    var divider = true

    var body: some View {
        let train = trip.train
        let depT = trip.live.stopTimings[0]
        let arrT = trip.live.stopTimings[train.stops.count - 1]
        let isPast = trip.live.phase == .arrived
        // one tone for the whole row: muted past, neutral far-future,
        // otherwise green/red by the destination forecast
        let farFuture = trip.live.departsAt.timeIntervalSince(now) > 24 * 3600
            && trip.live.phase == .scheduled
        let tone: Tone = isPast ? .muted
            : farFuture ? .neutral
            : arrT.delayMin > 5 ? .late : .ontime
        let depTone = tone
        let arrTone = tone

        HStack(alignment: .top, spacing: 8) {
            Rail(trip: trip, now: now)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    TrainMark(category: train.category)
                    Text(train.number)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.subGray)
                        .monospacedDigit()
                    Spacer()
                    StatusText(trip: trip, now: now)
                }
                (Text(cityFor(train.origin.code, train.origin.name)).fontWeight(.bold)
                    + Text(" to ").foregroundStyle(Color.subGray)
                    + Text(cityFor(train.destination.code, train.destination.name)).fontWeight(.bold))
                    .font(.system(size: 20))
                    .foregroundStyle(Color.inkline)
                    .lineLimit(1)
                HStack {
                    TimeCell(isDeparture: true, code: train.origin.code,
                             time: depT.depEst, tone: depTone)
                    Spacer()
                    TimeCell(isDeparture: false, code: train.destination.code,
                             time: arrT.arrEst, tone: arrTone,
                             nextDay: istDateISO(arrT.arrEst) != istDateISO(depT.depEst))
                }
                if divider {
                    Rectangle().fill(Color.hairline).frame(height: 1).padding(.top, 8)
                }
            }
        }
        .padding(.top, 12)
        .opacity(isPast ? 0.6 : 1)
    }
}
