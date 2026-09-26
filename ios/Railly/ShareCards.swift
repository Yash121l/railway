import CoreLocation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// WhatsApp-ready share cards. Instead of a plain sentence, a tap on Share
/// hands the family a crisp picture: the "train kahan pahunchi?" ritual that
/// is Flighty's #1 organic loop. Both cards lay out at 360x450 points and
/// render at scale 3, so they land as 1080x1350 PNGs (a 4:5 post or status).

private let cardSize = CGSize(width: 360, height: 450)

// MARK: - Route sketch

/// The trip's real track shape, projected flat and fitted to the frame: the
/// full line faint, the covered part in the trip's status color, and a glowing
/// dot where the train is.
private struct RouteSketch: View {
    let all: [CLLocationCoordinate2D]
    let done: [CLLocationCoordinate2D]
    let fromCode: String
    let toCode: String
    let tint: Color
    let showsTrain: Bool

    var body: some View {
        Canvas { ctx, size in
            // faint dot grid, the map's graticule
            var grid = Path()
            for x in stride(from: 9.0, to: size.width, by: 18) {
                for y in stride(from: 9.0, to: size.height, by: 18) {
                    grid.addEllipse(in: CGRect(x: x - 0.8, y: y - 0.8, width: 1.6, height: 1.6))
                }
            }
            ctx.fill(grid, with: .color(.white.opacity(0.07)))

            guard all.count > 1 else { return }
            let lats = all.map(\.latitude)
            let lngs = all.map(\.longitude)
            let minLat = lats.min()!, maxLat = lats.max()!
            let minLng = lngs.min()!, maxLng = lngs.max()!
            let k = cos((minLat + maxLat) / 2 * .pi / 180)
            let w = max((maxLng - minLng) * k, 0.05)
            let h = max(maxLat - minLat, 0.05)
            let inset: CGFloat = 44
            let box = CGSize(width: size.width - inset * 2, height: size.height - inset * 2)
            let scale = min(box.width / w, box.height / h)
            let ox = inset + (box.width - w * scale) / 2
            let oy = inset + (box.height - h * scale) / 2

            func pt(_ c: CLLocationCoordinate2D) -> CGPoint {
                CGPoint(x: ox + (c.longitude - minLng) * k * scale,
                        y: oy + (maxLat - c.latitude) * scale)
            }
            func line(_ cs: [CLLocationCoordinate2D]) -> Path {
                var p = Path()
                p.addLines(cs.map(pt))
                return p
            }
            let stroke = StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)

            ctx.stroke(line(all), with: .color(.white.opacity(0.28)), style: stroke)
            if done.count > 1 {
                ctx.stroke(line(done), with: .color(tint), style: stroke)
            }

            let ends = [(all[0], fromCode), (all[all.count - 1], toCode)]
            for (coord, code) in ends {
                let p = pt(coord)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10)),
                         with: .color(.white))
                let below = p.y < size.height - 34
                ctx.draw(Text(code).font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.85)),
                         at: CGPoint(x: min(max(p.x, 24), size.width - 24), y: below ? p.y + 10 : p.y - 10),
                         anchor: below ? .top : .bottom)
            }

            if showsTrain, let c = done.last {
                let p = pt(c)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 13, y: p.y - 13, width: 26, height: 26)),
                         with: .color(tint.opacity(0.3)))
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 7, y: p.y - 7, width: 14, height: 14)),
                         with: .color(.white))
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9)),
                         with: .color(tint))
            }
        }
    }
}

// MARK: - Trip card

private struct TripShareCard: View {
    let trip: HeldTrip

