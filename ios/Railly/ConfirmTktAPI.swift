import Foundation

/// Free, live PNR status — the same public web API the confirmtkt.com PNR
/// page calls (static web apikey, no account, no paid plan). This is what
/// makes Railly's PNR checks REAL: booking + current status per passenger,
/// chart state, real fare, and the live coach formation string.
///
/// Captured by sniffing the site's own XHR (Jul 2026):
///   POST https://cttrainsapi.confirmtkt.com/api/v2/ctpro/mweb/{pnr}
///        ?querysource=ct-mweb&locale=en&getHighChanceText=true&livePnr=false
///   headers: apikey: ct-mweb!2$ · clientid: ct-mweb · deviceid: <uuid>
///   body: {"proPlanName":"CP7","emailId":"","tempToken":""}
/// Invalid/flushed PNRs come back inside `pnrResponse` with `error` +
/// `errorCode` (201 = flushed / not yet generated).
enum ConfirmTktAPI {
    enum LookupError: Error {
        /// The service answered and rejected the PNR — authoritative.
        case invalid(String)
        /// Couldn't reach or read the service.
        case network
    }

    struct RealPassenger {
        let booking: String
        let current: String
        let coach: String?
        let berth: Int?
        let bookingCoach: String?
        let bookingBerth: Int?
        /// ConfirmTkt's confirmation-chance text ("67% Chance")
        let prediction: String?
    }

    struct RealTicket {
        let trainNumber: String
        /// "yyyy-MM-dd"
        let doj: String?
        let boardingCode: String?
        let resUptoCode: String?
        let fromCode: String?
        let toCode: String?
        let journeyClass: String
        let quota: String?
        let chartPrepared: Bool
        /// whole-ticket fare in rupees, as charged
        let fare: Int?
        /// "L SLR UR S7 S6 … B1 A1" — the live rake formation
        let coachPosition: String?
        let passengers: [RealPassenger]
    }

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 20
        return URLSession(configuration: cfg)
    }()

    /// Stable per-install device id, as the web client sends.
    private static var deviceId: String {
        let key = "railly.ctkt.device"
        if let id = UserDefaults.standard.string(forKey: key) { return id }
        let id = UUID().uuidString.lowercased()
        UserDefaults.standard.set(id, forKey: key)
        return id
    }

    static func pnrStatus(_ pnr: String) async throws -> RealTicket {
        let urlStr = "https://cttrainsapi.confirmtkt.com/api/v2/ctpro/mweb/\(pnr)"
            + "?querysource=ct-mweb&locale=en&getHighChanceText=true&livePnr=false"
        guard let url = URL(string: urlStr) else { throw LookupError.network }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("ct-mweb!2$", forHTTPHeaderField: "apikey")
        req.setValue("ct-mweb", forHTTPHeaderField: "clientid")
        req.setValue(deviceId, forHTTPHeaderField: "deviceid")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("https://www.confirmtkt.com/", forHTTPHeaderField: "referer")
        req.httpBody = Data(#"{"proPlanName":"CP7","emailId":"","tempToken":""}"#.utf8)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch is CancellationError {
            throw CancellationError()
        } catch let e as URLError where e.code == .cancelled {
            throw CancellationError()
        } catch {
            throw LookupError.network
        }
        // URLSession doesn't throw on HTTP errors — don't parse a 4xx/5xx
        // body as if it were a booking
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw LookupError.network
        }

        // Tolerant parsing: the schema is theirs to change, so pull fields
        // dynamically instead of trusting a rigid Codable shape.
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataBox = root["data"] as? [String: Any],
              let resp = dataBox["pnrResponse"] as? [String: Any]
        else { throw LookupError.network }

        if let err = str(resp["error"]), !err.isEmpty {
            throw LookupError.invalid(err)
        }
        guard let trainNo = str(resp["trainNo"]), !trainNo.isEmpty else {
            throw LookupError.invalid("No booking found for this PNR")
        }

        let paxList = (resp["passengerStatus"] as? [[String: Any]] ?? []).map { p in
            RealPassenger(
                booking: str(p["bookingStatus"]) ?? "",
                current: str(p["currentStatus"]) ?? "",
                coach: firstNonEmpty(str(p["currentCoachId"]), str(p["coach"])),
                berth: posInt(p["currentBerthNo"]) ?? posInt(p["berth"]),
                bookingCoach: str(p["bookingCoachId"]),
                bookingBerth: posInt(p["bookingBerthNo"]),
                prediction: str(p["prediction"])
            )
        }
        // a real booking always carries passengers; an empty list means the
        // schema moved under us — fail honestly rather than render "NOT CNF"
        guard !paxList.isEmpty else { throw LookupError.network }

        return RealTicket(
            trainNumber: trainNo,
            doj: isoFromDMY(str(resp["doj"])),
            boardingCode: str(resp["boardingPoint"]),
            resUptoCode: str(resp["reservationUpto"]),
            fromCode: str(resp["from"]),
            toCode: str(resp["to"]),
            journeyClass: str(resp["class"]) ?? "SL",
            quota: str(resp["quota"]),
            chartPrepared: resp["chartPrepared"] as? Bool ?? false,
            fare: int(resp["ticketFare"]) ?? int(resp["bookingFare"]),
            coachPosition: str(resp["coachPosition"]),
            passengers: paxList
        )
    }

    // MARK: dynamic-JSON helpers

    private static func str(_ v: Any?) -> String? {
        if let s = v as? String {
            let t = s.trimmingCharacters(in: .whitespaces)
            return t.isEmpty ? nil : t
        }
        if let n = v as? NSNumber { return n.stringValue }
        return nil
    }

    private static func int(_ v: Any?) -> Int? {
        if let n = v as? NSNumber { return n.intValue }
        if let s = v as? String { return Int(s.trimmingCharacters(in: .whitespaces)) }
        return nil
    }

    /// Berth/seat numbers: the feed uses 0 for "not assigned yet".
    private static func posInt(_ v: Any?) -> Int? {
        int(v).flatMap { $0 > 0 ? $0 : nil }
    }

    private static func firstNonEmpty(_ vals: String?...) -> String? {
        vals.compactMap { $0 }.first { !$0.isEmpty && $0 != "-" }
    }

    /// "13-02-2024" → "2024-02-13". Strictly numeric: a malformed date must
    /// fall to nil, never poison a runDate (istDateTime traps on garbage).
    private static func isoFromDMY(_ s: String?) -> String? {
        let parts = (s ?? "").split(separator: "-")
        guard parts.count == 3,
              let d = Int(parts[0]), (1...31).contains(d),
              let m = Int(parts[1]), (1...12).contains(m),
              let y = Int(parts[2]), (2000...2200).contains(y)
        else { return nil }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
