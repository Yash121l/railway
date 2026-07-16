import SwiftUI

/// "Where do I stand on the platform?" — the coach-position strip every
/// Indian rail traveller pulls up as the train rolls in. The rake is drawn
/// from the engine back, each coach tinted by class, with the user's coach
/// lit and its position called out.

extension JClass {
    /// Stripe colors keyed to how travellers think of the classes —
    /// premium purples/indigos for AC, workhorse green for Sleeper.
    var tint: Color {
        switch self {
        case .ac1: return Color(hex: 0x7C3AED)
        case .ac2: return Color(hex: 0x4F46E5)
        case .ac3: return Color(hex: 0x2563EB)
        case .ac3e: return Color(hex: 0x0891B2)
        case .sleeper: return Color(hex: 0x059669)
        case .chair: return Color(hex: 0xEA580C)
        case .execChair, .execAnubhuti: return Color(hex: 0x9333EA)
        case .vistadome: return Color(hex: 0xDB2777)
        case .second: return Color(hex: 0x64748B)
        case .general: return Color(hex: 0x94A3B8)
        }
    }
}

struct CoachStripView: View {
    let rake: [CoachSlot]
    /// coach code to light up ("B4"); nil draws a plain composition strip
    var highlight: String?

    /// platform ordinals skip the loco; trainsets (Vande Bharat) count from 1
    private var ordinalOffset: Int { rake.first?.kind == .loco ? 1 : 0 }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 3) {
                    ForEach(rake) { slot in
                        coachBox(slot)
                            .id(slot.code)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                if let highlight {
                    proxy.scrollTo(highlight, anchor: .center)
                }
            }
        }
    }

    private func coachLabel(_ slot: CoachSlot) -> String {
        if slot.kind == .loco { return "Engine" }
        var parts = ["Coach \(slot.code)"]
        if let jc = slot.jClass { parts.append(jc.label) }
        parts.append("position \(slot.position - ordinalOffset)")
        if slot.code == highlight { parts.append("your coach") }
        return parts.joined(separator: ", ")
    }

    private func coachBox(_ slot: CoachSlot) -> some View {
        let isMine = slot.code == highlight
        let tint = slot.jClass?.tint ?? Color.inkline

        return VStack(spacing: 4) {
            ZStack {
                if slot.kind == .loco {
                    // the loco gets a nose
                    UnevenRoundedRectangle(
                        topLeadingRadius: 14, bottomLeadingRadius: 14,
                        bottomTrailingRadius: 5, topTrailingRadius: 5
                    )
                    .fill(Color.inkline)
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isMine ? Color.arcBlue : Color.fillGray)
                        .overlay(alignment: .top) {
                            // class-color roofline, the LHB livery stripe
                            if let jc = slot.jClass {
                                Capsule()
                                    .fill(isMine ? .white : jc.tint)
                                    .frame(height: 3)
                                    .padding(.horizontal, 5)
                                    .padding(.top, 3)
                            }
                        }
                }
                Text(slot.code)
                    .font(.system(size: slot.code.count > 3 ? 8 : 10, weight: .bold))
                    .foregroundStyle(
                        slot.kind == .loco || isMine ? .white
                            : slot.kind == .reserved ? tint : Color.subGray
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 2)
            }
            .frame(width: 44, height: 30)
            .shadow(color: isMine ? Color.arcBlue.opacity(0.45) : .clear,
                    radius: 6, y: 2)

            Text(slot.kind == .loco ? "ENG" : "\(slot.position - ordinalOffset)")
                .font(.system(size: 9, weight: isMine ? .bold : .medium))
                .foregroundStyle(isMine ? Color.arcBlue : Color.subGray)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(coachLabel(slot))
    }
}

/// SectionCard wrapper used by the PNR result and trip detail screens.
struct CoachPositionCard: View {
    let train: Train
    /// the traveller's coach, if a berth is assigned
    var highlight: String?
    /// live formation from the chart (real PNRs) — beats the modeled rake
    var rakeOverride: [CoachSlot]? = nil

    var body: some View {
        let rake = rakeOverride ?? Reservation.rake(train)
        let mine = rake.first { $0.code == highlight }
        let offset = rake.first?.kind == .loco ? 1 : 0

        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Coach Position")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color.inkline)
                Text(mine.map {
                    "\($0.code) is coach \($0.position - offset) from the \(offset == 1 ? "engine" : "front")"
                } ?? "\(rake.count - offset) coaches, counted from the \(offset == 1 ? "engine" : "front")")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.subGray)
            }
            CoachStripView(rake: rake, highlight: highlight)
            Text(rakeOverride != nil
                ? "Live formation from the chart — rakes can run reversed."
                : "Composition is indicative — rakes can run reversed.")
                .font(.system(size: 11))
                .foregroundStyle(Color.subGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
    }
}
