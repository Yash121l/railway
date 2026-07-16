import SwiftUI

/// The Flighty Passport treatment — computed from the user's actual past
/// trips (real distances and durations from the live schedules).

struct LogStats {
    var trips = 0
    var overnight = 0
    var distanceKm = 0.0
    var railMinutes = 0
    var stationCodes = Set<String>()
    var trainNumbers = Set<String>()
    var lostMinutes = 0
    var delayedTrips = 0
    var worstDelayMin = 0
    var worstTrain = ""
    var worstRoute = ""
    /// trips that arrived 3h+ late — eligible for a full TDR refund
    var refundEligible = 0

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
            let arrDelay = trip.live.stopTimings[trip.live.stopTimings.count - 1].delayMin
            if arrDelay > 0 {
                s.lostMinutes += arrDelay
                s.delayedTrips += 1
                if arrDelay > s.worstDelayMin {
                    s.worstDelayMin = arrDelay
                    s.worstTrain = train.number
                    s.worstRoute = "\(train.origin.code)-\(train.destination.code)"
                }
            }
            if arrDelay >= 180 { s.refundEligible += 1 }
        }
        return s
    }
}

private func grouped(_ n: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: n)) ?? "0"
}

/// "42MIN" under an hour, "2H05M" above.
private func flapText(_ minutes: Int) -> String {
    minutes < 60
        ? String(format: "%02dMIN", minutes)
        : String(format: "%dH%02dM", minutes / 60, minutes % 60)
}

private struct SplitFlap: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                let ghost = ch.isLetter
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(LinearGradient(
                            colors: [Color(hex: 0x3A0F08), Color(hex: 0x2B0A05), Color(hex: 0x200704)],
                            startPoint: .top, endPoint: .bottom
                        ))
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .frame(height: 1.5)
                    Text(String(ch))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(ghost ? Color.white.opacity(0.32) : Color(hex: 0xFDF3E7))
                }
                .frame(width: 44, height: 62)
            }
        }
    }
}

private struct StatsButton: View {
    let label: String
    var dark = false

    var body: some View {
        HStack {
            Text(label).font(.system(size: 16, weight: .semibold))
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(dark ? Color(hex: 0x2D2A66) : .white)
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(dark ? Color.black.opacity(0.12) : Color.white.opacity(0.15))
        )
        .padding(.top, 14)
    }
}

