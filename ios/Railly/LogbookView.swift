import SwiftUI

/// The Flighty Passport treatment: gradient stat cards, a split-flap delay
/// board, and the past-trips log.

private struct SplitFlap: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                let ghost = ch.isLetter
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(LinearGradient(
                            colors: [Color(hex: 0x3A0F08), Color(hex: 0x2B0A05), Color(hex: 0x200704)],
                            startPoint: .top, endPoint: .bottom
                        ))
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .frame(height: 1.5)
                    Text(String(ch))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color(hex: 0xFDF3E7).opacity(ghost ? 0.3 : 1))
                }
                .frame(width: 44, height: 62)
            }
        }
    }
}

private struct StatsButton: View {
    let label: String
    var dark = false

    var body: some View {
        HStack {
            Text(label).font(.system(size: 16, weight: .semibold))
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(dark ? Color(hex: 0x2D2A66) : .white)
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(dark ? Color.black.opacity(0.12) : Color.white.opacity(0.15))
        )
        .padding(.top, 14)
    }
}

private struct PassportCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ALL-TIME RAILLY PASSPORT")
                .font(.system(size: 17, weight: .semibold))
                .kerning(1)
                .foregroundStyle(.white)
            Text("PASSPORT • PASS • पासपोर्ट")
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.4)
                .foregroundStyle(Color(hex: 0x8B7BC4))
                .padding(.top, 3)

            Text("DISTANCE")
                .font(.system(size: 11, weight: .bold)).kerning(1)
                .foregroundStyle(Color(hex: 0xA79BD6))
                .padding(.top, 22)
            (Text("28,412 ").font(.system(size: 38, weight: .heavy))
                + Text("km").font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(hex: 0xA79BD6)))
                .foregroundStyle(.white)
            Text("0.71x around the world")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0xA79BD6))

            HStack(spacing: 34) {
                passportStat("TRIPS", "47", sub: "12 overnight")
                passportStat("RAIL TIME", "214h")
            }
            .padding(.top, 20)
            HStack(spacing: 34) {
                passportStat("STATIONS", "38")
                passportStat("TRAINS", "8")
            }
            .padding(.top, 14)

            StatsButton(label: "All Trip Stats")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [Color(hex: 0x2A1052), Color(hex: 0x1B2E7A)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
    }

    private func passportStat(_ label: String, _ value: String, sub: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .bold)).kerning(1)
                .foregroundStyle(Color(hex: 0xA79BD6))
            Text(value)
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(.white)
            if let sub {
                Text(sub).font(.system(size: 12)).foregroundStyle(Color(hex: 0xA79BD6))
            }
        }
    }
}

private struct DelayCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SplitFlap(text: "42MIN")
            Text("Lost to Delays")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 18)
            Text("Delayed trips averaged 42m late · 19h lost all-time")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0xC98F85))
                .padding(.top, 2)

            HStack {
                Text("2H05M")
                Spacer()
                Text("12627")
                Spacer()
                Text("SBC-NDLS")
            }
            .font(.system(size: 15, weight: .bold, design: .monospaced))
            .kerning(2)
            .foregroundStyle(Color(hex: 0xFFB020))
            .shadow(color: Color(hex: 0xFFB020).opacity(0.65), radius: 5)
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0x1E0602)))
            .padding(.top, 16)

            Text("WORST DELAY")
                .font(.system(size: 11, weight: .bold)).kerning(1)
                .foregroundStyle(Color(hex: 0xC98F85))
                .padding(.top, 8)

            StatsButton(label: "All Delay Stats")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [Color(hex: 0x140302), Color(hex: 0x5A0E0E), Color(hex: 0x7A1E14)],
                    startPoint: .top, endPoint: .bottom
                ))
        )
    }
}

struct LogbookView: View {
    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { ctx in
                let now = ctx.date
                let past = getMyTrips(now).past

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 13) {
                            Text("Y")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color(hex: 0x2563AB))
                                .frame(width: 54, height: 54)
                                .background(Color(hex: 0xCFE3F8), in: Circle())
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Yash L.")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(Color.inkline)
                                Text("My Trip Log")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.subGray)
                            }
                        }

                        HStack(spacing: 10) {
                            Text("ALL-TIME")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.inkline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 11))
                            Text("2026")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.fadedGray)
                        }
                        .padding(.top, 16)

                        VStack(spacing: 15) {
                            PassportCard()
                            DelayCard()
                        }
                        .padding(.top, 16)

                        Text("Past Trips")
                            .font(.system(size: 23, weight: .bold))
                            .foregroundStyle(Color.inkline)
                            .padding(.top, 26)

                        ForEach(past) { trip in
                            NavigationLink(value: trip.id) {
                                pastRow(trip)
                            }
                            .buttonStyle(.plain)
                        }

                        Text("Lifetime stats are illustrative in this demo.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.fadedGray)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 26)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .background(Color.white)
            }
            .navigationDestination(for: String.self) { id in
                TripDetailView(id: id)
            }
        }
    }

    private func pastRow(_ trip: HeldTrip) -> some View {
        HStack(spacing: 11) {
            TrainMark(category: trip.train.category, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 7) {
                    Text(trip.train.number)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subGray)
                        .monospacedDigit()
                    Text("\(trip.train.origin.code) → \(trip.train.destination.code)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fadedGray)
                    Spacer()
                    Text(fmtDay(trip.live.arrivesEst))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subGray)
                }
                Text("\(cityFor(trip.train.origin.code, trip.train.origin.name)) to \(cityFor(trip.train.destination.code, trip.train.destination.name))")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.inkline)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }
}
