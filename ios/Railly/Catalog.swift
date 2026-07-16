import Foundation

/// Bundled offline index of the real IR network — every train and station,
/// straight from erail's own lookup assets. Search runs instantly on-device;
/// the network is only touched when a specific train's schedule is needed.

struct CatalogTrain: Identifiable {
    let number: String
    let rawName: String

    var id: String { number }
    var displayName: String { prettyTrainName(rawName) }
    var category: TrainCategory { categoryFor(name: rawName, type: "") }
}

struct CatalogStation: Codable, Identifiable {
    /// station code
    let c: String
    /// station name
    let n: String

    var id: String { c }
}

enum Catalog {
    static let trains: [CatalogTrain] = {
        guard let url = Bundle.main.url(forResource: "IRTrains", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return list.compactMap { entry in
            let parts = entry.split(separator: "-", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            return CatalogTrain(
                number: parts[0].trimmingCharacters(in: .whitespaces),
                rawName: parts[1].trimmingCharacters(in: .whitespaces)
            )
        }
        .sorted { $0.number < $1.number }
    }()

    static let stations: [CatalogStation] = {
        guard let url = Bundle.main.url(forResource: "Stations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([CatalogStation].self, from: data)
        else { return [] }
        return list
    }()

    static let stationCodes: Set<String> = Set(stations.map(\.c))

    /// Prefix matches first, then name-contains, then number-contains — so a
    /// name fragment ranks above a number's middle digits ("295" surfaces name
    /// hits before 22953).
    static func searchTrains(_ query: String, limit: Int = 30) -> [CatalogTrain] {
        let q = query.trimmingCharacters(in: .whitespaces).uppercased()
        guard !q.isEmpty else { return [] }
        var prefix: [CatalogTrain] = []
        var nameContains: [CatalogTrain] = []
        var numberContains: [CatalogTrain] = []
        for t in trains {
            if t.number.hasPrefix(q) || t.rawName.hasPrefix(q) {
                prefix.append(t)
            } else if t.rawName.contains(q) {
                nameContains.append(t)
            } else if t.number.contains(q) {
                numberContains.append(t)
            }
            if prefix.count >= limit { break }
        }
        return Array((prefix + nameContains + numberContains).prefix(limit))
    }

    static func searchStations(_ query: String, limit: Int = 12) -> [CatalogStation] {
        let q = query.trimmingCharacters(in: .whitespaces).uppercased()
        guard !q.isEmpty else { return [] }
        var codeHits: [CatalogStation] = []
        var nameHits: [CatalogStation] = []
        for s in stations {
            if s.c.hasPrefix(q) {
                codeHits.append(s)
            } else if s.n.uppercased().hasPrefix(q) || s.n.uppercased().contains(" " + q) {
                nameHits.append(s)
            }
            if codeHits.count >= limit { break }
        }
        return Array((codeHits + nameHits).prefix(limit))
    }
}

/// erail names arrive ALL-CAPS and clipped ("NDLS TEJAS RAJ", "BKN DURONTO
/// EXP"). Expand the standard railway abbreviations, keep station codes as
/// codes, and title-case the rest.
private let nameExpansions: [String: String] = [
    "EXP": "Express", "EXPRES": "Express", "EXPRESS": "Express",
    "SF": "Superfast", "SUP": "Superfast",
    "SPL": "Special", "SPECIA": "Special",
    "PASS": "Passenger", "PASSNG": "Passenger",
    "RAJ": "Rajdhani", "RAJDHN": "Rajdhani",
    "SHTBDI": "Shatabdi", "SHATAB": "Shatabdi",
    "JANSHT": "Jan Shatabdi", "JSHTBD": "Jan Shatabdi",
    "VB": "Vande Bharat",
    "INT": "Intercity", "INTERC": "Intercity",
    "GARIBRATH": "Garib Rath", "GRATH": "Garib Rath", "G": "Garib",
    "AC": "AC", "MEMU": "MEMU", "EMU": "EMU", "DEMU": "DEMU",
    "JN": "Jn", "TERM": "Terminus",
]

func prettyTrainName(_ raw: String) -> String {
    raw.split(separator: " ").map { token -> String in
        let word = String(token)
        if let expanded = nameExpansions[word] { return expanded }
        // station codes stay as codes ("NDLS Tejas Rajdhani")
        if word.count <= 5 && Catalog.stationCodes.contains(word) { return word }
        if word.count <= 2 { return word }
        return word.prefix(1) + word.dropFirst().lowercased()
    }
    .joined(separator: " ")
}