private struct PassportCard: View {
    let stats: LogStats
    let past: [HeldTrip]
    let mrzName: String
    var shareImage: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("ALL-TIME RAILLY PASSPORT")
                    .font(.system(size: 17, weight: .semibold))
                    .kerning(1)
                    .foregroundStyle(.white)
                Spacer()
                if let shareImage {
                    ShareLink(item: shareImage,
                              preview: SharePreview("Railly Passport", image: shareImage)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        Analytics.shared.log(.shareCardSent, ["card": "passport"])
                    })
                }
            }
            Text("PASSPORT • PASS • पासपोर्ट")
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.4)
                .foregroundStyle(Color(hex: 0xA9A3E8))
                .padding(.top, 3)

            Text("DISTANCE")
                .font(.system(size: 11, weight: .bold)).kerning(1)
                .foregroundStyle(Color(hex: 0xA9A3E8))
                .padding(.top, 22)
            (Text("\(grouped(stats.distanceKm)) ").font(.system(size: 38, weight: .heavy))
                + Text("km").font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(hex: 0xA9A3E8)))
                .foregroundStyle(.white)
            Text(String(format: "%.2fx around the world", stats.aroundTheWorld))
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0xA9A3E8))

            HStack(spacing: 34) {
                passportStat("TRIPS", "\(stats.trips)",
                             sub: stats.overnight > 0 ? "\(stats.overnight) overnight" : nil)
                passportStat("RAIL TIME", "\(stats.railMinutes / 60)h")
            }
            .padding(.top, 20)
            HStack(spacing: 34) {
                passportStat("STATIONS", "\(stats.stationCodes.count)")
                passportStat("TRAINS", "\(stats.trainNumbers.count)")
            }
            .padding(.top, 14)

            // machine-readable zone, like the real passport page
            VStack(alignment: .leading, spacing: 2) {
                Rectangle()
                    .fill(Color(hex: 0xA9A3E8).opacity(0.35))
                    .frame(height: 1)
                    .padding(.bottom, 8)
                Text(mrzHeaderLine)
                Text(mrzLine)
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.55))
            .kerning(1.2)
            .lineLimit(1)
            .padding(.top, 18)

            NavigationLink {
                TripStatsView(stats: stats, past: past)
            } label: {
                StatsButton(label: "All Trip Stats")
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [Color(hex: 0x14104B), Color(hex: 0x5A3FD6)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
    }

    private var mrzHeaderLine: String {
        let raw = "ALLTIME<<\(mrzName)<<MEMBER<<RAILLY"
        return String(raw.padding(toLength: 43, withPad: "<", startingAt: 0))
    }

    private var mrzLine: String {
        let raw = "\(istDateISO(Date()).replacingOccurrences(of: "-", with: ""))"
            + "\(stats.trips)TRIPS\(grouped(stats.distanceKm).replacingOccurrences(of: ",", with: ""))KM"
            + "<<<<\(stats.railMinutes / 60)H<<\(stats.stationCodes.count)STN<<\(stats.trainNumbers.count)TRN"
        return String(raw.padding(toLength: 43, withPad: "<", startingAt: 0))
    }

    private func passportStat(_ label: String, _ value: String, sub: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .bold)).kerning(1)
                .foregroundStyle(Color(hex: 0xA9A3E8))
            Text(value)
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(.white)
            if let sub {
                Text(sub).font(.system(size: 12)).foregroundStyle(Color(hex: 0xA9A3E8))
            }
        }
    }
}

private struct DelayCard: View {
    let stats: LogStats
    let past: [HeldTrip]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SplitFlap(text: flapText(stats.lostMinutes))
            Text("Lost to Delays")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 18)
            Text(stats.delayedTrips > 0
                ? "Delayed trips averaged \(stats.avgDelay)m late · \(stats.delayedTrips) of \(stats.trips) trips delayed"
                : "No time lost yet — may the signals stay green")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0xC98F85))
                .padding(.top, 2)

            if stats.refundEligible > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.system(size: 13))
                    Text("\(stats.refundEligible) trip\(stats.refundEligible == 1 ? "" : "s") ran 3h+ late — eligible for a full TDR refund")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color(hex: 0xFFB020))
                .padding(.top, 10)
            }

            if stats.worstDelayMin > 0 {
                HStack {
                    Text(flapText(stats.worstDelayMin))
                    Spacer()
                    Text(stats.worstTrain)
                    Spacer()
                    Text(stats.worstRoute)
                }
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .kerning(2)
                .foregroundStyle(Color(hex: 0xFFB020))
                .shadow(color: Color(hex: 0xFFB020).opacity(0.65), radius: 5)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0x1E0602)))
                .padding(.top, 16)

                Text("WORST DELAY")
                    .font(.system(size: 11, weight: .bold)).kerning(1)
                    .foregroundStyle(Color(hex: 0xC98F85))
                    .padding(.top, 8)
            }

            NavigationLink {
                DelayStatsView(stats: stats, past: past)
            } label: {
                StatsButton(label: "All Delay Stats")
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [Color(hex: 0x140302), Color(hex: 0x5A0E0E), Color(hex: 0x7A1E14)],
                    startPoint: .top, endPoint: .bottom
                ))
        )
    }
}

