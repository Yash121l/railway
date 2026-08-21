import Foundation

/// All schedules are IST; India has no DST so a fixed offset is exact.
let istOffsetMin = 330

private var utcCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}()

/// Date for a "yyyy-MM-dd" + minutes-past-midnight, both interpreted in IST.
func istDateTime(_ dateISO: String, minutes: Int) -> Date {
    let parts = dateISO.split(separator: "-").compactMap { Int($0) }
    var comps = DateComponents()
    comps.year = parts[0]
    comps.month = parts[1]
    comps.day = parts[2]
    let midnightUTC = utcCalendar.date(from: comps)!
    return midnightUTC.addingTimeInterval(TimeInterval((minutes - istOffsetMin) * 60))
}

/// "yyyy-MM-dd" of a Date as seen in IST.
func istDateISO(_ date: Date) -> String {
    let shifted = date.addingTimeInterval(TimeInterval(istOffsetMin * 60))
    let c = utcCalendar.dateComponents([.year, .month, .day], from: shifted)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}

func istWeekday(_ dateISO: String) -> Day {
    let parts = dateISO.split(separator: "-").compactMap { Int($0) }
    var comps = DateComponents()
    comps.year = parts[0]
    comps.month = parts[1]
    comps.day = parts[2]
    let date = utcCalendar.date(from: comps)!
    let order: [Day] = [.sun, .mon, .tue, .wed, .thu, .fri, .sat]
    return order[utcCalendar.component(.weekday, from: date) - 1]
}

func addDaysISO(_ dateISO: String, _ delta: Int) -> String {
    let parts = dateISO.split(separator: "-").compactMap { Int($0) }
    var comps = DateComponents()
    comps.year = parts[0]
    comps.month = parts[1]
    comps.day = parts[2] + delta
    let date = utcCalendar.date(from: comps)!
    let c = utcCalendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}

/// Minutes past midnight for an "HH:mm" string, or nil when the feed hands us
/// something that isn't one. erail returns "--" and empty strings on some rows.
func parseHMOrNil(_ hm: String) -> Int? {
    let parts = hm.split(separator: ":")
    guard parts.count >= 2,
          let h = Int(parts[0]), let m = Int(parts[1]),
          (0...23).contains(h), (0...59).contains(m)
    else { return nil }
    return h * 60 + m
}

/// Minutes past midnight, falling back to midnight on an unparseable time.
///
/// This used to index parts[0] and parts[1] unguarded, so one malformed
/// departure from the feed crashed that train on every render, permanently,
/// because the bad record had already been written to the disk cache.
/// `RailAPI.assertSchemaSane` now rejects such a train before it is cached, so
/// the fallback here should be unreachable in practice.
func parseHM(_ hm: String) -> Int { parseHMOrNil(hm) ?? 0 }

private let timeFormatter24: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.timeZone = TimeZone(identifier: "Asia/Kolkata")
    return f
}()

// compact "2:58PM", the Flighty treatment — also survives narrow row cells
private let timeFormatter12: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "h:mma"
    f.timeZone = TimeZone(identifier: "Asia/Kolkata")
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

private let dayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "EEE d MMM"
    f.timeZone = TimeZone(identifier: "Asia/Kolkata")
    f.locale = Locale(identifier: "en_IN")
    return f
}()

/// "17:05" in IST — or "5:05 pm" when Settings › Units picks 12-hour.
func fmtTime(_ date: Date) -> String {
    UserDefaults.standard.bool(forKey: "railly.time12")
        ? timeFormatter12.string(from: date)
        : timeFormatter24.string(from: date)
}

/// Speed honoring Settings › Units. `caps` picks "KM/H" vs "km/h".
func fmtSpeed(_ kmh: Int, caps: Bool = false) -> String {
    if UserDefaults.standard.bool(forKey: "railly.speedMph") {
        return "\(Int((Double(kmh) * 0.621371).rounded())) \(caps ? "MPH" : "mph")"
    }
    return "\(kmh) \(caps ? "KM/H" : "km/h")"
}

/// "Mon 7 Jul" in IST
func fmtDay(_ date: Date) -> String { dayFormatter.string(from: date) }

/// "15h 32m"
func fmtDuration(_ minutes: Double) -> String {
    let m = Int(minutes.rounded())
    let h = m / 60
    let rest = m % 60
    if h == 0 { return "\(rest)m" }
    if rest == 0 { return "\(h)h" }
    return "\(h)h \(rest)m"
}
