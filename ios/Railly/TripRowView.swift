import SwiftUI

/// One journey at a glance, Flighty's row anatomy: a countdown rail on the
/// left, then train + status, the route in words, and both endpoints in the
/// trip's one status color.
///
/// Honesty: without a live feed every delay is a timetable projection, so the
/// endpoint times fall back to the published timetable and any status claim
/// wears an EST mark.
struct TripRowView: View {
    let trip: HeldTrip
    let now: Date
    var divider = true

    @Environment(\.displayScale) private var displayScale

    private static let railWidth: CGFloat = 72
    private static let routeTitleSize: CGFloat = 18

    var body: some View {
        let train = trip.train
        let tone = trip.tone(now)
        let real = feedBacked
        let dep = trip.live.stopTimings[0]
        let arr = trip.live.stopTimings[trip.live.stopTimings.count - 1]
        let depTime = real ? dep.depEst : dep.depSched
        let arrTime = real ? arr.arrEst : arr.arrSched
        let nextDay = isNextDay(arrTime, after: depTime)
        let status = statusLine

        HStack(alignment: .center, spacing: 12) {
            RowRail(trip: trip, now: now, departure: depTime)
                .frame(width: Self.railWidth)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    TrainMark(category: train.category, size: 18)
                    Text(train.number)
                        .font(.dsSubhead.weight(.semibold))
                        .foregroundStyle(DS.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .layoutPriority(1)
                    Spacer(minLength: 6)
                    RowStatus(line: status, tone: tone, estimated: !real)
                }

                (Text(cityFor(train.origin.code, train.origin.name)).fontWeight(.bold)
                    + Text(" to ").foregroundStyle(DS.secondary)
                    + Text(cityFor(train.destination.code, train.destination.name)).fontWeight(.bold))
                    .font(.system(size: Self.routeTitleSize))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 18) {
                    endpoint(departing: true, code: train.origin.code, time: depTime,
                             nextDay: false, tone: tone)
                    endpoint(departing: false, code: train.destination.code, time: arrTime,
                             nextDay: nextDay, tone: tone)
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) {
                if divider {
                    Rectangle().fill(DS.separator).frame(height: 1 / displayScale)
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowLabel(status: status, estimated: !real, depTime: depTime,
                                     arrTime: arrTime, nextDay: nextDay))
    }

    /// Real feed data backs this row's numbers. A finished run keeps any
    /// snapshot that landed; a run still ahead or underway needs a fresh one.
    private var feedBacked: Bool {
        let n = trip.train.number
        let d = trip.live.runDate
        return trip.live.phase == .arrived
            ? LiveFeed.shared.hasFeedData(n, d)
            : LiveFeed.shared.isLive(n, d)
    }

    private var statusLine: StatusLine {
        let live = trip.live
        let arrDelay = trip.arrivalDelayMin
        switch live.phase {
        case .scheduled:
            if live.departsAt.timeIntervalSince(now) > 24 * 3600 {
                return .date(fmtDay(live.departsAt))
            }
            let d = live.stopTimings[0].delayMin
            return .pair(label: "Departs", value: d > 5 ? "\(d)m late" : "On Time")
        case .boarding:
            // the destination forecast owns the copy once arrival slips
            return arrDelay > 5
                ? .pair(label: "Arrives", value: "\(arrDelay)m late")
                : .pair(label: "Departs", value: "On Time")
        case .enroute:
            let mins = max(0, live.arrivesEst.timeIntervalSince(now) / 60)
            return .pair(label: "Arriving in", value: fmtDuration(mins))
        case .arrived:
            return .pair(label: "Arrived", value: arrDelay > 5 ? "\(arrDelay)m late" : "On Time")
        }
    }

    private func endpoint(departing: Bool, code: String, time: Date, nextDay: Bool,
                          tone: StatusTone) -> some View {
        HStack(spacing: 6) {
            EndpointGlyph(departing: departing, tone: tone)
            Text(code)
                .font(.dsCallout.weight(.semibold))
                .foregroundStyle(DS.secondary)
            timeText(time, nextDay: nextDay, size: 16, weight: .semibold)
                .foregroundStyle(tone.text)
                .monospacedDigit()
        }
        .lineLimit(1)
    }

    private func rowLabel(status: StatusLine, estimated: Bool, depTime: Date, arrTime: Date,
                          nextDay: Bool) -> String {
        let train = trip.train
        let lead: String
        switch trip.live.phase {
        case .scheduled:
            lead = "Departs in \(spokenDuration(depTime.timeIntervalSince(now) / 60))"
        case .boarding: lead = "Boarding"
        case .enroute: lead = "On rails"
        case .arrived: lead = "Arrived"
        }
        let statusPhrase: String
        switch status {
        case .date(let d): statusPhrase = d
        case .pair(let label, let value):
            statusPhrase = "\(label) \(value)" + (estimated ? ", estimated" : "")
        }
        return "\(train.category.label) \(train.number), "
            + "\(cityFor(train.origin.code, train.origin.name)) to "
            + "\(cityFor(train.destination.code, train.destination.name)). "
            + "\(lead). \(statusPhrase). "
            + "Departs \(train.origin.code) \(fmtTime(depTime)), "
            + "arrives \(train.destination.code) \(fmtTime(arrTime))\(nextDay ? " next day" : "")."
    }
}

private enum StatusLine {
    /// Far-future runs commit to nothing but their date.
    case date(String)
    /// Gray label, tone-colored value: "Departs" + "On Time".
    case pair(label: String, value: String)
}

private struct RowStatus: View {
    let line: StatusLine
    let tone: StatusTone
    let estimated: Bool

