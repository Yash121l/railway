import SwiftUI

// MARK: - Stats

/// Everything the Passport and the Delay Report show, computed from the
/// user's own completed trips: distances are the feed's published track
/// kilometres, rail time is the timetabled journey time.
struct LogStats {
    var trips = 0
    var overnight = 0
    var distanceKm = 0.0
    var railMinutes = 0
    var stationCodes = Set<String>()
    var trainNumbers = Set<String>()
    var lostMinutes = 0
    var delayedTrips = 0
    /// How many of `delayedTrips` had their delay read from a real feed rather
    /// than projected from the timetable. Drives the provenance line on the
    /// delay card, so the Passport never states a figure it cannot source.
    var measuredDelayedTrips = 0
    /// Trips whose run was backed by a real feed at all, late or not.
    var measuredTrips = 0
    var worstDelayMin = 0
    var worstTrain = ""
    var worstRoute = ""
    var worstTripId = ""
    /// Trips that arrived 3h+ late *on real feed data*. Projected delays never
    /// count here: see `compute`.
    var refundEligible = 0
    /// Trips per IST weekday of departure, Sunday first.
    var weekdayTrips = [Int](repeating: 0, count: 7)

    var aroundTheWorld: Double { distanceKm / 40_075 }
    var avgDelay: Int { delayedTrips == 0 ? 0 : lostMinutes / delayedTrips }

    static func compute(_ past: [HeldTrip]) -> LogStats {
        var s = LogStats()
        s.trips = past.count
        for trip in past {
            let train = trip.train
            s.distanceKm += train.distanceKm
            s.railMinutes += train.destination.arrMin
            s.stationCodes.insert(train.origin.code)
            s.stationCodes.insert(train.destination.code)
            s.trainNumbers.insert(train.number)
            if istDateISO(trip.live.arrivesSched) != istDateISO(trip.live.departsAt) {
                s.overnight += 1
            }
            if let day = Day.allCases.firstIndex(of: istWeekday(trip.live.runDate)) {
                s.weekdayTrips[day] += 1
            }
            let arrDelay = trip.arrivalDelayMin
            let measured = LiveFeed.shared.hasFeedData(train.number, trip.live.runDate)
            if measured { s.measuredTrips += 1 }
            if arrDelay > 0 {
                s.lostMinutes += arrDelay
                s.delayedTrips += 1
                if measured { s.measuredDelayedTrips += 1 }
                if arrDelay > s.worstDelayMin {
                    s.worstDelayMin = arrDelay
                    s.worstTrain = train.number
                    s.worstRoute = "\(train.origin.code)-\(train.destination.code)"
                    s.worstTripId = trip.id
                }
            }
            // Without a live-data key every delay here is a timetable
            // projection, and a projection is not grounds to tell someone the
            // railway owes them anything.
            if arrDelay >= 180, measured { s.refundEligible += 1 }
        }
        return s
    }
}

// MARK: - Signature liveries

/// The Passport and the Delay Report are the two surfaces that carry their
/// own colors instead of the white-sheet palette. The share cards use the same
/// constants so a shared image matches what the app shows.
enum Livery {
    static let passportDeep = Color(hex: 0x0F0B3E)
    static let passportMid = Color(hex: 0x2A1F8F)
    static let passportLabel = Color(hex: 0xB3ACF2)
    static let delayDeep = Color(hex: 0x1C0504)
    static let delayMid = Color(hex: 0x5E110C)
    static let delayHigh = Color(hex: 0x8E2216)
    static let delayLabel = Color(hex: 0xE7AA9E)
    static let flapTop = Color(hex: 0x3A0F08)
    static let flapBottom = Color(hex: 0x1F0704)
    static let flapInk = Color(hex: 0xFDF3E7)
    static let led = Color(hex: 0xFFB020)
    static let ledBoard = Color(hex: 0x1A0502)
    /// Night-globe backdrop for the share-card route sketch and the welcome art.
    static let nightTop = Color(hex: 0x060A14)
    static let nightBottom = Color(hex: 0x13233F)
    static let globeLit = Color(hex: 0x24406E)
    static let globeShade = Color(hex: 0x0C1730)

    static var passport: LinearGradient {
        LinearGradient(colors: [passportDeep, passportMid, DS.passport],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var delay: LinearGradient {
        LinearGradient(colors: [delayDeep, delayMid, delayHigh],
                       startPoint: .top, endPoint: .bottom)
    }
}

/// Whole number with thousands separators: "12,345".
func passportNumber(_ n: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.locale = Locale(identifier: "en_US")
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: n)) ?? "0"
}

/// Passport machine-readable zone, padded with "<" to a fixed width.
func passportMRZ(period: String, name: String, stats: LogStats, width: Int) -> (String, String) {
    let tag = period.replacingOccurrences(of: "-", with: "")
    let head = "P<RLY\(tag)<<\(name)<<MEMBER"
    let body = istDateISO(Date()).replacingOccurrences(of: "-", with: "")
        + "<<\(stats.trips)TRIPS<<\(Int(stats.distanceKm.rounded()))KM"
        + "<<\(stats.railMinutes / 60)H<<\(stats.stationCodes.count)STN<<\(stats.trainNumbers.count)TRN"
    return (head.padding(toLength: width, withPad: "<", startingAt: 0),
            body.padding(toLength: width, withPad: "<", startingAt: 0))
}