struct LogbookView: View {
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @State private var showSettings = false
    // nil = every year; otherwise a "yyyy" prefix filtering the past list
    @State private var yearFilter: String?
    @State private var passportImage: Image?
    @AppStorage("railly.profileName") private var profileName = ""

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { ctx in
                let now = ctx.date
                let past = store.myTrips(now, bank: bank).past
                let stats = LogStats.compute(past)
                let years = Array(Set(past.map { String($0.live.runDate.prefix(4)) })).sorted(by: >)
                let shownPast = yearFilter.map { y in
                    past.filter { $0.live.runDate.hasPrefix(y) }
                } ?? past

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 13) {
                            Button {
                                showSettings = true
                            } label: {
                                Text(profileAvatarInitial(profileName))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x2563AB))
                                    .frame(width: 54, height: 54)
                                    .background(Color(hex: 0xCFE3F8), in: Circle())
                            }
                            .buttonStyle(.plain)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(profileDisplayName(profileName))
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(Color.inkline)
                                Text("My Trip Log")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.subGray)
                            }
                        }

                        yearChips(years)
                            .padding(.top, 16)

                        VStack(spacing: 15) {
                            PassportCard(stats: stats, past: past,
                                         mrzName: profileMRZName(profileName),
                                         shareImage: passportImage)
                            DelayCard(stats: stats, past: past)
                        }
                        .padding(.top, 16)

                        Text("Past Trips")
                            .font(.system(size: 23, weight: .bold))
                            .foregroundStyle(Color.inkline)
                            .padding(.top, 26)

                        if shownPast.isEmpty {
                            Text(yearFilter == nil
                                ? "Completed trips land here and build your passport."
                                : "No trips in \(yearFilter!).")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.fadedGray)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 24)
                        }

                        ForEach(shownPast) { trip in
                            NavigationLink(value: trip.id) {
                                pastRow(trip)
                            }
                            .buttonStyle(.pressableRow)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
                .background(Color.white)
                .task(id: "\(stats.trips)|\(Int(stats.distanceKm))|\(stats.stationCodes.count)|\(stats.trainNumbers.count)|\(profileName)") {
                    passportImage = renderPassportShareCard(
                        stats: stats, mrzName: profileMRZName(profileName))
                }
            }
            .navigationDestination(for: String.self) { id in
                TripDetailView(id: id)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    /// The "ALL-TIME" pill clears the filter; the year chip is a live menu of
    /// the years actually present in the log.
    @ViewBuilder
    private func yearChips(_ years: [String]) -> some View {
        HStack(spacing: 10) {
            Button {
                yearFilter = nil
            } label: {
                Text("ALL-TIME")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(yearFilter == nil ? Color.inkline : Color.fadedGray)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(yearFilter == nil ? Color.fillGray : Color.clear,
                                in: RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)

            if !years.isEmpty {
                Menu {
                    Button("All Years") { yearFilter = nil }
                    Divider()
                    ForEach(years, id: \.self) { y in
                        Button(y) { yearFilter = y }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(yearFilter ?? "By Year")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 14, weight: yearFilter == nil ? .regular : .semibold))
                    .foregroundStyle(yearFilter == nil ? Color.fadedGray : Color.inkline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(yearFilter == nil ? Color.clear : Color.fillGray,
                                in: RoundedRectangle(cornerRadius: 11))
                }
            }
        }
    }

    private func pastRow(_ trip: HeldTrip) -> some View {
        HStack(spacing: 11) {
            TrainMark(category: trip.train.category, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 7) {
                    Text(trip.train.number)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subGray)
                        .monospacedDigit()
                    Text("\(trip.train.origin.code) → \(trip.train.destination.code)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fadedGray)
                    Spacer()
                    Text(fmtDay(trip.live.arrivesEst))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subGray)
                }
                Text("\(cityFor(trip.train.origin.code, trip.train.origin.name)) to \(cityFor(trip.train.destination.code, trip.train.destination.name))")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.inkline)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }
}

// MARK: - Stats detail screens

private func monthLabel(_ ym: String) -> String {
    let parts = ym.split(separator: "-")
    guard parts.count == 2, let m = Int(parts[1]), (1...12).contains(m) else { return ym }
    let names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return "\(names[m - 1]) '\(parts[0].suffix(2))"
}

/// The passport, unfolded: distance by month, the routes and trains ridden
/// most, and the single longest ride — all in the indigo passport livery.
struct TripStatsView: View {
    let stats: LogStats
    let past: [HeldTrip]

