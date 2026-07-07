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

func parseHM(_ hm: String) -> Int {
    let parts = hm.split(separator: ":").compactMap { Int($0) }
    return parts[0] * 60 + parts[1]
}

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.timeZone = TimeZone(identifier: "Asia/Kolkata")
    return f
}()

private let dayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "EEE d MMM"
    f.timeZone = TimeZone(identifier: "Asia/Kolkata")
    f.locale = Locale(identifier: "en_IN")
    return f
}()

/// "17:05" in IST
func fmtTime(_ date: Date) -> String { timeFormatter.string(from: date) }

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
