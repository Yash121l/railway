import Foundation

/// Bit-exact port of the web app's seeded PRNG (src/lib/rng.ts): the same
/// key yields the same stream on every platform, so the iOS app and the web
/// app render the identical "live" network.
func hashSeed(_ str: String) -> UInt32 {
    var h: UInt32 = 1_779_033_703 ^ UInt32(str.utf16.count)
    for unit in str.utf16 {
        h = (h ^ UInt32(unit)) &* 3_432_918_353
        h = (h << 13) | (h >> 19)
    }
    return h
}

final class SeededRng {
    private var a: UInt32

    init(_ key: String) {
        a = hashSeed(key)
    }

    /// mulberry32 — matches JS `Math.imul` semantics via wrapping UInt32 math.
    func next() -> Double {
        a = a &+ 0x6D2B_79F5
        var t = (a ^ (a >> 15)) &* (1 | a)
        t = (t &+ ((t ^ (t >> 7)) &* (61 | t))) ^ t
        return Double(t ^ (t >> 14)) / 4_294_967_296
    }

    /// Deterministic integer in [min, max]
    func int(_ min: Int, _ max: Int) -> Int {
        min + Int(next() * Double(max - min + 1))
    }

    func pick<T>(_ items: [T]) -> T {
        items[Int(next() * Double(items.count))]
    }
}
