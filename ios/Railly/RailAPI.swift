import Foundation

/// Client for erail.in — the same unofficial Indian Railways feed the erail
/// website itself runs on. Two endpoints: `getTrains.aspx` (train lookup and
/// trains-between-stations; `~`-delimited fields, `^`-delimited rows) and
/// `data.aspx?Action=TRAINROUTE` (full route with real times, platforms and
/// coordinates). Field indices mirror the constants in erail's own JS.

enum RailError: LocalizedError {
    case throttled
    case badResponse
    case notFound(String)
    case sourceDrifted

    var errorDescription: String? {
        switch self {
        case .throttled:
            return "The railway data service is busy. Try again in a minute."
        case .badResponse:
            return "Couldn't read the railway data feed."
        case .notFound(let q):
            return "No schedule found for \(q)."
        case .sourceDrifted:
            return "The schedule source changed format — we're on it. Try again later."
        }
    }
}

/// One row of a getTrains.aspx response. For a number lookup, from/to equal
/// origin/destination; for a between-stations search they are the queried leg.
struct TrainSummary: Identifiable {
    let number: String
    let name: String
    let originCode: String
    let originName: String
    let destCode: String
    let destName: String
    let fromCode: String
    let fromName: String
    let toCode: String
    let toName: String
    /// "HH:MM" at the from-station / to-station, IST
    let departure: String
    let arrival: String
    /// "HH:MM" total for the queried leg
    let travelTime: String
    let days: [Day]
    let trainId: Int
    let typeName: String
    let distanceKm: Double
    let classes: [String]

    var id: String { number }
    var displayName: String { prettyTrainName(name) }
    var category: TrainCategory { categoryFor(name: name, type: typeName) }
}

func categoryFor(name: String, type: String) -> TrainCategory {
    let n = name.uppercased()
    let t = type.uppercased()
    if n.contains("VANDE BHARAT") { return .vandeBharat }
    if t.contains("RAJDHANI") || n.contains("RAJDHANI") || n.hasSuffix(" RAJ") { return .rajdhani }
    if t.contains("SHATABDI") || n.contains("SHATABDI") || n.contains("SHTBDI") { return .shatabdi }
    if t.contains("DURONTO") || n.contains("DURONTO") { return .duronto }
    if n.contains("TEJAS") { return .tejas }
    if t.contains("SUPERFAST") || n.contains(" SF ") || n.hasSuffix(" SF EXP") { return .superfast }
    return .express
}

final class RailAPI {
    static let shared = RailAPI()

    // getTrains.aspx row fields (T_* in erail's JS)
    private enum T {
        static let no = 0, name = 1
        static let stnFirstName = 2, stnFirst = 3, stnLastName = 4, stnLast = 5
        static let stnFromName = 6, stnFrom = 7, stnToName = 8, stnTo = 9
        static let departure = 10, arrival = 11, travel = 12, runDays = 13
        static let classes = 21, trainType = 32, trainId = 33, distance = 39
    }

    // TRAINROUTE row fields (TR_* in erail's JS)
    private enum TR {
        static let code = 1, name = 2
        /// cumulative track km from the origin
        static let distance = 6
        static let platform = 8
        static let lat = 14, lng = 15, arrMin = 16, depMin = 17
    }

