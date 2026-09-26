import SwiftUI

/// Railly's design system. Every screen builds from these tokens and parts;
/// a screen that reaches for a raw hex or a one-off font size is a bug.
///
/// The language, in one breath: a white sheet floating over a satellite globe.
/// Black ink, one status color per journey (green on time, red late, gray
/// scheduled), amber reserved for the platform number, blue for the single
/// primary action. Numbers are the heroes; labels whisper.
enum DS {
    // MARK: Ink & surfaces

    static let ink = Color(hex: 0x0B0B0F)
    static let ink2 = Color(hex: 0x3C3C43)
    static let secondary = Color(hex: 0x6E6E73)
    static let tertiary = Color(hex: 0xAEAEB2)
    static let fill = Color(hex: 0xF2F2F7)
    static let fill2 = Color(hex: 0xE9E9EE)
    static let separator = Color(hex: 0xE5E5EA)
    static let sheet = Color.white
    static let canvas = Color(hex: 0xF7F7F9)

    // MARK: Signals — role-bound, never decorative

    static let onTime = Color(hex: 0x1FA34A)
    /// On-time green for text under 17pt (AA on white).
    static let onTimeText = Color(hex: 0x17843B)
    static let late = Color(hex: 0xE5382B)
    static let lateText = Color(hex: 0xD02C20)
    static let platform = Color(hex: 0xFFCC00)
    static let platformInk = Color(hex: 0x1A1400)
    static let action = Color(hex: 0x0A84FF)
    static let route = Color(hex: 0x4DA3FF)
    static let rac = Color(hex: 0xC98A00)
    static let passport = Color(hex: 0x4B3FD1)

    // tinted washes behind status banners
    static let onTimeWash = Color(hex: 0xEEF8F1)
    static let lateWash = Color(hex: 0xFDEFED)
    static let neutralWash = Color(hex: 0xF2F2F7)
    static let amberWash = Color(hex: 0xFFF7DB)

    // MARK: Layout

    static let gutter: CGFloat = 20
    static let cardRadius: CGFloat = 20
    static let sheetRadius: CGFloat = 38
    static let controlRadius: CGFloat = 14
}

// MARK: - Type scale

extension Font {
    /// Sheet titles: "My Trips".
    static let dsLargeTitle = Font.system(size: 32, weight: .bold)
    /// Detail route title: "Mumbai to New Delhi".
    static let dsTitle = Font.system(size: 26, weight: .bold)
    /// Section headers: "Your Coach", "Timetable".
    static let dsSection = Font.system(size: 21, weight: .bold)
    static let dsHeadline = Font.system(size: 17, weight: .semibold)
    static let dsBody = Font.system(size: 16)
    static let dsCallout = Font.system(size: 15)
    static let dsSubhead = Font.system(size: 14, weight: .medium)
    static let dsFootnote = Font.system(size: 13)
    static let dsCaption = Font.system(size: 12, weight: .medium)
    /// All-caps micro labels ("LIVE NOW", "PLATFORM").
    static let dsEyebrow = Font.system(size: 11, weight: .bold)
    /// The hero time in trip detail ("9:50 PM").
    static let dsHeroTime = Font.system(size: 46, weight: .bold)
    /// Row countdown numeral ("5h").
    static let dsCountdown = Font.system(size: 30, weight: .bold)
    /// Stat values on cards ("1,243 km").
    static let dsStat = Font.system(size: 22, weight: .bold)
}

extension Text {
    /// Uppercase micro label with tracking.
    func eyebrow(_ color: Color = DS.secondary) -> some View {
        self.font(.dsEyebrow).kerning(0.7).foregroundStyle(color).textCase(.uppercase)
    }
}

// MARK: - Status tone

/// One status color per journey. Rows, detail, share cards and the Live
/// Activity all derive their color from this, so a trip never reads green in
/// one place and red in another.
enum StatusTone: Equatable {
    case scheduled, onTime, late, done, cancelled

    var fill: Color {
        switch self {
        case .scheduled: return Color(hex: 0xC7C7CC)
        case .onTime: return DS.onTime
        case .late, .cancelled: return DS.late
        case .done: return DS.tertiary
        }
    }

    /// Large numerals (hero times) use the fill; small text uses this.
    var text: Color {
        switch self {
        case .scheduled: return DS.ink
        case .onTime: return DS.onTimeText
        case .late, .cancelled: return DS.lateText
        case .done: return DS.secondary
        }
    }

    var heroTime: Color {
        switch self {
        case .scheduled: return DS.ink
        case .done: return DS.secondary
        default: return fill
        }
    }

    var wash: Color {
        switch self {
        case .onTime: return DS.onTimeWash
        case .late, .cancelled: return DS.lateWash
        case .scheduled, .done: return DS.neutralWash
        }
    }

    var word: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .onTime: return "On Time"
        case .late: return "Late"
        case .done: return "Arrived"
        case .cancelled: return "Cancelled"
        }
    }
}

extension HeldTrip {
    /// Minutes late at the destination, as currently estimated.
    var arrivalDelayMin: Int { live.stopTimings[live.stopTimings.count - 1].delayMin }

    /// The journey's one status color. Far-future runs stay neutral; the
    /// tone only commits to green/red once the run is within a day or moving.
    func tone(_ now: Date) -> StatusTone {
        switch live.phase {
        case .arrived:
            return .done
        case .enroute, .boarding:
            return arrivalDelayMin > 5 ? .late : .onTime
        case .scheduled:
            let hours = live.departsAt.timeIntervalSince(now) / 3600
            if hours > 24 { return .scheduled }
            return live.stopTimings[0].delayMin > 5 ? .late : .onTime
        }
    }
}

// MARK: - Countdown