/// Split-flap text: "42MIN" under an hour, "9H35M" under 100 hours, "123H" beyond.
private func flapText(_ minutes: Int) -> String {
    if minutes < 60 { return String(format: "%02dMIN", minutes) }
    if minutes < 6000 { return String(format: "%dH%02dM", minutes / 60, minutes % 60) }
    return "\(minutes / 60)H"
}

/// Departure-board text: "42 MIN", "2H 05M".
private func ledText(_ minutes: Int) -> String {
    minutes < 60 ? "\(minutes) MIN" : String(format: "%dH %02dM", minutes / 60, minutes % 60)
}

private func cities(_ train: Train) -> (from: String, to: String) {
    (cityFor(train.origin.code, train.origin.name),
     cityFor(train.destination.code, train.destination.name))
}

private func periodTitle(_ period: String) -> String {
    period == "ALL-TIME" ? "All-time" : period
}

// MARK: - Profile

/// The traveller's log: who you are, the Passport, the Delay Report, and every
/// completed trip. Presented from the avatar on My Trips.
struct ProfileView: View {
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss
    @AppStorage("railly.profileName") private var profileName = ""
    /// nil is all-time; otherwise the "yyyy" the log is filtered to.
    @State private var year: String?
    @State private var passportImage: Image?
    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { ctx in
                page(ctx.date)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
                .environmentObject(bank)
                .environmentObject(router)
                .preferredColorScheme(.light)
        }
        .alert("Your Name", isPresented: $editingName) {
            TextField("Name", text: $nameDraft)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                profileName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } message: {
            Text("Printed on your Passport and its share card.")
        }
    }

    private var hasName: Bool {
        !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func page(_ now: Date) -> some View {
        let allPast = store.myTrips(now, bank: bank).past
        let past = year.map { y in allPast.filter { $0.live.runDate.hasPrefix(y) } } ?? allPast
        let stats = LogStats.compute(past)
        let period = year ?? "ALL-TIME"
        let mrzName = profileMRZName(profileName)
        let cardKey = "\(period)|\(stats.trips)|\(Int(stats.distanceKm))|\(stats.railMinutes)|"
            + "\(stats.stationCodes.count)|\(stats.trainNumbers.count)|\(mrzName)"

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                DSPill(title: "Settings", systemImage: "gearshape", tint: DS.ink, filled: false) {
                    showSettings = true
                }
                .padding(.top, 16)

                periodPicker(years(in: allPast, now: now))
                    .padding(.top, 24)

                PassportCard(stats: stats, past: past, period: period,
                             mrzName: mrzName, shareImage: passportImage)
                    .padding(.top, 14)
                DelayCard(stats: stats, past: past, period: period)
                    .padding(.top, 12)

                pastTrips(past, period: period, now: now)
                    .padding(.top, 34)
            }
            .padding(.horizontal, DS.gutter)
            .padding(.top, 20)
            .padding(.bottom, 40)
            .readableColumn()
        }
        .background(DS.sheet)
        .task(id: cardKey) {
            passportImage = renderPassportShareCard(stats: stats, mrzName: mrzName, period: period)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Button {
                nameDraft = profileName
                editingName = true
            } label: {
                HStack(spacing: 14) {
                    ProfileAvatar(name: profileName, size: 58, showsAdd: !hasName)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hasName ? profileDisplayName(profileName) : "Add Your Name")
                            .font(.dsTitle)
                            .foregroundStyle(hasName ? DS.ink : DS.tertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("My Trip Log")
                            .font(.dsCallout)
                            .foregroundStyle(DS.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Edit your name")

            Spacer(minLength: 8)
            DSCircleButton(systemImage: "xmark", label: "Close") { dismiss() }
        }
    }

    private func years(in past: [HeldTrip], now: Date) -> [String] {
        var set = Set(past.map { String($0.live.runDate.prefix(4)) })
        set.insert(String(istDateISO(now).prefix(4)))
        return set.sorted(by: >)
    }

    private func periodPicker(_ years: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                PeriodChip(title: "ALL-TIME", selected: year == nil) { year = nil }
                ForEach(years, id: \.self) { y in
                    PeriodChip(title: y, selected: year == y) { year = y }
                }
            }
        }
        .animation(.snappy(duration: 0.2), value: year)
    }

    @ViewBuilder
    private func pastTrips(_ past: [HeldTrip], period: String, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            DSSectionHeader(
                title: "Past Trips",
                subtitle: past.isEmpty ? nil
                    : "\(past.count) trip\(past.count == 1 ? "" : "s") · \(periodTitle(period))")

            if past.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tram")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(DS.tertiary)
                    Text(year == nil
                         ? "Completed trips land here and fill your Passport."
                         : "No completed trips in \(period).")
                        .font(.dsCallout)
                        .foregroundStyle(DS.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            }

            ForEach(Array(past.enumerated()), id: \.element.id) { i, trip in
                Button {
                    router.focus(trip.id)
                } label: {
                    TripRowView(trip: trip, now: now, divider: i < past.count - 1)
                }
                .buttonStyle(RowPressStyle())
            }
        }
    }
}

/// Round monogram avatar; a person glyph (and an optional "+" badge) until a
/// name is set.
struct ProfileAvatar: View {
    let name: String
    var size: CGFloat = 56
    var showsAdd = false

    var body: some View {
        let empty = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ZStack(alignment: .bottomTrailing) {
            Group {
                if empty {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.44))
                        .foregroundStyle(DS.tertiary)
                } else {
                    Text(profileAvatarInitial(name))
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundStyle(DS.passport)
                }
            }
            .frame(width: size, height: size)
            .background(empty ? DS.fill : DS.passport.opacity(0.12), in: Circle())

