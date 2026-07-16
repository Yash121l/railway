import SwiftUI

/// Seat availability, the IRCTC ritual — but readable: pick a class and
/// quota, get the next runs with PRS-true status strings ("AVAILABLE-0042",
/// "GNWL21/WL9"), color-coded so bookable dates jump out, with a fare
/// estimate per class.

private func statusTone(_ s: AvailStatus) -> Color {
    switch s {
    case .available: return .onTime
    case .rac: return Color(hex: 0xB58900)
    case .waitlist: return .lateRed
    case .regret, .departed: return .lateRed
    case .opens, .charting, .noService: return .subGray
    }
}

/// Typed push token so availability screens can be reached from any stack
/// without colliding with the String trip-id destinations.
struct AvailRoute: Hashable { let number: String }

struct AvailabilityView: View {
    let number: String

    @EnvironmentObject private var bank: TrainBank
    @State private var jClass: JClass?
    @State private var quota: Quota = .general
    /// live availability strings by "yyyy-MM-dd" when a key resolves them, and
    /// whether the last live fetch actually succeeded (gates the footer)
    @State private var liveAvail: [String: String] = [:]
    @State private var liveSourceOK = false
    @AppStorage("railly.tatkalReminders") private var tatkalReminderCSV = ""

    var body: some View {
        Group {
            if let train = bank.cached(number) {
                loaded(train)
            } else {
                // reachable only with a resolved train; guard anyway
                Text("Schedule not loaded yet.")
                    .foregroundStyle(Color.subGray)
            }
        }
        .background(Color.white)
        .navigationTitle("Seat Availability")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loaded(_ train: Train) -> some View {
        let classes = JClass.reservable(from: train.classes)
        let selected = jClass ?? JClass.defaultPick(classes) ?? .sleeper

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header(train)

                eyebrow("CLASS")
                classPicker(classes, selected: selected)

                eyebrow("QUOTA")
                quotaPicker

                if let note = quota.note {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.fadedGray)
                        if quota == .tatkal, let target = nextTatkalDate(train, selected) {
                            tatkalRemindButton(train, target, selected)
                        }
                    }
                    .padding(.top, 6)
                }

                fareLine(train, selected)
                    .padding(.top, 16)

