import Foundation

private let earthRadiusKm = 6371.0

private func toRad(_ deg: Double) -> Double { deg * .pi / 180 }
private func toDeg(_ rad: Double) -> Double { rad * 180 / .pi }

func haversineKm(_ aLat: Double, _ aLng: Double, _ bLat: Double, _ bLng: Double) -> Double {
    let dLat = toRad(bLat - aLat)
    let dLng = toRad(bLng - aLng)
    let h = sin(dLat / 2) * sin(dLat / 2)
        + cos(toRad(aLat)) * cos(toRad(bLat)) * sin(dLng / 2) * sin(dLng / 2)
    return 2 * earthRadiusKm * asin(sqrt(h))
}

/// Initial bearing from A to B, degrees clockwise from north.
func bearingDeg(_ aLat: Double, _ aLng: Double, _ bLat: Double, _ bLng: Double) -> Double {
    let phi1 = toRad(aLat)
    let phi2 = toRad(bLat)
    let dLambda = toRad(bLng - aLng)
    let y = sin(dLambda) * cos(phi2)
    let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLambda)
    return (toDeg(atan2(y, x)) + 360).truncatingRemainder(dividingBy: 360)
}

func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double { min(hi, max(lo, v)) }

/// Cumulative km along the stop polyline; [0] = 0, [n-1] = total.
func cumulativeKm(_ stops: [Stop]) -> [Double] {
    var out = [0.0]
    for i in 1..<stops.count {
        out.append(out[i - 1] + haversineKm(
            stops[i - 1].lat, stops[i - 1].lng, stops[i].lat, stops[i].lng))
    }
    return out
}