            if showsAdd {
                Image(systemName: "plus")
                    .font(.system(size: size * 0.2, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: size * 0.36, height: size * 0.36)
                    .background(DS.action, in: Circle())
                    .overlay(Circle().stroke(DS.sheet, lineWidth: 2))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct PeriodChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.dsSubhead)
                .foregroundStyle(selected ? DS.ink : DS.secondary)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(selected ? DS.fill : .clear,
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Rows flash the fill gray on press, like a table cell.
private struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
                    .fill(DS.fill)
                    .padding(.horizontal, -10)
                    .opacity(configuration.isPressed ? 1 : 0)
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Passport card

/// The translucent "All Trip Stats" bar at the foot of both hero cards.
private struct HeroCardButton: View {
    let label: String

    var body: some View {
        HStack {
            Text(label).font(.dsHeadline)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
            .stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

/// Concentric rings in the corner, the security-print texture of a real
/// passport page.
private struct Guilloche: View {
    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { i in
                Circle()
                    .stroke(.white.opacity(0.05), lineWidth: 1)
                    .frame(width: CGFloat(90 + i * 46), height: CGFloat(90 + i * 46))
            }
        }
        .offset(x: 150, y: -120)
        .allowsHitTesting(false)
    }
}

private struct PassportCard: View {
    let stats: LogStats
    let past: [HeldTrip]
    let period: String
    let mrzName: String
    let shareImage: Image?

    var body: some View {
        let mrz = passportMRZ(period: period, name: mrzName, stats: stats, width: 44)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(period) RAILLY PASSPORT")
                        .font(.system(size: 17, weight: .semibold))
                        .kerning(1)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    HStack(spacing: 6) {
                        Image(systemName: "person.text.rectangle.fill")
                        Text("PASSPORT · PASS · पासपोर्ट")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(1.1)
                    .foregroundStyle(Livery.passportLabel)
                }
                Spacer(minLength: 8)
                if let shareImage {
                    ShareLink(item: shareImage,
                              preview: SharePreview("Railly Passport", image: shareImage)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Share Passport")
                    .simultaneousGesture(TapGesture().onEnded {
                        Analytics.shared.log(.shareCardSent, ["card": "passport"])
                    })
                }
            }

            label("DISTANCE").padding(.top, 24)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(passportNumber(stats.distanceKm))
                    .font(.system(size: 46, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("km")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Livery.passportLabel)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            Text(String(format: "%.2fx around the world", stats.aroundTheWorld))
                .font(.dsFootnote)
                .foregroundStyle(Livery.passportLabel)

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 16) {
                GridRow {
                    stat("TRIPS", "\(stats.trips)",
                         sub: stats.overnight > 0 ? "\(stats.overnight) overnight" : nil)
                    stat("RAIL TIME", stats.railMinutes == 0 ? "0h" : fmtDuration(Double(stats.railMinutes)))
                }
                GridRow {
                    stat("STATIONS", "\(stats.stationCodes.count)")
                    stat("TRAINS", "\(stats.trainNumbers.count)")
                }
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 3) {
                Rectangle()
                    .fill(Livery.passportLabel.opacity(0.3))
                    .frame(height: 1)
                    .padding(.bottom, 7)
                Text(mrz.0)
                Text(mrz.1)
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.5))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.top, 20)
            .accessibilityHidden(true)

            NavigationLink {
                TripStatsView(stats: stats, past: past, period: period, shareImage: shareImage)
            } label: {
                HeroCardButton(label: "All Trip Stats")
            }
            .buttonStyle(DSPressStyle())
            .padding(.top, 18)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Livery.passport
                .overlay(Guilloche())
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.dsEyebrow)
            .kerning(1)
            .foregroundStyle(Livery.passportLabel)
    }

    private func stat(_ title: String, _ value: String, sub: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            label(title)
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .monospacedDigit()
            if let sub {
                Text(sub).font(.dsCaption).foregroundStyle(Livery.passportLabel)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Delay card

private struct SplitFlap: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(colors: [Livery.flapTop, Livery.flapBottom],
                                             startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.black.opacity(0.5), lineWidth: 1)
                    Rectangle()
                        .fill(.black.opacity(0.55))
                        .frame(height: 1.5)
                    Text(String(ch))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(ch.isLetter ? Livery.flapInk.opacity(0.3) : Livery.flapInk)
                }
                .frame(width: 42, height: 60)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

/// Amber dot-matrix strip: "2H 05M   12951   MMCT-NDLS".
private struct LedStrip: View {
    let minutes: Int
    let train: String
    let route: String

    var body: some View {
        HStack {
            Text(ledText(minutes))
            Spacer(minLength: 8)
            Text(train)
            Spacer(minLength: 8)
            Text(route)
        }
        .font(.system(size: 15, weight: .bold, design: .monospaced))
        .kerning(1.5)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .foregroundStyle(Livery.led)
        .shadow(color: Livery.led.opacity(0.6), radius: 5)
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Livery.ledBoard, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Worst delay \(ledText(minutes)), train \(train), \(route)")
    }
}

private struct DelayCard: View {
    let stats: LogStats
    let past: [HeldTrip]
    let period: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(period) DELAY REPORT")
                .font(.dsEyebrow)
                .kerning(1)
                .foregroundStyle(Livery.led)

            SplitFlap(text: flapText(stats.lostMinutes))
                .padding(.top, 16)
            Text("Lost to Delays")
                .font(.dsTitle)
                .foregroundStyle(.white)
                .padding(.top, 14)
            Text(summary)
                .font(.dsFootnote)
                .foregroundStyle(Livery.delayLabel)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)

            if stats.delayedTrips > 0 {
                Text(stats.measuredDelayedTrips == 0
                     ? "Estimated from the timetable, not a live feed"
                     : "\(stats.measuredDelayedTrips) of \(stats.delayedTrips) measured from a live feed, the rest estimated from the timetable")
                    .font(.dsCaption)
                    .foregroundStyle(Livery.delayLabel.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }

            if stats.refundEligible > 0 {
                Label("\(stats.refundEligible) trip\(stats.refundEligible == 1 ? "" : "s") ran 3h+ late, per the live feed",
                      systemImage: "indianrupeesign.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Livery.led)
                    .padding(.top, 10)
            }

            if stats.worstDelayMin > 0 {
                LedStrip(minutes: stats.worstDelayMin, train: stats.worstTrain, route: stats.worstRoute)
                    .padding(.top, 18)
                Text("WORST DELAY")
                    .font(.dsEyebrow)
                    .kerning(1)
                    .foregroundStyle(Livery.delayLabel)
                    .padding(.top, 8)
            }

            NavigationLink {
                DelayStatsView(stats: stats, past: past, period: period)
            } label: {
                HeroCardButton(label: "All Delay Stats")
            }
            .buttonStyle(DSPressStyle())
            .padding(.top, 18)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Livery.delay, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var summary: String {
        if stats.trips == 0 { return "Completed trips are graded here." }
        if stats.delayedTrips == 0 { return "No time lost yet. May the signals stay green." }
        return "Delayed trips averaged \(stats.avgDelay)m late · \(stats.delayedTrips) of \(stats.trips) trips delayed"
    }
}

// MARK: - Stats building blocks

/// A titled stats section with a hairline beneath, Flighty's stats-page rhythm.
private struct StatBlock<Content: View>: View {
    let title: String
    var estimated = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.dsSection).foregroundStyle(DS.ink)
                Spacer()
                if estimated { EstimateTag() }
            }
            content
        }
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.separator).frame(height: 1)
        }
    }
}