    private let accent = Color(hex: 0xA9A3E8)

    private struct MonthDistance: Identifiable { let id: String; let label: String; let km: Double }
    private struct RouteStat: Identifiable { let id: String; let label: String; let count: Int; let km: Double }
    private struct TrainStat: Identifiable { let id: String; let name: String; let category: TrainCategory; let count: Int }

    private var monthStats: [MonthDistance] {
        var map: [String: Double] = [:]
        for t in past { map[String(t.live.runDate.prefix(7)), default: 0] += t.train.distanceKm }
        return map.keys.sorted().map { MonthDistance(id: $0, label: monthLabel($0), km: map[$0]!) }
    }

    private var routeStats: [RouteStat] {
        var count: [String: Int] = [:]
        var km: [String: Double] = [:]
        var label: [String: String] = [:]
        for t in past {
            let key = "\(t.train.origin.code)-\(t.train.destination.code)"
            count[key, default: 0] += 1
            km[key, default: 0] += t.train.distanceKm
            label[key] = "\(cityFor(t.train.origin.code, t.train.origin.name)) → \(cityFor(t.train.destination.code, t.train.destination.name))"
        }
        return count.keys
            .map { RouteStat(id: $0, label: label[$0] ?? $0, count: count[$0]!, km: km[$0]!) }
            .sorted { $0.count == $1.count ? $0.km > $1.km : $0.count > $1.count }
    }

    private var trainStats: [TrainStat] {
        var count: [String: Int] = [:]
        var meta: [String: (String, TrainCategory)] = [:]
        for t in past {
            count[t.train.number, default: 0] += 1
            meta[t.train.number] = (t.train.displayName, t.train.category)
        }
        return count.keys
            .map { TrainStat(id: $0, name: meta[$0]!.0, category: meta[$0]!.1, count: count[$0]!) }
            .sorted { $0.count > $1.count }
    }

