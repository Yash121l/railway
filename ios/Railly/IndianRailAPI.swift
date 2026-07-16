import Foundation

/// Client for indianrailapi.com's **Live Train Status** — the only field that
/// isn't already real in Railly. Schedules/routes come from erail (RailAPI);
/// the moment-to-moment position + delay was simulated (Sim.swift). This feed
/// returns per-halt actual/scheduled times, delays, and a departed flag, which
/// we fold back into the same delay-walk the simulator produces so the whole
/// live picture (position, ETA, timeline) becomes real.
///
/// It's a paid, API-key service; the key lives in Settings (UserDefaults), and
/// everything degrades to the simulator when the key is absent or the call
/// fails, so the app always works offline.

/// A real running snapshot, reduced to what the delay-walk needs. Codable so
/// `LiveFeed` can persist the last one per run to disk.
struct LiveSnapshot: Codable {
    /// arrival delay in minutes, per station code
    let delayByCode: [String: Int]
    /// whether the train has already left each station
    let departedByCode: [String: Bool]
    let currentCode: String?
}

enum IndianRailAPI {
    static let keyDefault = "railly.indianrail.key"

    static var apiKey: String? {
        let k = UserDefaults.standard.string(forKey: keyDefault)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (k?.isEmpty == false) ? k : nil
    }

    static var isConfigured: Bool { apiKey != nil }

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    // MARK: Wire types (indianrailapi.com v2 livetrainstatus)

    private struct Response: Decodable {
        let ResponseCode: String?
        let TrainRoute: [Stn]?
        let CurrentStation: Stn?
        let Message: String?
    }
    private struct Stn: Decodable {
        let StationCode: String?
        let IsDeparted: String?
        let DelayInArrival: String?
        let DelayInDeparture: String?
    }