/// "5h" / "41 MIN", "3" / "DAYS", "12" / "MIN" — the row's left-rail numeral.
func countdownParts(until date: Date, now: Date) -> (value: String, unit: String) {
    let mins = max(0, date.timeIntervalSince(now) / 60)
    if mins >= 48 * 60 {
        let days = Int((mins / (24 * 60)).rounded())
        return ("\(days)", days == 1 ? "DAY" : "DAYS")
    }
    if mins >= 60 {
        let h = Int(mins / 60)
        let m = Int(mins.truncatingRemainder(dividingBy: 60))
        return ("\(h)h", "\(m) MIN")
    }
    let m = max(1, Int(mins.rounded()))
    return ("\(m)", m == 1 ? "MINUTE" : "MINUTES")
}

// MARK: - Surfaces

extension View {
    /// The standard card: white, hairline stroke, 20pt corners.
    func dsCard(padding: CGFloat = 16) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.sheet, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous).stroke(DS.separator, lineWidth: 1))
    }

    /// A filled gray well — search fields, secondary tiles.
    func dsWell(radius: CGFloat = DS.controlRadius) -> some View {
        self.background(DS.fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Section header with an optional trailing action ("Timetable · See All").
struct DSSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (label: String, run: () -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.dsSection).foregroundStyle(DS.ink)
                if let subtitle {
                    Text(subtitle).font(.dsFootnote).foregroundStyle(DS.secondary)
                }
            }
            Spacer()
            if let action {
                Button(action.label, action: action.run)
                    .font(.dsSubhead)
                    .foregroundStyle(DS.action)
            }
        }
    }
}

// MARK: - Controls

/// The gray circular close/more button that sits top-right on every sheet.
struct DSCircleButton: View {
    let systemImage: String
    var label: String
    var size: CGFloat = 32
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(DS.secondary)
                .frame(width: size, height: size)
                .background(DS.fill, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Full-width primary button (blue) or secondary (gray well).
struct DSButton: View {
    enum Style { case primary, secondary, destructive }
    let title: String
    var systemImage: String? = nil
    var style: Style = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(DSPressStyle())
    }

    private var foreground: Color {
        switch style {
        case .primary: return .white
        case .secondary: return DS.ink
        case .destructive: return DS.late
        }
    }

    private var background: Color {
        switch style {
        case .primary: return DS.action
        case .secondary: return DS.fill
        case .destructive: return DS.lateWash
        }
    }
}

/// Compact capsule button used in toolbars and inline actions.
struct DSPill: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = DS.action
    var filled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage).font(.system(size: 14, weight: .semibold)) }
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(filled ? .white : tint)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(filled ? tint : tint.opacity(0.12), in: Capsule())
        }
        .buttonStyle(DSPressStyle())
    }
}

/// Scale-down press feedback for buttons that aren't rows.
struct DSPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Data display

/// The amber platform badge: direction glyph + number. "--" when unknown.
struct PlatformBadge: View {
    let platform: String?
    var departing = true
    var size: CGFloat = 1

    var body: some View {
        HStack(spacing: 4 * size) {
            Image(systemName: departing ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 13 * size, weight: .heavy))
            Text(platform.map { "PF \($0)" } ?? "--")
                .font(.system(size: 17 * size, weight: .heavy))
                .monospacedDigit()
        }
        .foregroundStyle(DS.platformInk)
        .padding(.horizontal, 10 * size)
        .frame(height: 34 * size)
        .background(DS.platform, in: RoundedRectangle(cornerRadius: 10 * size, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(platform.map { "Platform \($0)" } ?? "Platform not yet announced")
    }
}

/// Small label over a bold value — the atom of every stats row.
struct DSStat: View {
    let label: String
    let value: String
    var valueColor: Color = DS.ink
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(label).font(.dsCaption).foregroundStyle(DS.secondary)
            Text(value).font(.system(size: 17, weight: .semibold)).foregroundStyle(valueColor).monospacedDigit()
        }
    }
}

/// Status chip: "CNF", "RAC 12", "WL 23", "On Time".
struct DSChip: View {
    let text: String
    var color: Color = DS.ink
    var filled = false

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .kerning(0.3)
            .foregroundStyle(filled ? .white : color)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(filled ? color : color.opacity(0.12), in: Capsule())
    }
}

/// A thin progress track with a leading fill.
struct DSProgress: View {
    let value: Double
    var tint: Color = DS.action
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.fill2)
                Capsule().fill(tint).frame(width: max(height, geo.size.width * min(1, max(0, value))))
            }
        }
        .frame(height: height)
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
    }
}

/// Departure / arrival glyph in a status-colored circle.
struct EndpointGlyph: View {
    let departing: Bool
    var tone: StatusTone
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: departing ? "arrow.up.right" : "arrow.down.right")
            .font(.system(size: size * 0.5, weight: .black))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tone.fill, in: Circle())
    }
}

/// Time with an optional "+1" superscript for next-day arrivals.
func timeText(_ date: Date, nextDay: Bool, size: CGFloat, weight: Font.Weight = .bold) -> Text {
    Text(fmtTime(date)).font(.system(size: size, weight: weight))
        + Text(nextDay ? "+1" : "").font(.system(size: size * 0.55, weight: .bold)).baselineOffset(size * 0.4)
}

/// True when `later` falls on a later IST calendar day than `earlier`.
func isNextDay(_ later: Date, after earlier: Date) -> Bool {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
    return cal.startOfDay(for: later) > cal.startOfDay(for: earlier)
}

/// The honest-data label: every estimated value in the app wears one.
struct EstimateTag: View {
    var text = "Estimated"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform.path.ecg").font(.system(size: 10, weight: .bold))
            Text(text).font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(DS.secondary)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(DS.fill, in: Capsule())
        .accessibilityLabel("\(text): projected from the timetable")
    }
}