/// The oversized number that leads each section: "6,729 km".
private struct BigNumber: View {
    let value: String
    var unit: String? = nil

    var body: some View {
        (Text(value).font(.system(size: 52, weight: .bold)).foregroundStyle(DS.ink)
            + Text(unit.map { " \($0)" } ?? "").font(.system(size: 28, weight: .semibold)).foregroundStyle(DS.tertiary))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

private struct Bar: Identifiable {
    let id: String
    let label: String
    let value: Int
}

/// Plain vertical bar chart with count labels over non-empty bars.
private struct VerticalBars: View {
    let bars: [Bar]
    let tint: Color

    var body: some View {
        let top = Double(max(1, bars.map(\.value).max() ?? 1))
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(bars) { b in
                    VStack(spacing: 4) {
                        Spacer(minLength: 0)
                        if b.value > 0 {
                            Text("\(b.value)")
                                .font(.dsCaption)
                                .foregroundStyle(DS.secondary)
                                .monospacedDigit()
                        }
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(b.value > 0 ? tint : DS.fill2)
                            .frame(height: b.value > 0 ? max(6, 120 * Double(b.value) / top) : 3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 146)
            .overlay(alignment: .bottom) {
                Rectangle().fill(DS.separator).frame(height: 1)
            }
            HStack(spacing: 8) {
                ForEach(bars) { b in
                    Text(b.label)
                        .font(.dsCaption)
                        .foregroundStyle(DS.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bars.map { "\($0.label) \($0.value)" }.joined(separator: ", "))
    }
}

/// "0.31x Around the Earth" — a comparison as a filled capsule.
private struct ComparisonBar: View {
    let icon: String
    let ratio: Double
    let label: String

    private var ratioText: String {
        switch ratio {
        case 10...: return String(format: "%.0fx", ratio)
        case 1...: return String(format: "%.1fx", ratio)
        case 0.01...: return String(format: "%.2fx", ratio)
        default: return String(format: "%.3fx", ratio)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.passport)
                .frame(width: 42, height: 42)
                .background(DS.passport.opacity(0.12), in: Circle())
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.passport.opacity(0.13))
                    Capsule().fill(DS.passport)
                        .frame(width: max(geo.size.height, geo.size.width * min(1, ratio)))
                    HStack {
                        Spacer()
                        (Text(ratioText).fontWeight(.bold) + Text(" \(label)"))
                            .font(.dsSubhead)
                            .foregroundStyle(ratio >= 0.75 ? .white : DS.passport)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.trailing, 14)
                    }
                }
            }
            .frame(height: 42)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(ratioText) \(label)")
    }
}

/// A ranked line: title and subtitle, a proportional bar, and the count.
private struct RankRow: View {
    let title: String
    let subtitle: String
    let count: Int
    let top: Int
    var tint: Color = DS.passport
    var mark: TrainCategory? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let mark { TrainMark(category: mark, size: 30) }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.dsHeadline)
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.fill)
                    Capsule().fill(tint)
                        .frame(width: max(8, geo.size.width * Double(count) / Double(max(1, top))))
                }
            }
            .frame(width: 72, height: 8)
            Text("\(count)")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .frame(minWidth: 24, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Widget-style tile: label, value, optional footnote.
private struct StatTile: View {
    let label: String
    let value: String
    var sub: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.dsSubhead).foregroundStyle(DS.ink2)
            Text(value)
                .font(.dsStat)
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let sub {
                Text(sub)
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .dsWell(radius: 18)
        .accessibilityElement(children: .combine)
    }
}