    /// GET the live status for a run. `runDate` is "yyyy-MM-dd" (IST).
    static func liveStatus(number: String, runDate: String) async throws -> LiveSnapshot {
        guard let key = apiKey else { throw RailError.notFound("live key") }
        let ymd = runDate.replacingOccurrences(of: "-", with: "")
        let urlStr = "https://indianrailapi.com/api/v2/livetrainstatus"
            + "/apikey/\(key)/trainnumber/\(number)/date/\(ymd)/"
        guard let url = URL(string: urlStr) else { throw RailError.badResponse }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) { throw RailError.badResponse }
        let resp = try JSONDecoder().decode(Response.self, from: data)
        guard resp.ResponseCode == "200", let route = resp.TrainRoute, !route.isEmpty else {
            throw RailError.notFound("live \(number)")
        }
        var delays: [String: Int] = [:]
        var departed: [String: Bool] = [:]
        for s in route {
            guard let code = s.StationCode, !code.isEmpty else { continue }
            delays[code] = parseDelayMinutes(s.DelayInArrival)
                ?? parseDelayMinutes(s.DelayInDeparture) ?? 0
            departed[code] = (s.IsDeparted == "1" || s.IsDeparted?.lowercased() == "true")
        }
        return LiveSnapshot(delayByCode: delays,
                            departedByCode: departed,
                            currentCode: resp.CurrentStation?.StationCode)
    }

    // MARK: PNR check (v2 PNRCheck)

    /// Wire shape per indianrailapi.com's own docs — note the API's real
    /// field names are misspelled ("ChatPrepared", "Passangers"); match them
    /// or nothing decodes.
    private struct PNRResponse: Decodable {
        let ResponseCode: String?
        let Status: String?
        let TrainNumber: String?
        let TrainName: String?
        let JourneyClass: String?
        let ChatPrepared: String?
        let From: String?
        let To: String?
        let JourneyDate: String?
        let Passangers: [PNRPax]?
    }
    struct PNRPax: Decodable {
        let Passenger: String?
        /// "CNF/S6/71/GN", "RLWL/-/16/GN" — status/coach/berth/quota
        let BookingStatus: String?
        let CurrentStatus: String?
    }

    struct RealPNR {
        let trainNumber: String
        let journeyClass: String
        let chartPrepared: Bool
        /// station codes pulled out of "NAME [CODE]"
        let fromCode: String?
        let toCode: String?
        /// "yyyy-MM-dd"
        let journeyDate: String?
        let passengers: [(booking: String, current: String)]
    }

    static func pnrCheck(_ pnr: String) async throws -> RealPNR {
        guard let key = apiKey else { throw RailError.notFound("live key") }
        let urlStr = "https://indianrailapi.com/api/v2/PNRCheck"
            + "/apikey/\(key)/PNRNumber/\(pnr)/"
        guard let url = URL(string: urlStr) else { throw RailError.badResponse }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) { throw RailError.badResponse }
        let resp = try JSONDecoder().decode(PNRResponse.self, from: data)
        guard resp.ResponseCode == "200", resp.Status == "SUCCESS",
              let trainNumber = resp.TrainNumber, !trainNumber.isEmpty
        else { throw RailError.notFound("PNR \(pnr)") }
        return RealPNR(
            trainNumber: trainNumber,
            journeyClass: resp.JourneyClass ?? "SL",
            chartPrepared: resp.ChatPrepared?.uppercased() == "YES",
            fromCode: bracketCode(resp.From),
            toCode: bracketCode(resp.To),
            journeyDate: isoFromDMY(resp.JourneyDate),
            passengers: (resp.Passangers ?? []).map {
                (booking: $0.BookingStatus ?? "", current: $0.CurrentStatus ?? "")
            }
        )
    }

    /// "SEALDAH [SDAH]" → "SDAH"
    private static func bracketCode(_ s: String?) -> String? {
        guard let s, let open = s.lastIndex(of: "["),
              let close = s.lastIndex(of: "]"), open < close else { return nil }
        return String(s[s.index(after: open)..<close])
    }

    /// "23-09-2018" → "2018-09-23". Strictly numeric so a malformed date can
    /// never poison a runDate (istDateTime traps on garbage).
    private static func isoFromDMY(_ s: String?) -> String? {
        let parts = (s ?? "").split(separator: "-")
        guard parts.count == 3,
              let d = Int(parts[0]), (1...31).contains(d),
              let m = Int(parts[1]), (1...12).contains(m),
              let y = Int(parts[2]), (2000...2200).contains(y)
        else { return nil }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    // MARK: Seat availability (v2 SeatAvailability — GN quota only)

    private struct AvailResponse: Decodable {
        let ResponseCode: String?
        let Availability: [AvailDay]?
    }
    private struct AvailDay: Decodable {
        let JourneyDate: String?
        let Availability: String?
    }

    /// Availability strings by "yyyy-MM-dd", as the PRS prints them
    /// ("AVAILABLE-0042", "GNWL21/WL9", …).
    static func seatAvailability(number: String, from: String, to: String,
                                 dateISO: String, jClass: String) async throws -> [String: String] {
        guard let key = apiKey else { throw RailError.notFound("live key") }
        let ymd = dateISO.replacingOccurrences(of: "-", with: "")
        let urlStr = "https://indianrailapi.com/api/v2/SeatAvailability"
            + "/apikey/\(key)/TrainNumber/\(number)/From/\(from)/To/\(to)"
            + "/Date/\(ymd)/Quota/GN/Class/\(jClass)/"
        guard let url = URL(string: urlStr) else { throw RailError.badResponse }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) { throw RailError.badResponse }
        let resp = try JSONDecoder().decode(AvailResponse.self, from: data)
        guard resp.ResponseCode == "200", let days = resp.Availability else {
            throw RailError.notFound("availability \(number)")
        }
        var out: [String: String] = [:]
        for d in days {
            if let iso = isoFromDMY(d.JourneyDate), let s = d.Availability {
                out[iso] = s
            }
        }
        return out
    }

    /// Parse the feed's delay field, which appears as minutes ("15"),
    /// "HH:MM" ("00:15"), or an on-time word.
    static func parseDelayMinutes(_ raw: String?) -> Int? {
        guard var s = raw?.trimmingCharacters(in: .whitespaces), !s.isEmpty else { return nil }
        let lower = s.lowercased()
        if lower.contains("right") || lower.contains("on time") || lower == "0" { return 0 }
        if s.contains(":") {
            let parts = s.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2 { return parts[0] * 60 + parts[1] }
        }
        s.removeAll { !$0.isNumber && $0 != "-" }
        return Int(s)
    }
}
