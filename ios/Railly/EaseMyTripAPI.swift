import CommonCrypto
import Foundation

/// Free, live PNR status via EaseMyTrip's public rail endpoint — the second
/// rung of the PNR ladder, between ConfirmTkt and the paid indianrailapi.com.
/// No account or key: the site's own web client posts the PNR AES-128-CBC
/// encrypted (key == IV == "8080808080808080", PKCS7) and base64-encoded, and
/// gets back the booking picture. We fold it onto the erail schedule the same
/// way the other sources do.
///
///   POST https://railways.easemytrip.com/Train/PnrchkStatus
///   body: {"pnrNumber": "<base64(AES-128-CBC(pnr))>"}
enum EaseMyTripAPI {
    enum LookupError: Error {
        case crypto
        case network
    }

    struct EasePassenger {
        let booking: String
        let current: String
        let coach: String?
        let berth: Int?
        let bookingCoach: String?
        let bookingBerth: Int?
    }

    struct EaseTicket {
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
        let passengers: [EasePassenger]
    }

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 20
        return URLSession(configuration: cfg)
    }()

    static func pnrStatus(_ pnr: String) async throws -> EaseTicket {
        guard let cipher = encrypt(pnr) else { throw LookupError.crypto }
        guard let url = URL(string: "https://railways.easemytrip.com/Train/PnrchkStatus")
        else { throw LookupError.network }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("application/json", forHTTPHeaderField: "accept")
        req.setValue("https://www.easemytrip.com/", forHTTPHeaderField: "referer")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["pnrNumber": cipher])

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
        // URLSession doesn't throw on HTTP errors — never parse a 4xx/5xx body
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw LookupError.network
        }

        // Tolerant parsing: the schema is theirs to change, so pull fields
        // dynamically rather than trusting a rigid Codable shape.
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { throw LookupError.network }
        // some deployments nest the ticket under a payload key
        let box = (root["Data"] as? [String: Any])
            ?? (root["data"] as? [String: Any])
            ?? (root["PnrData"] as? [String: Any])
            ?? root

        guard let trainNo = str(box, "TrainNo", "TrainNumber", "trainNo"),
              !trainNo.isEmpty
        else { throw LookupError.network }

        let paxRaw = (box["PassengerStatus"] as? [[String: Any]])
            ?? (box["Passengers"] as? [[String: Any]])
            ?? (box["passengerList"] as? [[String: Any]])
            ?? []
        let passengers = paxRaw.map { p in
            EasePassenger(
                booking: str(p, "Booking_Status", "BookingStatus", "bookingStatus") ?? "",
                current: str(p, "Current_Status", "CurrentStatus", "currentStatus") ?? "",
                coach: str(p, "Coach", "CurrentCoach", "currentCoachId"),
                berth: posInt(p, "Berth", "CurrentBerthNo", "currentBerthNo"),
                bookingCoach: str(p, "BookingCoach", "bookingCoachId"),
                bookingBerth: posInt(p, "BookingBerthNo", "bookingBerthNo")
            )
        }
        // a real booking always carries passengers; an empty list means the
        // schema moved under us — fail honestly and let the next tier answer
        guard !passengers.isEmpty else { throw LookupError.network }

        return EaseTicket(
            trainNumber: trainNo,
            doj: normalizeDate(str(box, "Doj", "DateOfJourney", "doj")),
            boardingCode: code(str(box, "BoardingPoint", "BoardingStationCode", "boardingPoint")),
            resUptoCode: code(str(box, "ReservationUpto", "ReservationUptoCode", "reservationUpto")),
            fromCode: code(str(box, "From", "SourceStation", "from")),
            toCode: code(str(box, "To", "DestinationStation", "to")),
            journeyClass: str(box, "Class", "JourneyClass", "class") ?? "SL",
            quota: str(box, "Quota", "quota"),
            chartPrepared: chartFlag(box),
            passengers: passengers
        )
    }

    // MARK: crypto

    /// AES-128-CBC with key == IV == "8080808080808080" and PKCS7 padding, then
    /// base64 — exactly what EaseMyTrip's web client sends.
    private static func encrypt(_ plaintext: String) -> String? {
        let keyIV = Data("8080808080808080".utf8)   // 16 bytes, used as both key and IV
        let input = Data(plaintext.utf8)
        var output = Data(count: input.count + kCCBlockSizeAES128)
        var moved = 0
        let status = output.withUnsafeMutableBytes { outPtr in
            input.withUnsafeBytes { inPtr in
                keyIV.withUnsafeBytes { keyPtr in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyPtr.baseAddress, keyPtr.count,
                        keyPtr.baseAddress,               // IV == key
                        inPtr.baseAddress, inPtr.count,
                        outPtr.baseAddress, outPtr.count,
                        &moved)
                }
            }
        }
        guard status == CCCryptorStatus(kCCSuccess) else { return nil }
        output.removeSubrange(moved..<output.count)
        return output.base64EncodedString()
    }

    // MARK: dynamic-JSON helpers

    private static func str(_ dict: [String: Any], _ keys: String...) -> String? {
        for k in keys {
            let v = dict[k]
            if let s = v as? String {
                let t = s.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty { return t }
            } else if let n = v as? NSNumber {
                return n.stringValue
            }
        }
        return nil
    }

    private static func posInt(_ dict: [String: Any], _ keys: String...) -> Int? {
        for k in keys {
            if let n = dict[k] as? NSNumber, n.intValue > 0 { return n.intValue }
            if let s = dict[k] as? String, let i = Int(s.trimmingCharacters(in: .whitespaces)),
               i > 0 { return i }
        }
        return nil
    }

    private static func chartFlag(_ dict: [String: Any]) -> Bool {
        if let b = dict["ChartPrepared"] as? Bool { return b }
        let s = (str(dict, "ChartPrepared", "ChartStatus", "chartStatus") ?? "").uppercased()
        return s.contains("PREPARED") && !s.contains("NOT")
            || s == "YES" || s == "TRUE"
    }

    /// Best-effort station code from either a bare code ("BCT") or a
    /// "NAME [CODE]" label.
    private static func code(_ s: String?) -> String? {
        guard let s else { return nil }
        if let open = s.lastIndex(of: "["), let close = s.lastIndex(of: "]"), open < close {
            return String(s[s.index(after: open)..<close])
        }
        let up = s.trimmingCharacters(in: .whitespaces).uppercased()
        let looksLikeCode = up.count >= 2 && up.count <= 5
            && up.allSatisfy { $0.isLetter && $0.isUppercase }
        return looksLikeCode ? up : nil
    }

    /// Accepts "2024-02-13T00:00:00", "2024-02-13", or "13-02-2024" → "yyyy-MM-dd".
    private static func normalizeDate(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let head = String(raw.prefix(while: { $0 != "T" && $0 != " " }))
        let parts = head.split(separator: "-")
        guard parts.count == 3 else { return nil }
        if let y = Int(parts[0]), (2000...2200).contains(y),
           let m = Int(parts[1]), (1...12).contains(m),
           let d = Int(parts[2]), (1...31).contains(d) {
            return String(format: "%04d-%02d-%02d", y, m, d)   // already ISO
        }
        if let d = Int(parts[0]), (1...31).contains(d),
           let m = Int(parts[1]), (1...12).contains(m),
           let y = Int(parts[2]), (2000...2200).contains(y) {
            return String(format: "%04d-%02d-%02d", y, m, d)   // DMY
        }
        return nil
    }
}
