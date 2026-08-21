import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// WhatsApp-ready share cards. Instead of a plain sentence, a tap on Share
/// hands the family a crisp picture — the "train kahan pahunchi?" ritual that
/// is Flighty's #1 organic loop. Cards render to PNG via ImageRenderer at
/// scale 3, sized for a WhatsApp status.

// MARK: - Live-trip card (9:16)

private struct TripShareCard: View {
    let trip: HeldTrip

    var body: some View {
        let live = trip.live
        let train = trip.train
        let destDelay = live.stopTimings.last?.delayMin ?? live.delayMin

        let (late, headline, subline): (Bool, String, String) = {
            switch live.phase {
            case .enroute:
                return (destDelay > 5,
                        "Arrives \(fmtTime(live.arrivesEst))",
                        "\(Int((live.progress * 100).rounded()))% of \(Int(live.totalKm)) km")
            case .arrived:
                return (destDelay > 5,
                        "Arrived \(fmtTime(live.arrivesEst))",
                        "Reached \(cityFor(train.destination.code, train.destination.name))")
            case .boarding, .scheduled:
                return (live.delayMin > 5,
                        "Departs \(fmtTime(live.departsAt))",
                        "From \(cityFor(train.origin.code, train.origin.name))")
            }
        }()
        let statusColor = late ? Color.lateRed : Color.onTime
        let chip: String = {
            switch live.phase {
            case .enroute, .arrived: return destDelay > 5 ? "\(destDelay)m late" : "On time"
            case .boarding, .scheduled: return live.delayMin > 5 ? "\(live.delayMin)m late start" : "On time"
            }
        }()

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("RAILLY")
                    .font(.system(size: 15, weight: .heavy)).kerning(3)
                    .foregroundStyle(.white)
                Spacer()
                TrainMark(category: train.category, size: 40)
            }

            Spacer(minLength: 0)

            Text("\(train.number) · \(fmtDay(live.departsAt).uppercased())")
                .font(.system(size: 13, weight: .semibold)).kerning(0.5)
                .foregroundStyle(Color.fadedGray)
            Text(cityFor(train.origin.code, train.origin.name))
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.6)
            HStack(spacing: 9) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(statusColor)
                Text(cityFor(train.destination.code, train.destination.name))
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            Text(train.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.fadedGray)
                .lineLimit(1)
                .padding(.top, 5)

            Spacer(minLength: 0)

            if live.phase == .enroute {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.12))
                        Capsule().fill(statusColor)
                            .frame(width: max(8, geo.size.width * live.progress))
                    }
                }
                .frame(height: 7)
                .padding(.bottom, 20)
            }

            Text(chip)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 13).padding(.vertical, 7)
                .background(statusColor.opacity(0.16), in: Capsule())
            Text(headline)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.top, 12)
            Text(subline)
                .font(.system(size: 14))
                .foregroundStyle(Color.fadedGray)
                .padding(.top, 2)

            Spacer(minLength: 0)

            // This card leaves the app, so it has to carry its own provenance:
            // "live" is only true when a real feed backed this run.
            Text(LiveFeed.shared.hasFeedData(train.number, live.runDate)
                 ? "Tracked live with Railly"
                 : "Estimated from the timetable · Railly")
                .font(.system(size: 12, weight: .semibold)).kerning(0.3)
                .foregroundStyle(Color.subGray)
        }
        .padding(30)
        .frame(width: 360, height: 640, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x0B0D12), Color(hex: 0x161B22), Color(hex: 0x0B0D12)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }
}

// MARK: - Passport card (4:5)

private struct PassportShareCard: View {
    let stats: LogStats
    let mrzName: String

    private let accent = Color(hex: 0xA9A3E8)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("RAILLY PASSPORT")
                    .font(.system(size: 15, weight: .heavy)).kerning(1.5)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "tram.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accent)
            }
            Text("PASSPORT • PASS • पासपोर्ट")
                .font(.system(size: 10, weight: .semibold)).kerning(1.4)
                .foregroundStyle(accent)
                .padding(.top, 3)

            Text("DISTANCE")
                .font(.system(size: 11, weight: .bold)).kerning(1)
                .foregroundStyle(accent)
                .padding(.top, 28)
            (Text("\(cardGrouped(stats.distanceKm)) ").font(.system(size: 40, weight: .heavy))
                + Text("km").font(.system(size: 22, weight: .semibold)).foregroundStyle(accent))
                .foregroundStyle(.white)
            Text(String(format: "%.2fx around the world", stats.aroundTheWorld))
                .font(.system(size: 13))
                .foregroundStyle(accent)

            HStack(spacing: 26) {
                stat("TRIPS", "\(stats.trips)")
                stat("RAIL TIME", "\(stats.railMinutes / 60)h")
                stat("STATIONS", "\(stats.stationCodes.count)")
                stat("TRAINS", "\(stats.trainNumbers.count)")
            }
            .padding(.top, 24)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 3) {
                Rectangle().fill(accent.opacity(0.35)).frame(height: 1)
                    .padding(.bottom, 6)
                Text(mrzHeaderLine).lineLimit(1)
                Text(mrzLine).lineLimit(1)
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.55))
            .kerning(1)

            Text("railly.app")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 14)
        }
        .padding(26)
        .frame(width: 400, height: 500, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x14104B), Color(hex: 0x5A3FD6)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 10, weight: .bold)).kerning(1)
                .foregroundStyle(accent)
            Text(value).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
        }
    }

    private var mrzHeaderLine: String {
        let raw = "ALLTIME<<\(mrzName)<<MEMBER<<RAILLY"
        return String(raw.padding(toLength: 40, withPad: "<", startingAt: 0))
    }

    private var mrzLine: String {
        let raw = "\(istDateISO(Date()).replacingOccurrences(of: "-", with: ""))"
            + "\(stats.trips)TRIPS\(cardGrouped(stats.distanceKm).replacingOccurrences(of: ",", with: ""))KM"
            + "<<<<\(stats.railMinutes / 60)H<<\(stats.stationCodes.count)STN"
        return String(raw.padding(toLength: 40, withPad: "<", startingAt: 0))
    }
}

private func cardGrouped(_ n: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: n)) ?? "0"
}

// MARK: - Rendering

@MainActor
private func renderCard<V: View>(_ view: V) -> Image? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3
    #if canImport(UIKit)
    guard let ui = renderer.uiImage else { return nil }
    return Image(uiImage: ui)
    #else
    guard let cg = renderer.cgImage else { return nil }
    return Image(decorative: cg, scale: 3)
    #endif
}

/// The live-trip card as a shareable PNG image, or nil if rendering failed.
@MainActor
func renderTripShareCard(_ trip: HeldTrip) -> Image? {
    renderCard(TripShareCard(trip: trip))
}

/// The all-time passport card as a shareable PNG image.
@MainActor
func renderPassportShareCard(stats: LogStats, mrzName: String) -> Image? {
    renderCard(PassportShareCard(stats: stats, mrzName: mrzName))
}