    var body: some View {
        let live = trip.live
        let train = trip.train
        let now = Date()
        let destDelay = trip.arrivalDelayMin
        // a stale snapshot mid-run is no longer live; a finished run's feed data stands
        let measured = live.phase == .arrived
            ? LiveFeed.shared.hasFeedData(train.number, live.runDate)
            : LiveFeed.shared.isLive(train.number, live.runDate)
        // An arrived run keeps its verdict on a shared card instead of the
        // in-app gray "done".
        let tone: StatusTone = live.phase == .arrived
            ? (destDelay > 5 ? .late : .onTime)
            : trip.tone(now)
        let route = RailRouteCache.route(for: train)
        let done: [CLLocationCoordinate2D] = {
            switch live.phase {
            case .arrived: return route.coords
            case .enroute: return route.travelled(toLeg: live.prevStopIdx, frac: live.legFraction)
            case .boarding, .scheduled: return []
            }
        }()
        let from = cityFor(train.origin.code, train.origin.name)
        let to = cityFor(train.destination.code, train.destination.name)

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                LinearGradient(colors: [Livery.nightTop, Livery.nightBottom], startPoint: .top, endPoint: .bottom)
                RouteSketch(all: route.coords, done: done,
                            fromCode: train.origin.code, toCode: train.destination.code,
                            tint: tone.fill, showsTrain: live.phase == .enroute)
                HStack {
                    Text("RAILLY")
                        .font(.system(size: 13, weight: .heavy))
                        .kerning(3)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(chip(tone: tone, destDelay: destDelay))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .frame(height: 24)
                        .background(tone.fill, in: Capsule())
                }
                .padding(18)
            }
            .frame(height: 196)
            .clipped()

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    TrainMark(category: train.category, size: 22)
                    Text("\(train.number) · \(train.displayName)")
                        .font(.dsSubhead)
                        .foregroundStyle(DS.secondary)
                        .lineLimit(1)
                }
                (Text(from) + Text(" to ").foregroundStyle(DS.secondary) + Text(to))
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 8)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(heroLabel).eyebrow()
                        timeText(heroTime, nextDay: heroNextDay, size: 40)
                            .foregroundStyle(tone.heroTime)
                            .monospacedDigit()
                    }
                    Spacer()
                    if !measured && (live.phase != .scheduled || live.delayMin > 0) {
                        EstimateTag()
                            .padding(.bottom, 8)
                    }
                }
                .padding(.top, 14)

                if live.phase == .enroute {
                    DSProgress(value: live.progress, tint: tone.fill, height: 6)
                        .padding(.top, 12)
                    Text("\(Int((live.progress * 100).rounded()))% of \(Int(live.totalKm)) km")
                        .font(.dsFootnote)
                        .foregroundStyle(DS.secondary)
                        .padding(.top, 6)
                }

                Spacer(minLength: 0)

                // This card leaves the app, so it carries its own provenance:
                // "live" is only true when a real feed backed this run.
                HStack {
                    Text(measured ? "Tracked live with Railly" : "Estimated from the timetable · Railly")
                    Spacer()
                    Text(fmtDay(live.departsAt))
                }
                .font(.dsCaption)
                .foregroundStyle(DS.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DS.sheet)
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }

    private var heroLabel: String {
        switch trip.live.phase {
        case .enroute: return "Arrives"
        case .arrived: return "Arrived"
        case .boarding, .scheduled: return "Departs"
        }
    }

    private var heroTime: Date {
        switch trip.live.phase {
        case .enroute, .arrived: return trip.live.arrivesEst
        case .boarding, .scheduled: return trip.live.stopTimings[0].depEst
        }
    }

    private var heroNextDay: Bool {
        switch trip.live.phase {
        case .enroute, .arrived: return isNextDay(trip.live.arrivesEst, after: trip.live.departsAt)
        case .boarding, .scheduled: return false
        }
    }

    private func chip(tone: StatusTone, destDelay: Int) -> String {
        switch trip.live.phase {
        case .enroute: return destDelay > 5 ? "\(destDelay)m late" : "On time"
        case .arrived: return destDelay > 5 ? "Arrived \(destDelay)m late" : "Arrived on time"
        case .boarding, .scheduled:
            if tone == .scheduled { return "Scheduled" }
            return trip.live.delayMin > 5 ? "\(trip.live.delayMin)m late start" : "On time"
        }
    }
}

// MARK: - Passport card

private struct PassportShareCard: View {
    let stats: LogStats
    let mrzName: String
    let period: String

    var body: some View {
        let mrz = passportMRZ(period: period, name: mrzName, stats: stats, width: 40)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(period) RAILLY PASSPORT")
                        .font(.system(size: 16, weight: .semibold))
                        .kerning(1)
                        .foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Image(systemName: "person.text.rectangle.fill")
                        Text("PASSPORT · PASS · पासपोर्ट")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.1)
                    .foregroundStyle(Livery.passportLabel)
                }
                Spacer()
                Image(systemName: "tram.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Livery.passportLabel)
            }

            label("DISTANCE").padding(.top, 30)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(passportNumber(stats.distanceKm))
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(.white)
                Text("km")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Livery.passportLabel)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            Text(String(format: "%.2fx around the world", stats.aroundTheWorld))
                .font(.dsFootnote)
                .foregroundStyle(Livery.passportLabel)

            Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 16) {
                GridRow {
                    stat("TRIPS", "\(stats.trips)")
                    stat("RAIL TIME", stats.railMinutes == 0 ? "0h" : fmtDuration(Double(stats.railMinutes)))
                }
                GridRow {
                    stat("STATIONS", "\(stats.stationCodes.count)")
                    stat("TRAINS", "\(stats.trainNumbers.count)")
                }
            }
            .padding(.top, 24)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 3) {
                Rectangle()
                    .fill(Livery.passportLabel.opacity(0.3))
                    .frame(height: 1)
                    .padding(.bottom, 7)
                Text(mrz.0)
                Text(mrz.1)
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.5))
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            HStack {
                Text("Track km from the Indian Railways timetable")
                Spacer()
                Text("railly.app").fontWeight(.semibold)
            }
            .font(.dsCaption)
            .foregroundStyle(.white.opacity(0.55))
            .padding(.top, 14)
        }
        .padding(26)
        .frame(width: cardSize.width, height: cardSize.height, alignment: .topLeading)
        .background(
            Livery.passport.overlay {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .stroke(.white.opacity(0.05), lineWidth: 1)
                        .frame(width: CGFloat(90 + i * 46), height: CGFloat(90 + i * 46))
                        .offset(x: 150, y: -150)
                }
            }
        )
        .clipped()
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.dsEyebrow).kerning(1).foregroundStyle(Livery.passportLabel)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            label(title)
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Rendering

@MainActor
private func renderCard<V: View>(_ view: V) -> Image? {
    let renderer = ImageRenderer(content: view.environment(\.colorScheme, .light))
    renderer.scale = 3
    #if canImport(UIKit)
    guard let ui = renderer.uiImage else { return nil }
    return Image(uiImage: ui)
    #else
    guard let cg = renderer.cgImage else { return nil }
    return Image(decorative: cg, scale: 3)
    #endif
}

/// The trip card as a shareable 1080x1350 image, or nil if rendering failed.
@MainActor
func renderTripShareCard(_ trip: HeldTrip) -> Image? {
    renderCard(TripShareCard(trip: trip))
}

/// The Passport card as a shareable 1080x1350 image. `period` is "ALL-TIME" or
/// the "yyyy" the stats cover.
@MainActor
func renderPassportShareCard(stats: LogStats, mrzName: String, period: String = "ALL-TIME") -> Image? {
    renderCard(PassportShareCard(stats: stats, mrzName: mrzName, period: period))
}