    var body: some View {
        switch line {
        case .date(let d):
            Text(d)
                .font(.dsSubhead.weight(.regular))
                .foregroundStyle(DS.secondary)
                .lineLimit(1)
        case .pair(let label, let value):
            HStack(spacing: 5) {
                (Text(label + " ").foregroundStyle(DS.secondary)
                    + Text(value).fontWeight(.semibold).foregroundStyle(tone.text))
                    .font(.dsSubhead.weight(.regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .rollingNumbers(value: value)
                if estimated {
                    Text("Est")
                        .eyebrow()
                        .padding(.horizontal, 5)
                        .frame(height: 16)
                        .background(DS.fill, in: Capsule())
                }
            }
        }
    }
}

/// Left rail: the countdown numeral, or a state circle once the run is live.
private struct RowRail: View {
    let trip: HeldTrip
    let now: Date
    let departure: Date

    var body: some View {
        VStack(spacing: 4) {
            switch trip.live.phase {
            case .scheduled:
                let parts = countdownParts(until: departure, now: now)
                Text(parts.value)
                    .font(.dsCountdown)
                    .foregroundStyle(DS.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .rollingNumbers(value: parts.value)
                unitCaption(parts.unit)
            case .boarding, .enroute:
                stateCircle("tram.fill", ink: DS.ink)
                caption(trip.live.phase == .enroute ? "ON RAILS" : "BOARDING")
            case .arrived:
                stateCircle("checkmark", ink: DS.secondary)
                caption("ARRIVED")
            }
        }
    }

    private func stateCircle(_ symbol: String, ink: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(ink)
            .frame(width: 44, height: 44)
            .background(DS.fill, in: Circle())
    }

    private func caption(_ s: String) -> some View {
        Text(s)
            .eyebrow()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    /// "41 MIN": the number in ink, the unit whispering beside it.
    private func unitCaption(_ unit: String) -> some View {
        let parts = unit.split(separator: " ", maxSplits: 1).map(String.init)
        let leadsWithNumber = parts.count == 2 && parts[0].allSatisfy(\.isNumber)
        let text = leadsWithNumber
            ? Text(parts[0] + " ").foregroundStyle(DS.ink) + Text(parts[1]).foregroundStyle(DS.secondary)
            : Text(unit).foregroundStyle(DS.secondary)
        return text
            .font(.dsEyebrow)
            .kerning(0.6)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .rollingNumbers(value: unit)
    }
}

/// "5 hours 41 minutes" for VoiceOver, where "5h 41m" reads badly.
private func spokenDuration(_ minutes: Double) -> String {
    let m = max(0, Int(minutes.rounded()))
    if m >= 48 * 60 {
        let days = Int((Double(m) / (24 * 60)).rounded())
        return "\(days) days"
    }
    let h = m / 60
    let rest = m % 60
    let hours = h == 0 ? "" : "\(h) hour\(h == 1 ? "" : "s") "
    return hours + "\(rest) minute\(rest == 1 ? "" : "s")"
}
