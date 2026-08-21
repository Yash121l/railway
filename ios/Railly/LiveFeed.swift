import Foundation

/// Store of real running snapshots, keyed by "number:runDate". The simulator
/// (`Sim.swift`) reads `alignedDelays` synchronously while building a run; once
/// a fresh snapshot exists the whole live picture derives from real data, and
/// it keeps deriving from the LAST real snapshot even after the feed goes quiet
/// — we never regress a run back to the seeded walk mid-run. Snapshots are
/// mirrored to disk (beside TrainCache) so a relaunch mid-journey keeps the
/// real delays. Views refresh it via `refreshLive(...)` (pull-to-refresh,
/// detail open, foreground). Access is guarded by an internal lock, so the sim
/// can read it from any actor.
final class LiveFeed: @unchecked Sendable {
    static let shared = LiveFeed()

    /// Older than this a snapshot stops reading as "live" — the detail screen
    /// renders its age ("as of N min ago") instead — but its real delays keep
    /// driving the run. Stale beats regressing to the sim.
    private let freshTTL: TimeInterval = 150
    /// Persisted snapshots older than this are pruned on launch — the run is
    /// long over by then.
    private let diskTTL: TimeInterval = 7 * 24 * 3600

    private let lock = NSLock()
    private var cache: [String: (snap: LiveSnapshot, at: Date)] = [:]

    private let dir: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let d = docs.appendingPathComponent("LiveSnapshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    private struct StoredSnapshot: Codable {
        let number: String
        let runDate: String
        let snap: LiveSnapshot
        let at: Date
    }

    private init() { hydrate() }

    private func key(_ number: String, _ runDate: String) -> String { "\(number):\(runDate)" }

    /// Load persisted snapshots so a relaunch mid-run keeps real delays;
    /// discard (and delete) anything past the disk TTL.
    private func hydrate() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil) else { return }
        let cutoff = Date().addingTimeInterval(-diskTTL)
        lock.lock(); defer { lock.unlock() }
        for f in files where f.pathExtension == "json" {
            guard let data = try? Data(contentsOf: f),
                  let s = try? JSONDecoder().decode(StoredSnapshot.self, from: data) else { continue }
            if s.at < cutoff { try? FileManager.default.removeItem(at: f); continue }
            cache[key(s.number, s.runDate)] = (s.snap, s.at)
        }
    }

    func store(_ number: String, _ runDate: String, _ snap: LiveSnapshot) {
        let at = Date()
        lock.lock()
        cache[key(number, runDate)] = (snap, at)
        lock.unlock()
        persist(number, runDate, snap, at)
    }

    private func persist(_ number: String, _ runDate: String, _ snap: LiveSnapshot, _ at: Date) {
        let stored = StoredSnapshot(number: number, runDate: runDate, snap: snap, at: at)
        let url = dir.appendingPathComponent("\(number)_\(runDate).json")
        if let data = try? JSONEncoder().encode(stored) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func entry(_ number: String, _ runDate: String) -> (snap: LiveSnapshot, at: Date)? {
        lock.lock(); defer { lock.unlock() }
        return cache[key(number, runDate)]
    }

    /// The snapshot only while it's still fresh — drives the "LIVE" badge.
    func snapshot(_ number: String, _ runDate: String) -> LiveSnapshot? {
        guard let e = entry(number, runDate),
              Date().timeIntervalSince(e.at) < freshTTL else { return nil }
        return e.snap
    }

    /// True when a run currently has *fresh* live data (for a "LIVE" badge).
    func isLive(_ number: String, _ runDate: String) -> Bool {
        snapshot(number, runDate) != nil
    }

    /// True when a real snapshot has landed for this run, at any age.
    ///
    /// Gate on this, not on a delay value, before making any claim that carries
    /// money or legal consequence (TDR refund eligibility being the one that
    /// matters). Without a live-data key no snapshot ever lands, so every delay
    /// figure is a timetable projection, and telling someone the railway owes
    /// them a refund on the strength of a projection is not a claim to make.
    func hasFeedData(_ number: String, _ runDate: String) -> Bool {
        entry(number, runDate) != nil
    }

    /// How old the stored snapshot is, at any age; nil when there's none.
    /// Drives the "as of N min ago" staleness label.
    func snapshotAge(_ number: String, _ runDate: String) -> TimeInterval? {
        guard let e = entry(number, runDate) else { return nil }
        return Date().timeIntervalSince(e.at)
    }

    /// When the stored snapshot was captured — the memoization stamp `buildRun`
    /// keys its cache on, so a new snapshot invalidates the cached run.
    func snapshotStamp(_ number: String, _ runDate: String) -> Date? {
        entry(number, runDate)?.at
    }

    /// Arrival delay (minutes) per stop, aligned to `stops`, carrying the last
    /// known delay forward across any stop the feed omitted. Uses the stored
    /// snapshot at ANY age (never regress to the sim once real data exists);
    /// `nil` only when no snapshot has landed for this run — the caller then
    /// simulates. Negatives (early-running trains) pass through unclamped.
    func alignedDelays(number: String, runDate: String, stops: [Stop]) -> [Int]? {
        guard let e = entry(number, runDate), stops.count >= 2 else { return nil }
        let snap = e.snap
        // require a real overlap with this route, else it's the wrong data
        let hits = stops.filter { snap.delayByCode[$0.code] != nil }.count
        guard hits >= max(2, stops.count / 3) else { return nil }
        var out: [Int] = []
        var carry = 0
        for s in stops {
            if let d = snap.delayByCode[s.code] { carry = d }
            out.append(carry)
        }
        return out
    }
}

/// Fetch a run's live status and cache it (main-actor). No-op without a key or
/// when offline — the app keeps simulating. Safe to call often.
@MainActor
func refreshLive(_ number: String, _ runDate: String) async {
    guard IndianRailAPI.isConfigured else { return }
    if let snap = try? await IndianRailAPI.liveStatus(number: number, runDate: runDate) {
        LiveFeed.shared.store(number, runDate, snap)
    }
}