    private var longest: HeldTrip? { past.max { $0.train.distanceKm < $1.train.distanceKm } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if past.isEmpty {
                    Text("Finish a trip and its numbers land here.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.subGray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else {
                    distanceCard
                    routesCard
                    trainsCard
                    if let longest { longestCard(longest) }
                }
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .navigationTitle("All Trip Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold)).kerning(1)
                .foregroundStyle(accent)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [Color(hex: 0x14104B), Color(hex: 0x5A3FD6)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
    }

    private var distanceCard: some View {
        let maxKm = monthStats.map(\.km).max() ?? 1
        return card("Distance by Month") {
            VStack(spacing: 10) {
                ForEach(monthStats) { m in
                    HStack(spacing: 10) {
                        Text(m.label)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(accent)
                            .frame(width: 62, alignment: .leading)
                        GeometryReader { geo in
                            Capsule().fill(.white.opacity(0.9))
                                .frame(width: max(6, geo.size.width * (m.km / maxKm)))
                        }
                        .frame(height: 10)
                        Text(grouped(m.km))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .frame(width: 54, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var routesCard: some View {
        card("Top Routes") {
            VStack(spacing: 12) {
                ForEach(Array(routeStats.prefix(5))) { r in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.label)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text("\(grouped(r.km)) km")
                                .font(.system(size: 12))
                                .foregroundStyle(accent)
                        }
                        Spacer()
                        Text("\(r.count)×")
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private var trainsCard: some View {
        card("Top Trains") {
            VStack(spacing: 12) {
                ForEach(Array(trainStats.prefix(5))) { t in
                    HStack(spacing: 11) {
                        TrainMark(category: t.category, size: 30)
                        Text(t.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text("\(t.count)×")
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private func longestCard(_ trip: HeldTrip) -> some View {
        card("Longest Ride") {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(cityFor(trip.train.origin.code, trip.train.origin.name)) → \(cityFor(trip.train.destination.code, trip.train.destination.name))")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 28) {
                    statChip("\(grouped(trip.train.distanceKm)) km", "DISTANCE")
                    statChip(fmtDuration(Double(trip.train.destination.arrMin)), "DURATION")
                }
            }
        }
    }

    private func statChip(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 20, weight: .heavy)).foregroundStyle(.white)
            Text(label).font(.system(size: 10, weight: .bold)).kerning(1).foregroundStyle(accent)
        }
    }
}

/// The delay ledger: total time lost, a histogram of how late arrivals ran,
/// and the single worst offender — in the split-flap delay livery.
struct DelayStatsView: View {
    let stats: LogStats
    let past: [HeldTrip]

    private let accent = Color(hex: 0xC98F85)
    private let flapAmber = Color(hex: 0xFFB020)

    private struct Bucket: Identifiable { let id: String; let label: String; let count: Int }

    private var arrivalDelays: [Int] { past.map { $0.live.stopTimings.last?.delayMin ?? 0 } }

    private var buckets: [Bucket] {
        let d = arrivalDelays
        func n(_ p: (Int) -> Bool) -> Int { d.filter(p).count }
        return [
            Bucket(id: "ot", label: "On time", count: n { $0 <= 5 }),
            Bucket(id: "a", label: "6–15m", count: n { $0 > 5 && $0 <= 15 }),
            Bucket(id: "b", label: "16–30m", count: n { $0 > 15 && $0 <= 30 }),
            Bucket(id: "c", label: "31–60m", count: n { $0 > 30 && $0 <= 60 }),
            Bucket(id: "d", label: "60m+", count: n { $0 > 60 }),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if past.isEmpty {
                    Text("No completed trips to grade yet.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.subGray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else {
                    summaryCard
                    histogramCard
                    if stats.worstDelayMin > 0 { worstCard }
                }
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .navigationTitle("All Delay Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(
                        colors: [Color(hex: 0x140302), Color(hex: 0x5A0E0E), Color(hex: 0x7A1E14)],
                        startPoint: .top, endPoint: .bottom
                    ))
            )
    }

    private var summaryCard: some View {
        let onTime = arrivalDelays.filter { $0 <= 5 }.count
        let rate = past.isEmpty ? 0 : Int((Double(onTime) / Double(past.count) * 100).rounded())
        return card {
            SplitFlap(text: flapText(stats.lostMinutes))
            Text("Lost to Delays")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 2)
            HStack(spacing: 26) {
                delayStat("\(rate)%", "ON TIME")
                delayStat("\(stats.avgDelay)m", "AVG WHEN LATE")
                delayStat("\(stats.delayedTrips)", "TRIPS LATE")
            }
            .padding(.top, 6)
        }
    }

    private var histogramCard: some View {
        let maxCount = max(1, buckets.map(\.count).max() ?? 1)
        return card {
            Text("DELAY HISTOGRAM")
                .font(.system(size: 12, weight: .bold)).kerning(1)
                .foregroundStyle(accent)
            VStack(spacing: 10) {
                ForEach(buckets) { b in
                    HStack(spacing: 10) {
                        Text(b.label)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(accent)
                            .frame(width: 64, alignment: .leading)
                        GeometryReader { geo in
                            Capsule().fill(flapAmber)
                                .frame(width: b.count == 0 ? 0
                                    : max(6, geo.size.width * (Double(b.count) / Double(maxCount))))
                        }
                        .frame(height: 10)
                        Text("\(b.count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var worstCard: some View {
        card {
            Text("WORST DELAY")
                .font(.system(size: 12, weight: .bold)).kerning(1)
                .foregroundStyle(accent)
            HStack {
                Text(flapText(stats.worstDelayMin))
                Spacer()
                Text(stats.worstTrain)
                Spacer()
                Text(stats.worstRoute)
            }
            .font(.system(size: 15, weight: .bold, design: .monospaced))
            .kerning(2)
            .foregroundStyle(flapAmber)
            .shadow(color: flapAmber.opacity(0.65), radius: 5)
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0x1E0602)))
        }
    }

    private func delayStat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 22, weight: .heavy)).foregroundStyle(.white)
            Text(label).font(.system(size: 9, weight: .bold)).kerning(0.8).foregroundStyle(accent)
        }
    }
}