/// One trip as a tappable line (shortest / longest / worst). Taps fly the
/// globe to it.
private struct TripLine: View {
    let trip: HeldTrip
    let trailing: String
    var trailingUnit = ""
    let action: () -> Void

    var body: some View {
        let c = cities(trip.train)
        Button(action: action) {
            HStack(spacing: 12) {
                TrainMark(category: trip.train.category, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    (Text(c.from) + Text("  →  ").foregroundStyle(DS.tertiary) + Text(c.to))
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("\(trip.train.number) · \(fmtDay(trip.live.departsAt))")
                        .font(.dsFootnote)
                        .foregroundStyle(DS.secondary)
                }
                Spacer(minLength: 8)
                (Text(trailing) + Text(trailingUnit).foregroundStyle(DS.tertiary))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(DS.ink)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(RowPressStyle())
    }
}

private func countLine(_ n: Int, _ label: String) -> some View {
    (Text("\(n) ").fontWeight(.semibold).foregroundStyle(DS.ink)
        + Text(label).foregroundStyle(DS.secondary))
        .font(.dsBody)
}

private func monthLabel(_ ym: String) -> String {
    let parts = ym.split(separator: "-")
    guard parts.count == 2, let m = Int(parts[1]), (1...12).contains(m) else { return ym }
    let names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return "\(names[m - 1]) '\(parts[0].suffix(2))"
}

// MARK: - Trip stats

/// The Passport, unfolded: trips by weekday or month, distance against the
/// Earth and Moon, rail time, top routes and stations, and the trains ridden.
struct TripStatsView: View {
    let stats: LogStats
    let past: [HeldTrip]
    let period: String
    var shareImage: Image?

    @EnvironmentObject private var router: Router
    @State private var perMonth = false

    private struct RouteStat: Identifiable {
        let id: String
        let cities: String
        let count: Int
    }

    private struct StationStat: Identifiable {
        let id: String
        let city: String
        let count: Int
    }

    private struct TrainStat: Identifiable {
        let id: String
        let name: String
        let category: TrainCategory
        let count: Int
        let km: Double
        let minutes: Int
    }

    private var weekdayBars: [Bar] {
        zip(Day.allCases, stats.weekdayTrips).map { Bar(id: $0.rawValue, label: $0.rawValue, value: $1) }
    }

    private var monthCounts: [(ym: String, trips: Int, km: Double)] {
        var trips: [String: Int] = [:]
        var km: [String: Double] = [:]
        for t in past {
            let ym = String(t.live.runDate.prefix(7))
            trips[ym, default: 0] += 1
            km[ym, default: 0] += t.train.distanceKm
        }
        return trips.keys.sorted().suffix(12).map { (ym: $0, trips: trips[$0]!, km: km[$0]!) }
    }

    private var monthBars: [Bar] {
        monthCounts.map { Bar(id: $0.ym, label: String(monthLabel($0.ym).prefix(3)), value: $0.trips) }
    }

    private var routeStats: [RouteStat] {
        var count: [String: Int] = [:]
        var label: [String: String] = [:]
        for t in past {
            let key = "\(t.train.origin.code)–\(t.train.destination.code)"
            count[key, default: 0] += 1
            let c = cities(t.train)
            label[key] = "\(c.from) to \(c.to)"
        }
        return count.keys
            .map { RouteStat(id: $0, cities: label[$0] ?? $0, count: count[$0]!) }
            .sorted { $0.count == $1.count ? $0.id < $1.id : $0.count > $1.count }
    }

    private var stationStats: [StationStat] {
        var count: [String: Int] = [:]
        var name: [String: String] = [:]
        for t in past {
            for stop in [t.train.origin, t.train.destination] {
                count[stop.code, default: 0] += 1
                name[stop.code] = cityFor(stop.code, stop.name)
            }
        }
        return count.keys
            .map { StationStat(id: $0, city: name[$0] ?? $0, count: count[$0]!) }
            .sorted { $0.count == $1.count ? $0.id < $1.id : $0.count > $1.count }
    }

    private var trainStats: [TrainStat] {
        var byNumber: [String: TrainStat] = [:]
        for t in past {
            let prev = byNumber[t.train.number]
            byNumber[t.train.number] = TrainStat(
                id: t.train.number, name: t.train.displayName, category: t.train.category,
                count: (prev?.count ?? 0) + 1,
                km: (prev?.km ?? 0) + t.train.distanceKm,
                minutes: (prev?.minutes ?? 0) + t.train.destination.arrMin)
        }
        return byNumber.values.sorted { $0.count == $1.count ? $0.km > $1.km : $0.count > $1.count }
    }

    private var categoryStats: [(category: TrainCategory, count: Int)] {
        var count: [TrainCategory: Int] = [:]
        for t in past { count[t.train.category, default: 0] += 1 }
        return count.map { (category: $0.key, count: $0.value) }
            .sorted { $0.count == $1.count ? $0.category.label < $1.category.label : $0.count > $1.count }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(periodTitle(period)) · Railly Passport")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
                    .padding(.top, 8)
                if past.isEmpty {
                    Text("Finish a trip and its numbers land here.")
                        .font(.dsCallout)
                        .foregroundStyle(DS.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else {
                    tripsBlock
                    distanceBlock
                    timeBlock
                    routesBlock
                    stationsBlock
                    trainsBlock
                }
            }
            .padding(.horizontal, DS.gutter)
            .padding(.bottom, 40)
            .readableColumn()
        }
        .background(DS.sheet)
        .navigationTitle("Trip Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let shareImage {
                    ShareLink(item: shareImage,
                              preview: SharePreview("Railly Passport", image: shareImage)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share Passport")
                }
            }
        }
    }

    private var tripsBlock: some View {
        StatBlock(title: "Trips") {
            BigNumber(value: "\(stats.trips)")
            VStack(alignment: .leading, spacing: 3) {
                countLine(stats.overnight, "overnight")
                countLine(stats.trips - stats.overnight, stats.trips - stats.overnight == 1 ? "day trip" : "day trips")
                countLine(stats.trainNumbers.count, stats.trainNumbers.count == 1 ? "train" : "different trains")
            }
            HStack(spacing: 4) {
                Text("TRIPS PER").eyebrow(DS.ink)
                    .padding(.trailing, 6)
                PeriodChip(title: "Weekday", selected: !perMonth) { perMonth = false }
                PeriodChip(title: "Month", selected: perMonth) { perMonth = true }
            }
            .padding(.top, 10)
            VerticalBars(bars: perMonth ? monthBars : weekdayBars, tint: DS.passport)
                .padding(.top, 4)
                .animation(.snappy(duration: 0.3), value: perMonth)
        }
    }

    private var distanceBlock: some View {
        let shortest = past.min { $0.train.distanceKm < $1.train.distanceKm }
        let longest = past.max { $0.train.distanceKm < $1.train.distanceKm }
        let months = monthCounts
        let maxKm = months.map(\.km).max() ?? 1
        return StatBlock(title: "Distance") {
            BigNumber(value: passportNumber(stats.distanceKm), unit: "km")
            Text("Average trip: \(passportNumber(stats.distanceKm / Double(max(1, stats.trips)))) km of track")
                .font(.dsCallout)
                .foregroundStyle(DS.ink2)
            VStack(spacing: 10) {
                ComparisonBar(icon: "map.fill", ratio: stats.distanceKm / 3_214,
                              label: "India, north to south")
                ComparisonBar(icon: "globe.asia.australia.fill", ratio: stats.aroundTheWorld,
                              label: "Around the Earth")
                ComparisonBar(icon: "moon.fill", ratio: stats.distanceKm / 384_400,
                              label: "To the Moon")
            }
            .padding(.top, 6)

            if months.count > 1 {
                Text("BY MONTH").eyebrow().padding(.top, 14)
                VStack(spacing: 9) {
                    ForEach(months, id: \.ym) { m in
                        HStack(spacing: 10) {
                            Text(monthLabel(m.ym))
                                .font(.dsCaption)
                                .foregroundStyle(DS.secondary)
                                .frame(width: 56, alignment: .leading)
                            GeometryReader { geo in
                                Capsule().fill(DS.passport)
                                    .frame(width: max(6, geo.size.width * m.km / max(1, maxKm)))
                            }
                            .frame(height: 8)
                            Text("\(passportNumber(m.km)) km")
                                .font(.dsCaption)
                                .foregroundStyle(DS.ink)
                                .monospacedDigit()
                                .frame(width: 76, alignment: .trailing)
                        }
                    }
                }
            }

            if let shortest, let longest {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shortest trip").font(.dsHeadline).foregroundStyle(DS.ink)
                    TripLine(trip: shortest, trailing: passportNumber(shortest.train.distanceKm),
                             trailingUnit: " km") { router.focus(shortest.id) }
                    Rectangle().fill(DS.separator).frame(height: 1).padding(.vertical, 6)
                    Text("Longest trip").font(.dsHeadline).foregroundStyle(DS.ink)
                    TripLine(trip: longest, trailing: passportNumber(longest.train.distanceKm),
                             trailingUnit: " km") { router.focus(longest.id) }
                }
                .padding(.top, 16)
            }
        }
    }