                eyebrow("NEXT RUNS")
                TimelineView(.periodic(from: .now, by: 30)) { ctx in
                    let days = Reservation.strip(train, selected, quota,
                                                 now: ctx.date, days: 7)
                    VStack(spacing: 0) {
                        ForEach(days) { day in
                            dayRow(day, train: train, jClass: selected,
                                   now: ctx.date, live: liveAvail[day.dateISO])
                        }
                        // the model's confirm-chance note only applies to the
                        // model strip — not when we're showing live PRS strings
                        if !liveSourceOK,
                           days.contains(where: { if case .waitlist = $0.status { return true }; return false }) {
                            Text("Confirm chance is Railly's waitlist model — an estimate, not a guarantee.")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.fadedGray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 10)
                        }
                    }
                }

                Text(availabilityCaption)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fadedGray)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 44)
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: quota)
        .sensoryFeedback(.selection, trigger: jClass)
        // Real availability when a key is set — GN quota only, as the endpoint
        // supports. Refetch on class/quota change and once per day; a failure
        // (or a non-GN quota) leaves the model strip and an honest footer.
        .task(id: "\(selected.rawValue)|\(quota.rawValue)|\(istDateISO(Date()))") {
            liveSourceOK = false
            liveAvail = [:]
            guard IndianRailAPI.isConfigured, quota == .general else { return }
            if let result = try? await IndianRailAPI.seatAvailability(
                number: train.number, from: train.origin.code, to: train.destination.code,
                dateISO: istDateISO(Date()), jClass: selected.rawValue), !result.isEmpty {
                liveAvail = result
                liveSourceOK = true
            }
        }
    }

    /// Footer provenance, gated on an actual successful live fetch — never
    /// claims live data we didn't get.
    private var availabilityCaption: String {
        if liveSourceOK { return "Live availability via indianrailapi.com." }
        if IndianRailAPI.isConfigured {
            return "Showing Railly's fill model — live availability wasn't reachable for this class/quota."
        }
        return "Demo availability — a live model of how IR trains fill.\nAdd a live-data key in Settings for booking-grade numbers."
    }

    /// Tone for a raw PRS availability string ("AVAILABLE-0042", "RAC12",
    /// "GNWL21/WL9", "REGRET").
    private func liveTone(_ s: String) -> Color {
        let u = s.uppercased()
        if u.contains("AVBL") || u.contains("AVAIL") || u.contains("CURR") { return .onTime }
        if u.contains("RAC") { return Color(hex: 0xB58900) }
        if u.contains("REGRET") || u.contains("WL") || u.contains("NOT") { return .lateRed }
        return .subGray
    }

    private func header(_ train: Train) -> some View {
        HStack(spacing: 11) {
            TrainMark(category: train.category, size: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(train.number) · \(runDaysLabel(train.days))")
                    .font(.system(size: 12, weight: .semibold))
                    .kerning(0.5)
                    .foregroundStyle(Color.subGray)
                Text(train.displayName)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color.inkline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.top, 14)
    }

    private func eyebrow(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .bold))
            .kerning(0.8)
            .foregroundStyle(Color.fadedGray)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private func classPicker(_ classes: [JClass], selected: JClass) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(classes, id: \.self) { c in
                    Button {
                        jClass = c
                    } label: {
                        VStack(spacing: 2) {
                            Text(c.rawValue)
                                .font(.system(size: 15, weight: .bold))
                            Text(c.label)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(c == selected ? .white : Color.inkline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(c == selected ? Color.inkline : Color.fillGray)
                        )
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(c.tint)
                                .frame(width: 26, height: 3)
                                .padding(.top, 3)
                                .opacity(c == selected ? 1 : 0)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var quotaPicker: some View {
        HStack(spacing: 8) {
            ForEach(Quota.allCases, id: \.self) { q in
                Button {
                    quota = q
                } label: {
                    Text(q == .general || q == .tatkal ? q.label : q.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(quota == q ? .white : Color.inkline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(quota == q ? Color.inkline : Color.fillGray))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func fareLine(_ train: Train, _ jClass: JClass) -> some View {
        HStack(spacing: 6) {
            Text("₹\(FareModel.fare(train, jClass, quota: quota))")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color.inkline)
                .monospacedDigit()
                .rollingNumbers(value: "\(FareModel.fare(train, jClass, quota: quota))")
            Text("approx · \(jClass.label) · \(Int(train.distanceKm)) km")
                .font(.system(size: 13))
                .foregroundStyle(Color.subGray)
        }
    }

    /// The next run date whose Tatkal window (for this class) hasn't opened yet
    /// — the one a reminder should target.
    private func nextTatkalDate(_ train: Train, _ jClass: JClass) -> String? {
        let now = Date()
        let today = istDateISO(now)
        var offset = 0
        while offset <= Reservation.arpDays {
            let d = addDaysISO(today, offset)
            offset += 1
            guard train.days.contains(istWeekday(d)) else { continue }
            let remindAt = Reservation.tatkalOpen(travelDateISO: d, jClass: jClass)
                .addingTimeInterval(-15 * 60)
            if remindAt > now { return d }
        }
        return nil
    }

    private func tatkalRemindButton(_ train: Train, _ target: String,
                                    _ jClass: JClass) -> some View {
        let id = TatkalReminder.id(number: train.number, travelDateISO: target)
        let isSet = tatkalReminderCSV.split(separator: ",").map(String.init).contains(id)
        let opens = Reservation.tatkalOpen(travelDateISO: target, jClass: jClass)
        return Button {
            var ids = tatkalReminderCSV.split(separator: ",").map(String.init)
            if isSet {
                TatkalReminder.cancel(number: train.number, travelDateISO: target)
                ids.removeAll { $0 == id }
            } else if TatkalReminder.schedule(number: train.number,
                                              trainName: train.displayName,
                                              travelDateISO: target,
                                              jClass: jClass, now: Date()) {
                ids.append(id)
            }
            tatkalReminderCSV = ids.joined(separator: ",")
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSet ? "bell.fill" : "bell")
                Text(isSet
                    ? "Reminder set · \(fmtTime(opens)) \(fmtDay(opens))"
                    : "Remind me before it opens")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isSet ? Color.onTime : Color.arcBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background((isSet ? Color.onTime : Color.arcBlue).opacity(0.1), in: Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSet)
    }

    private func dayRow(_ day: DayAvailability, train: Train, jClass: JClass,
                        now: Date, live: String?) -> some View {
        let today = istDateISO(now)
        let label = day.dateISO == today ? "Today"
            : day.dateISO == addDaysISO(today, 1) ? "Tomorrow" : nil
        let pretty = fmtDay(istDateTime(day.dateISO, minutes: 12 * 60))
        let color = live.map(liveTone) ?? statusTone(day.status)

        return HStack {
            VStack(alignment: .leading, spacing: 1) {
                if let label {
                    Text(label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.inkline)
                    Text(pretty)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.subGray)
                } else {
                    Text(pretty)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.inkline)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(live ?? day.status.text)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 9))
                if live != nil {
                    Text("LIVE")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(0.6)
                        .foregroundStyle(Color.onTime)
                } else if case .waitlist(let kind, _, let current) = day.status {
                    let departure = istDateTime(day.dateISO, minutes: parseHM(train.departureTime))
                    wlMeter(Reservation.wlConfidence(
                        train, jClass, kind: kind, position: current,
                        daysToGo: departure.timeIntervalSince(now) / 86_400))
                }
            }
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }

    private func confidenceTone(_ pct: Int) -> Color {
        pct >= 68 ? .onTime : pct >= 32 ? Color(hex: 0xB58900) : .lateRed
    }

    /// The waitlist-confidence meter: a thin track filled to the model's
    /// confirm-by-charting odds, with the percent alongside.
    private func wlMeter(_ c: Reservation.WLConfidence) -> some View {
        let tone = confidenceTone(c.percent)
        return HStack(spacing: 6) {
            Capsule().fill(Color.fillGray)
                .frame(width: 44, height: 5)
                .overlay(alignment: .leading) {
                    Capsule().fill(tone)
                        .frame(width: 44 * CGFloat(c.percent) / 100, height: 5)
                }
            Text("\(c.percent)%")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tone)
                .monospacedDigit()
        }
    }
}
