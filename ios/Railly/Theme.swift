import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// Dec 2025 Flighty palette — mirrors src/app/globals.css.
    static let inkline = Color(hex: 0x111318)
    static let subGray = Color(hex: 0x6B7280)
    static let fadedGray = Color(hex: 0x9CA3AF)
    static let fillGray = Color(hex: 0xF2F2F5)
    static let hairline = Color(hex: 0xE5E7EB)
    static let onTime = Color(hex: 0x1E9E4A)
    static let lateRed = Color(hex: 0xD93025)
    static let gateAmber = Color(hex: 0xF6C445)
    static let proPurple = Color(hex: 0x7C3AED)
    static let arcBlue = Color(hex: 0x4D9FFF)
}

extension TrainCategory {
    /// Livery-colored monogram — Railly's stand-in for airline logos.
    var liveryColor: Color {
        switch self {
        case .rajdhani: return Color(hex: 0xC62828)
        case .vandeBharat: return Color(hex: 0x0D47A1)
        case .shatabdi: return Color(hex: 0x546E7A)
        case .duronto: return Color(hex: 0x2E7D32)
        case .tejas: return Color(hex: 0xEF6C00)
        case .superfast: return Color(hex: 0x6A1B9A)
        case .express: return Color(hex: 0x37474F)
        }
    }

    var monogram: String {
        switch self {
        case .rajdhani: return "RJ"
        case .vandeBharat: return "VB"
        case .shatabdi: return "SH"
        case .duronto: return "DR"
        case .tejas: return "TJ"
        case .superfast: return "SF"
        case .express: return "EX"
        }
    }
}

struct TrainMark: View {
    let category: TrainCategory
    var size: CGFloat = 20

    var body: some View {
        Text(category.monogram)
            .font(.system(size: size * 0.36, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(category.liveryColor, in: Circle())
    }
}

/// City shown under the station code, departure-board style.
func cityFor(_ code: String, _ stationName: String) -> String {
    let byCode: [String: String] = [
        "MMCT": "Mumbai", "BVI": "Mumbai", "NDLS": "New Delhi", "HWH": "Kolkata",
        "SDAH": "Kolkata", "SHM": "Kolkata", "MAS": "Chennai", "SBC": "Bengaluru",
        "GNC": "Gandhinagar", "DDU": "Deen Dayal Upadhyaya", "VGLJ": "Jhansi",
        "PRYJ": "Prayagraj", "BSB": "Varanasi",
    ]
    if let city = byCode[code] { return city }
    var name = stationName
    for suffix in [" Junction", " Jn", " Central", " Cantt", " Capital", " City"] {
        if name.hasSuffix(suffix) { name = String(name.dropLast(suffix.count)) }
    }
    return name
}