    private var timeBlock: some View {
        let mins = Double(stats.railMinutes)
        let longest = past.max { $0.train.destination.arrMin < $1.train.destination.arrMin }
        return StatBlock(title: "Rail Time") {
            (Text("\(stats.railMinutes / 60)").font(.system(size: 52, weight: .bold)).foregroundStyle(DS.ink)
                + Text("h ").font(.system(size: 30, weight: .semibold)).foregroundStyle(DS.tertiary)
                + Text("\(stats.railMinutes % 60)").font(.system(size: 52, weight: .bold)).foregroundStyle(DS.ink)
                + Text("m").font(.system(size: 30, weight: .semibold)).foregroundStyle(DS.tertiary))
                .monospacedDigit()
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                StatTile(label: "Days", value: String(format: "%.1f", mins / 1440))
                StatTile(label: "Weeks", value: String(format: "%.2f", mins / 10_080))
                StatTile(label: "Average trip", value: fmtDuration(mins / Double(max(1, stats.trips))))
                if let longest {
                    StatTile(label: "Longest trip",
                             value: fmtDuration(Double(longest.train.destination.arrMin)),
                             sub: "\(longest.train.origin.code)–\(longest.train.destination.code)")
                }
            }
            Text("Timetabled journey times. Delays are counted in the Delay Report.")
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
        }
    }

    private var routesBlock: some View {
        let routes = routeStats
        return StatBlock(title: "Top Routes") {
            BigNumber(value: "\(routes.count)", unit: routes.count == 1 ? "route" : "routes")
            VStack(spacing: 14) {
                ForEach(routes.prefix(5)) { r in
                    RankRow(title: r.id, subtitle: r.cities, count: r.count, top: routes[0].count)
                }
            }
            .padding(.top, 4)
        }
    }

    private var stationsBlock: some View {
        let stations = stationStats
        return StatBlock(title: "Top Stations") {
            BigNumber(value: "\(stations.count)", unit: stations.count == 1 ? "station" : "stations")
            VStack(spacing: 14) {
                ForEach(stations.prefix(5)) { s in
                    RankRow(title: s.city, subtitle: s.id, count: s.count, top: stations[0].count)
                }
            }
            .padding(.top, 4)
        }
    }

    private var trainsBlock: some View {
        let trains = trainStats
        let types = categoryStats
        return StatBlock(title: "Train Stats") {
            if let top = trains.first { mostRidden(top) }
            if trains.count > 1 {
                Text("TOP TRAINS").eyebrow().padding(.top, 12)
                VStack(spacing: 14) {
                    ForEach(trains.prefix(5)) { t in
                        RankRow(title: t.name, subtitle: t.id, count: t.count, top: trains[0].count,
                                mark: t.category)
                    }
                }
            }
            Text("BY TYPE").eyebrow().padding(.top, 12)
            VStack(spacing: 14) {
                ForEach(types, id: \.category) { c in
                    RankRow(title: c.category.label,
                            subtitle: "\(c.count) trip\(c.count == 1 ? "" : "s")",
                            count: c.count, top: types[0].count,
                            tint: c.category.liveryColor, mark: c.category)
                }
            }
        }
    }

    private func mostRidden(_ t: TrainStat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                TrainMark(category: t.category, size: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text("MOST-RIDDEN TRAIN").eyebrow()
                    Text(t.name)
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(t.id) · \(t.category.label)")
                        .font(.dsFootnote)
                        .foregroundStyle(DS.secondary)
                }
            }
            HStack(spacing: 0) {
                DSStat(label: "Trips", value: "\(t.count)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                DSStat(label: "Aboard", value: "\(passportNumber(t.km)) km")
                    .frame(maxWidth: .infinity, alignment: .leading)
                DSStat(label: "Rail time", value: fmtDuration(Double(t.minutes)))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsWell(radius: DS.cardRadius)
    }
}

