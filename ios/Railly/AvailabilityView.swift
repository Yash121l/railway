import SwiftUI

/// Seat availability, the IRCTC ritual made readable: pick a class and quota,
/// scan a strip of upcoming runs colored by status, tap one for the exact PRS
/// string, the waitlist odds, and the fare, then book on IRCTC.

/// Status color for an availability value: green bookable, amber RAC, red
/// waitlist, gray for regret and everything that isn't a live queue.
func availTone(_ s: AvailStatus) -> Color {
    switch s {
    case .available: return DS.onTimeText
    case .rac: return DS.rac
    case .waitlist: return DS.lateText
    case .regret, .departed, .opens, .charting, .noService: return DS.secondary
    }
}

private func availWash(_ tone: Color) -> Color {
    switch tone {
    case DS.onTimeText: return DS.onTimeWash
    case DS.rac: return DS.amberWash
    case DS.lateText: return DS.lateWash
    default: return DS.neutralWash
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
    @State private var selectedDate: String?
    /// live availability strings by "yyyy-MM-dd" when a key resolves them, and
    /// whether the last live fetch actually succeeded (gates every "live" label)
    @State private var liveAvail: [String: String] = [:]
    @State private var liveSourceOK = false
    @AppStorage("railly.tatkalReminders") private var tatkalReminderCSV = ""

    private static let irctcURL = URL(string: "https://www.irctc.co.in/nget/train-search")!

    var body: some View {
        Group {
            if let train = bank.cached(number) {
                loaded(train)
            } else {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading the schedule for \(number)…")
                        .font(.dsFootnote)
                        .foregroundStyle(DS.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task { _ = try? await bank.resolve(number) }
            }
        }
        .background(DS.sheet)
        .navigationTitle("Seat Availability")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loaded(_ train: Train) -> some View {
        let classes = JClass.reservable(from: train.classes)
        let selected = jClass ?? JClass.defaultPick(classes) ?? .sleeper

        return TimelineView(.periodic(from: .now, by: 30)) { ctx in
            let days = Reservation.strip(train, selected, quota, now: ctx.date, days: 14)
            let focus = days.first { $0.dateISO == selectedDate }
                ?? days.first { $0.status.isBookable }
                ?? days.first

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header(train)
                    classPicker(classes, selected: selected)
                    quotaRow(train, selected)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Next Runs")
                                .font(.dsSection)
                                .foregroundStyle(DS.ink)
                            Spacer()
                            sourceTag(days)
                        }
                        dateStrip(days, focus: focus?.dateISO, now: ctx.date)
                    }
                    if let focus {
                        dayDetail(focus, train: train, jClass: selected, now: ctx.date)
                    }
                    bookButton
                    Text(availabilityCaption)
                        .font(.dsCaption)
                        .foregroundStyle(DS.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, DS.gutter)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .sensoryFeedback(.selection, trigger: quota)
        .sensoryFeedback(.selection, trigger: jClass)
        .sensoryFeedback(.selection, trigger: selectedDate)
        // Real availability when a key is set, GN quota only, as the endpoint
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

    /// LIVE only when every day on screen came from the live source; days the
    /// live answer skipped fall back to the model, so a partial fetch reads as
    /// partly estimated.
    @ViewBuilder
    private func sourceTag(_ days: [DayAvailability]) -> some View {
        let liveDays = days.filter { liveAvail[$0.dateISO] != nil }.count
        if liveSourceOK && liveDays == days.count {
            DSChip(text: "LIVE", color: DS.onTimeText)
        } else if liveSourceOK && liveDays > 0 {
            EstimateTag(text: "Partly estimated")
        } else {
            EstimateTag()
        }
    }

    /// Footer provenance, gated on an actual successful live fetch: never
    /// claims live data we didn't get.
    private var availabilityCaption: String {
        if liveSourceOK { return "Live availability via indianrailapi.com." }
        if IndianRailAPI.isConfigured {
            return "Estimated with Railly's fill model. Live availability wasn't reachable for this class and quota."
        }
        return "Estimated with Railly's model of how IR trains fill.\nAdd a live-data key in Settings for booking-grade numbers."
    }

    // MARK: Header & pickers

    private func header(_ train: Train) -> some View {
        HStack(spacing: 12) {
            TrainMark(category: train.category, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(train.number) · \(runDaysLabel(train.days))")
                    .font(.dsCaption)
                    .foregroundStyle(DS.secondary)
                Text(train.displayName)
                    .font(.dsSection)
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\(train.origin.code) → \(train.destination.code)")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
            }
        }
    }

    private func classPicker(_ classes: [JClass], selected: JClass) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(classes, id: \.self) { c in
                    let on = c == selected
                    Button {
                        jClass = c
                    } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(c.rawValue).font(.dsHeadline)
                            Text(c.label).font(.dsCaption)
                                .foregroundStyle(on ? Color.white.opacity(0.75) : DS.secondary)
                        }
                        .foregroundStyle(on ? Color.white : DS.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(on ? DS.ink : DS.fill,
                                    in: RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous))
                    }
                    .buttonStyle(DSPressStyle())
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    private func quotaRow(_ train: Train, _ selected: JClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                Picker("Quota", selection: $quota) {
                    ForEach(Quota.allCases, id: \.self) { q in
                        Text(q.label).tag(q)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Quota").foregroundStyle(DS.secondary)
                    Text(quota.label).fontWeight(.semibold).foregroundStyle(DS.ink)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.dsCaption)
                        .foregroundStyle(DS.secondary)
                }
                .font(.dsCallout)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(DS.fill, in: Capsule())
            }
            if let note = quota.note {
                Text(note)
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
            }
            if quota == .tatkal, let target = nextTatkalDate(train, selected) {
                tatkalRemindButton(train, target, selected)
            }
        }
    }

    // MARK: Strip

    private func dateStrip(_ days: [DayAvailability], focus: String?, now: Date) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(days) { day in
                    dateCell(day, selected: day.dateISO == focus, now: now)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    private func dateCell(_ day: DayAvailability, selected: Bool, now: Date) -> some View {
        let live = liveAvail[day.dateISO]
        let tone = live.map(liveTone) ?? availTone(day.status)
        let parts = fmtDay(istDateTime(day.dateISO, minutes: 12 * 60)).split(separator: " ").map(String.init)
        let today = istDateISO(now)
        let top = day.dateISO == today ? "Today"
            : day.dateISO == addDaysISO(today, 1) ? "Tmrw" : (parts.first ?? "")

        return Button {
            selectedDate = day.dateISO
        } label: {
            VStack(spacing: 4) {
                Text(top)
                    .font(.dsCaption)
                    .foregroundStyle(DS.secondary)
                Text(parts.count > 1 ? parts[1] : "")
                    .font(.dsStat)
                    .foregroundStyle(DS.ink)
                    .monospacedDigit()
                Text(live.map(liveChip) ?? day.status.chip)
                    .font(.dsEyebrow)
                    .foregroundStyle(tone)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 6)
            .frame(width: 70, height: 88)
            .background(availWash(tone), in: RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
                    .stroke(selected ? DS.ink : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(DSPressStyle())
        .accessibilityLabel("\(parts.joined(separator: " ")), \(live ?? day.status.text)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func dayDetail(_ day: DayAvailability, train: Train, jClass: JClass, now: Date) -> some View {
        let live = liveAvail[day.dateISO]
        let tone = live.map(liveTone) ?? availTone(day.status)
        let fare = FareModel.fare(train, jClass, quota: quota)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(fmtDay(istDateTime(day.dateISO, minutes: 12 * 60))) · \(jClass.rawValue) · \(quota.label)")
                    .font(.dsSubhead)
                    .foregroundStyle(DS.secondary)
                Spacer()
                if live != nil { DSChip(text: "LIVE", color: DS.onTimeText) }
            }
            Text(live ?? day.status.text)
                .font(.dsTitle)
                .foregroundStyle(tone)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
            if live == nil, let explainer = explainer(day.status) {
                Text(explainer)
                    .font(.dsFootnote)
                    .foregroundStyle(DS.ink2)
            }
            if live == nil, case .waitlist(let kind, _, let current) = day.status {
                let departure = istDateTime(day.dateISO, minutes: parseHM(train.departureTime))
                wlConfidence(Reservation.wlConfidence(
                    train, jClass, kind: kind, position: current,
                    daysToGo: departure.timeIntervalSince(now) / 86_400))
            }
            Rectangle().fill(DS.separator).frame(height: 1)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Approx. fare, \(jClass.label)")
                        .font(.dsCaption)
                        .foregroundStyle(DS.secondary)
                    Text("₹\(fare.formatted())")
                        .font(.dsStat)
                        .foregroundStyle(DS.ink)
                        .monospacedDigit()
                        .rollingNumbers(value: "\(fare)")
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    EstimateTag()
                    Text("\(Int(train.distanceKm).formatted()) km, full run")
                        .font(.dsCaption)
                        .foregroundStyle(DS.tertiary)
                }
            }
        }
        .dsCard()
    }

    private func explainer(_ s: AvailStatus) -> String? {
        switch s {
        case .available(let n): return n == 1 ? "1 berth left in this quota." : "\(n) berths left in this quota."
        case .rac: return "RAC: you board, sharing a side-lower berth until one frees up."
        case .waitlist: return "Waitlisted: it confirms only as others cancel."
        case .regret: return "The waitlist is full. No more bookings in this class."
        case .opens(let date): return "Tatkal opens \(fmtTime(date)), \(fmtDay(date))."
        case .charting: return "The chart is prepared for this run."
        case .departed: return "This run has already left."
        case .noService: return "No service in this class and quota on this date."
        }
    }

    private func wlConfidence(_ c: Reservation.WLConfidence) -> some View {
        let tone = c.percent >= 68 ? DS.onTimeText : c.percent >= 32 ? DS.rac : DS.lateText
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(c.percent)%")
                    .font(.dsStat)
                    .foregroundStyle(tone)
                    .monospacedDigit()
                Text("chance to confirm")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.ink2)
                Spacer()
                EstimateTag(text: "Railly estimate")
            }
            DSProgress(value: Double(c.percent) / 100, tint: tone)
            Text(c.rationale)
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
        }
        .padding(12)
        .dsWell()
    }

    private var bookButton: some View {
        VStack(spacing: 8) {
            Link(destination: Self.irctcURL) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right.square")
                    Text("Book on IRCTC")
                }
                .font(.dsHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(DS.action, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(DSPressStyle())
            Text("Opens IRCTC. Railly doesn't sell tickets.")
                .font(.dsCaption)
                .foregroundStyle(DS.tertiary)
        }
    }

    // MARK: Live strings

    /// Tone for a raw PRS availability string ("AVAILABLE-0042", "RAC12",
    /// "GNWL21/WL9", "REGRET").
    private func liveTone(_ s: String) -> Color {
        let u = s.uppercased()
        if u.contains("AVBL") || u.contains("AVAIL") || u.contains("CURR") { return DS.onTimeText }
        if u.contains("RAC") { return DS.rac }
        if u.contains("WL") { return DS.lateText }
        return DS.secondary
    }

    /// Compact cell form of a raw PRS string: "AVAILABLE-0042" → "AVL 42".
    private func liveChip(_ s: String) -> String {
        let u = s.uppercased()
        let last = u.split(whereSeparator: { !$0.isNumber }).last.flatMap { Int($0) }
        if u.contains("AVBL") || u.contains("AVAIL") { return last.map { "AVL \($0)" } ?? "AVL" }
        if u.contains("RAC") { return last.map { "RAC \($0)" } ?? "RAC" }
        if u.contains("WL") { return last.map { "WL \($0)" } ?? "WL" }
        return String(u.prefix(8))
    }

    // MARK: Tatkal reminder

    /// The next run date whose Tatkal window (for this class) hasn't opened yet,
    /// the one a reminder should target.
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

    private func tatkalRemindButton(_ train: Train, _ target: String, _ jClass: JClass) -> some View {
        let id = TatkalReminder.id(number: train.number, travelDateISO: target)
        let isSet = tatkalReminderCSV.split(separator: ",").map(String.init).contains(id)
        let opens = Reservation.tatkalOpen(travelDateISO: target, jClass: jClass)
        return DSPill(title: isSet ? "Reminder set · \(fmtTime(opens)) \(fmtDay(opens))" : "Remind me before it opens",
                      systemImage: isSet ? "bell.fill" : "bell",
                      tint: isSet ? DS.onTimeText : DS.action,
                      filled: false) {
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
        }
        .sensoryFeedback(.selection, trigger: isSet)
    }
}
