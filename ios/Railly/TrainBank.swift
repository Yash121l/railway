import Foundation

/// Resolved full trains (schedule + route + platforms), three layers deep:
/// bundled seeds → disk cache from past fetches → live erail fetch. Once a
/// train has been resolved it works offline forever.
@MainActor
final class TrainBank: ObservableObject {
    static let shared = TrainBank()

    @Published private(set) var trains: [String: Train] = [:]
    private var inflight: [String: Task<Train, Error>] = [:]

    /// numbers shipped in the seed cache, in curated order — the app's
    /// "popular trains" rail
    private(set) var seedNumbers: [String] = []

    private let cacheDir: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("TrainCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private init() {
        if let url = Bundle.main.url(forResource: "SeedTrains", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let seeds = try? JSONDecoder().decode([Train].self, from: data) {
            for t in seeds { trains[t.number] = t }
            seedNumbers = seeds.map(\.number)
        }
        // disk cache is fresher than the bundle — let it win
        if let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "json" {
                if let data = try? Data(contentsOf: file),
                   let t = try? JSONDecoder().decode(Train.self, from: data) {
                    trains[t.number] = t
                }
            }
        }
    }

    func cached(_ number: String) -> Train? { trains[number] }

    /// A fetched schedule older than this is refetched in the background on the
    /// next access — erail route/platform data drifts on the order of weeks.
    private let cacheTTL: TimeInterval = 21 * 24 * 3600

    /// Cached copy if present, else one deduplicated live fetch. A cached copy
    /// that has aged past the TTL is served immediately but revalidated in the
    /// background (stale-on-failure).
    func resolve(_ number: String, forceRefresh: Bool = false) async throws -> Train {
        if !forceRefresh, let t = trains[number] {
            if isStale(number) { revalidate(number) }
            return t
        }
        if let task = inflight[number] { return try await task.value }
        let task = Task { try await RailAPI.shared.fullTrain(number) }
        inflight[number] = task
        defer { inflight[number] = nil }
        do {
            let train = try await task.value
            trains[number] = train
            invalidateRunCache(number)
            persist(train)
            return train
        } catch {
            // a stale schedule beats an error screen
            if let t = trains[number] { return t }
            throw error
        }
    }

    /// When the cached JSON for a number was last written; nil for bundled
    /// seeds that were never fetched.
    private func cacheDate(_ number: String) -> Date? {
        let url = cacheDir.appendingPathComponent("\(number).json")
        return (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate
    }

    /// True once a fetched copy has aged past the TTL, or whenever we hold no
    /// copy at all. Seed-only trains (bundled, no disk file) count as fresh:
    /// curated seeds never hit the wire on their own.
    func isStale(_ number: String) -> Bool {
        // Holding nothing for this number means any trip on it renders as
        // nothing, so it is stale by definition. This is what makes "Clear
        // Route Cache" survivable: it empties `trains`, and cacheDate() then
        // returns nil, which used to read as "fresh" and skip the refetch.
        guard trains[number] != nil else { return true }
        guard let at = cacheDate(number) else { return false }
        return Date().timeIntervalSince(at) > cacheTTL
    }

    /// Refetch a stale schedule without blocking the caller; a failure leaves
    /// the cached copy untouched.
    private func revalidate(_ number: String) {
        guard inflight[number] == nil else { return }
        let task = Task { try await RailAPI.shared.fullTrain(number) }
        inflight[number] = task
        Task { @MainActor in
            defer { inflight[number] = nil }
            if let train = try? await task.value {
                trains[number] = train
                invalidateRunCache(number)
                persist(train)
            }
        }
    }

    private func persist(_ train: Train) {
        let url = cacheDir.appendingPathComponent("\(train.number).json")
        if let data = try? JSONEncoder().encode(train) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: Settings support

    var diskCacheCount: Int {
        (try? FileManager.default.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "json" }.count ?? 0
    }

    var diskCacheBytes: Int {
        ((try? FileManager.default.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: [.fileSizeKey])) ?? [])
            .compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }
            .reduce(0, +)
    }

    /// Drop fetched routes (bundled seeds survive; held trips refetch on view).
    func clearDiskCache() {
        if let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: nil) {
            for f in files { try? FileManager.default.removeItem(at: f) }
        }
        trains = [:]
        invalidateAllRunCache()
        if let url = Bundle.main.url(forResource: "SeedTrains", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let seeds = try? JSONDecoder().decode([Train].self, from: data) {
            for t in seeds { trains[t.number] = t }
        }
    }
}