// MARK: - Delay stats

/// The Delay Report: how often trips ran late, how late, the worst run, and
/// how each train performed.
struct DelayStatsView: View {
    let stats: LogStats
    let past: [HeldTrip]
    let period: String

    @EnvironmentObject private var router: Router

    private struct Bucket: Identifiable {
        let id: String
        let count: Int
        let onTime: Bool
    }

    private struct TrainPerf: Identifiable {
        let id: String
        let name: String
        let category: TrainCategory
        let trips: Int
        let late: Int
        let lostMinutes: Int
    }

    /// Anything short of every trip being feed-backed is at least partly a
    /// timetable projection, and the page says so.
    private var estimated: Bool { stats.measuredTrips < stats.trips }

    private var delays: [Int] { past.map(\.arrivalDelayMin) }

    private var buckets: [Bucket] {
        let d = delays
        func n(_ p: (Int) -> Bool) -> Int { d.filter(p).count }
        return [
            Bucket(id: "On time", count: n { $0 <= 5 }, onTime: true),
            Bucket(id: "6–15m late", count: n { $0 > 5 && $0 <= 15 }, onTime: false),
            Bucket(id: "16–30m late", count: n { $0 > 15 && $0 <= 30 }, onTime: false),
            Bucket(id: "31–60m late", count: n { $0 > 30 && $0 <= 60 }, onTime: false),
            Bucket(id: "60m+ late", count: n { $0 > 60 }, onTime: false),
        ]
    }