    /// erail's class bitmask order, from its language file
    static let classOrder = ["1A", "2A", "3A", "CC", "FC", "SL", "2S",
                             "3E", "GN", "EA", "EC", "EV", "VC", "VS"]

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        cfg.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15",
        ]
        return URLSession(configuration: cfg)
    }()

    private func fetch(_ urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { throw RailError.badResponse }
        let (data, _) = try await session.data(from: url)
        guard let text = String(data: data, encoding: .utf8) else {
            throw RailError.badResponse
        }
        if text.contains("Please try again") { throw RailError.throttled }
        return text
    }

    private func parseSummary(_ fields: [String]) -> TrainSummary? {
        guard fields.count > T.distance,
              !fields[T.no].isEmpty,
              fields[T.no].allSatisfy(\.isNumber)
        else { return nil }
        let bits = Array(fields[T.runDays])
        let monFirst: [Day] = [.mon, .tue, .wed, .thu, .fri, .sat, .sun]
        let days = monFirst.enumerated().compactMap { i, d in
            i < bits.count && bits[i] == "1" ? d : nil
        }
        let classBits = Array(fields[T.classes])
        let classes = RailAPI.classOrder.enumerated().compactMap { i, c in
            i < classBits.count && classBits[i] == "1" ? c : nil
        }
        return TrainSummary(
            number: fields[T.no],
            name: fields[T.name],
            originCode: fields[T.stnFirst], originName: fields[T.stnFirstName],
            destCode: fields[T.stnLast], destName: fields[T.stnLastName],
            fromCode: fields[T.stnFrom], fromName: fields[T.stnFromName],
            toCode: fields[T.stnTo], toName: fields[T.stnToName],
            departure: fields[T.departure].replacingOccurrences(of: ".", with: ":"),
            arrival: fields[T.arrival].replacingOccurrences(of: ".", with: ":"),
            travelTime: fields[T.travel].replacingOccurrences(of: ".", with: ":"),
            days: days,
            trainId: Int(fields[T.trainId]) ?? 0,
            typeName: fields[T.trainType],
            distanceKm: Double(fields[T.distance]) ?? 0,
            classes: classes
        )
    }

    private func summaries(from response: String) -> [TrainSummary] {
        response.split(separator: "^").compactMap {
            parseSummary($0.components(separatedBy: "~"))
        }
    }

    /// Exact-number lookup: full metadata incl. the internal route id.
    func trainInfo(_ number: String) async throws -> TrainSummary {
        let text = try await fetch(
            "https://erail.in/rail/getTrains.aspx?TrainNo=\(number)&DataSource=0&Language=0&Cache=true")
        guard let summary = summaries(from: text).first(where: { $0.number == number })
        else { throw RailError.notFound("train \(number)") }
        return summary
    }

    /// Every train running between two station codes.
    func trainsBetween(_ from: String, _ to: String) async throws -> [TrainSummary] {
        let text = try await fetch(
            "https://erail.in/rail/getTrains.aspx?Station_From=\(from)&Station_To=\(to)&DataSource=0&Language=0&Cache=true")
        let rows = summaries(from: text)
        if rows.isEmpty { throw RailError.notFound("trains \(from) → \(to)") }
        return rows
    }

    /// Full route: real halt times (as minute offsets from origin departure),
    /// platforms, and station coordinates.
    func route(trainId: Int) async throws -> [Stop] {
        let text = try await fetch(
            "https://erail.in/data.aspx?Action=TRAINROUTE&Password=2012&Data1=\(trainId)&Data2=0&Cache=true")
        var stops: [Stop] = []
        for row in text.split(separator: "^") {
            let f = row.components(separatedBy: "~")
            guard f.count > TR.depMin,
                  let lat = Double(f[TR.lat]), let lng = Double(f[TR.lng]),
                  let arrMin = Int(f[TR.arrMin])
            else { continue }
            let pf = f[TR.platform].trimmingCharacters(in: .whitespaces)
            // The guard above already proves this index exists (depMin is 17).
            let km = Double(f[TR.distance].trimmingCharacters(in: .whitespaces))
            stops.append(Stop(
                name: f[TR.name].trimmingCharacters(in: .whitespaces),
                code: f[TR.code].trimmingCharacters(in: .whitespaces),
                lat: lat, lng: lng,
                arrMin: arrMin,
                depMin: Int(f[TR.depMin]) ?? arrMin,
                platform: (pf.isEmpty || pf == "0") ? nil : pf,
                distanceKm: (km.map { $0 >= 0 } ?? false) ? km : nil
            ))
        }
        guard stops.count >= 2 else { throw RailError.badResponse }
        try assertSchemaSane(stops)
        return stops
    }

    /// erail's TRAINROUTE columns are positional; if the feed reorders them the
    /// parse yields plausible-looking garbage. Sanity-check the decoded route
    /// and surface an honest "source drifted" error rather than rendering it.
    private func assertSchemaSane(_ stops: [Stop]) throws {
        // station codes are 2–5 uppercase letters; tolerate the odd oddball but
        // treat wholesale failure as a reordered schema
        let codeOK: (String) -> Bool = { code in
            let n = code.count
            return n >= 2 && n <= 5 && code.allSatisfy { $0.isUppercase && $0.isLetter }
        }
        let badCodes = stops.filter { !codeOK($0.code) }.count
        guard badCodes <= stops.count / 5 else { throw RailError.sourceDrifted }
        // minute offsets must be non-negative, halts under a day, and never run
        // backwards down the route
        var prevDep = 0
        for (i, s) in stops.enumerated() {
            guard s.arrMin >= 0, s.depMin >= s.arrMin, s.depMin - s.arrMin <= 1439
            else { throw RailError.sourceDrifted }
            if i > 0 { guard s.arrMin >= prevDep else { throw RailError.sourceDrifted } }
            prevDep = s.depMin
        }
    }

    /// Lookup + route composed into the app's Train model.
    func fullTrain(_ number: String) async throws -> Train {
        let info = try await trainInfo(number)
        let stops = try await route(trainId: info.trainId)
        return Train(
            number: info.number,
            name: info.name,
            category: info.category,
            departureTime: info.departure,
            days: info.days,
            // Real track km where the feed gives it, straight-chord only as a
            // last resort — see RailRoute, which every derived number rides on.
            distanceKm: info.distanceKm > 0
                ? info.distanceKm
                : (stops.last?.distanceKm ?? cumulativeKm(stops).last ?? 0),
            stops: stops,
            trainId: info.trainId,
            typeName: info.typeName,
            classes: info.classes
        )
    }
}