    private var trainPerf: [TrainPerf] {
        var byNumber: [String: TrainPerf] = [:]
        for t in past {
            let prev = byNumber[t.train.number]
            let d = t.arrivalDelayMin
            byNumber[t.train.number] = TrainPerf(
                id: t.train.number, name: t.train.displayName, category: t.train.category,
                trips: (prev?.trips ?? 0) + 1,
                late: (prev?.late ?? 0) + (d > 5 ? 1 : 0),
                lostMinutes: (prev?.lostMinutes ?? 0) + max(0, d))
        }
        return byNumber.values.sorted { $0.trips == $1.trips ? $0.late > $1.late : $0.trips > $1.trips }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if past.isEmpty {
                    Text("No completed trips to grade yet.")
                        .font(.dsCallout)
                        .foregroundStyle(DS.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else {
                    hero.padding(.top, 12)
                    performanceBlock
                    if stats.worstDelayMin > 0 { worstBlock }
                    trainBlock
                    if stats.refundEligible > 0 { refundNote }
                }
            }
            .padding(.horizontal, DS.gutter)
            .padding(.bottom, 40)
            .readableColumn()
        }
        .background(DS.sheet)
        .navigationTitle("Delay Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        let pct = Int((Double(stats.delayedTrips) / Double(max(1, stats.trips)) * 100).rounded())
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(periodTitle(period)) Delay Report")
                    .font(.dsHeadline)
                    .foregroundStyle(Livery.led)
                Rectangle().fill(Livery.led).frame(height: 2)
            }

            Text("\(pct)%")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .padding(.top, 18)
            Text("Trips delayed")
                .font(.dsTitle)
                .foregroundStyle(.white)
            Text("\(stats.delayedTrips) of \(stats.trips) trips arrived later than scheduled")
                .font(.dsFootnote)
                .foregroundStyle(Livery.delayLabel)
                .padding(.top, 2)

            SplitFlap(text: flapText(stats.lostMinutes))
                .padding(.top, 22)
            Text("Lost to Delays")
                .font(.dsTitle)
                .foregroundStyle(.white)
                .padding(.top, 14)
            Text(stats.delayedTrips > 0
                 ? "Delayed trips averaged \(stats.avgDelay)m late"
                 : "No time lost yet. May the signals stay green.")
                .font(.dsFootnote)
                .foregroundStyle(Livery.delayLabel)
                .padding(.top, 2)

            Text(stats.measuredTrips == 0
                 ? "Estimated from the timetable, not a live feed"
                 : "\(stats.measuredTrips) of \(stats.trips) trips measured from a live feed\(estimated ? ", the rest estimated from the timetable" : "")")
                .font(.dsCaption)
                .foregroundStyle(Livery.delayLabel.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Livery.delay, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var performanceBlock: some View {
        let avgAll = stats.lostMinutes / max(1, stats.trips)
        let total = max(1, stats.trips)
        return StatBlock(title: "My Performance", estimated: estimated) {
            BigNumber(value: "\(avgAll)m", unit: "late")
            Text("average arrival across \(stats.trips) trip\(stats.trips == 1 ? "" : "s")")
                .font(.dsCallout)
                .foregroundStyle(DS.secondary)
            VStack(spacing: 12) {
                ForEach(buckets) { b in
                    bucketRow(b, share: Double(b.count) / Double(total))
                }
            }
            .padding(.top, 8)
            Text("On time means within five minutes of the timetable, the same line the app draws between green and red.")
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
                .padding(.top, 4)
        }
    }

    private func bucketRow(_ b: Bucket, share: Double) -> some View {
        HStack(spacing: 12) {
            Text(b.id)
                .font(.dsSubhead)
                .foregroundStyle(DS.ink)
                .frame(width: 96, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.fill)
                    if b.count > 0 {
                        Capsule().fill(b.onTime ? DS.onTime : DS.late)
                            .frame(width: max(geo.size.height, geo.size.width * share))
                    }
                }
            }
            .frame(height: 16)
            Text("\(Int((share * 100).rounded()))%")
                .font(.dsSubhead)
                .foregroundStyle(b.count > 0 ? DS.ink : DS.tertiary)
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(b.id): \(b.count) trip\(b.count == 1 ? "" : "s"), \(Int((share * 100).rounded())) percent")
    }

    private var worstBlock: some View {
        let worst = past.first { $0.id == stats.worstTripId }
        let measured = worst.map { LiveFeed.shared.hasFeedData($0.train.number, $0.live.runDate) } ?? false
        return StatBlock(title: "Worst Delay", estimated: !measured) {
            LedStrip(minutes: stats.worstDelayMin, train: stats.worstTrain, route: stats.worstRoute)
            if let worst {
                TripLine(trip: worst, trailing: "+\(stats.worstDelayMin)", trailingUnit: "m") {
                    router.focus(worst.id)
                }
                .padding(.top, 4)
            }
        }
    }

    private var trainBlock: some View {
        let perf = trainPerf
        let late = perf.reduce(0) { $0 + $1.late }
        let pct = Int((Double(late) / Double(max(1, stats.trips)) * 100).rounded())
        return StatBlock(title: "Train Performance", estimated: estimated) {
            BigNumber(value: "\(pct)%", unit: "late arrivals")
            VStack(spacing: 18) {
                ForEach(perf.prefix(8)) { t in trainRow(t) }
            }
            .padding(.top, 6)
        }
    }

    private func trainRow(_ t: TrainPerf) -> some View {
        let share = Double(t.late) / Double(max(1, t.trips))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TrainMark(category: t.category, size: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(t.name)
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                    Text("\(t.id) · \(t.lostMinutes / t.trips)m late on average")
                        .font(.dsFootnote)
                        .foregroundStyle(DS.secondary)
                }
                Spacer(minLength: 8)
                (Text("\(Int((share * 100).rounded()))%").foregroundStyle(DS.ink)
                    + Text("  (\(t.late)/\(t.trips))").foregroundStyle(DS.tertiary))
                    .font(.dsSubhead)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(t.late == 0 ? DS.onTime.opacity(0.35) : DS.fill)
                    if t.late > 0 {
                        Capsule().fill(DS.late)
                            .frame(width: max(geo.size.height, geo.size.width * share))
                    }
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
    }

    private var refundNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("\(stats.refundEligible) trip\(stats.refundEligible == 1 ? "" : "s") ran 3h+ late, per the live feed",
                  systemImage: "indianrupeesign.circle.fill")
                .font(.dsHeadline)
                .foregroundStyle(DS.lateText)
            Text("Indian Railways refunds the full fare when a train runs more than three hours late and you choose not to travel, by filing a TDR before it departs.")
                .font(.dsFootnote)
                .foregroundStyle(DS.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.lateWash, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
        .padding(.top, 24)
    }
}
