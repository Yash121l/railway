import SwiftUI

/// "Where do I stand on the platform?" — the coach-position strip every
/// Indian rail traveller pulls up as the train rolls in. The rake is drawn
/// from the engine back, each coach capped with its class color, with the
/// traveller's coach lit and its position called out.

extension JClass {
    /// Class colors keyed to how travellers think of the classes: premium
    /// purples/indigos for AC, workhorse green for Sleeper.
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

/// The bare strip: one cell per coach, engine first, scrolled so the
/// highlighted coach sits centred.
struct CoachStripView: View {
    let rake: [CoachSlot]
    /// Coach code to light up ("B4"); nil draws a plain composition strip.
    var highlight: String?
    /// Leading/trailing scroll margin, so the strip can bleed to a card's
    /// edges while its first coach still lines up with the card's content.
    var inset: CGFloat = 0

    /// Platform ordinals skip the loco; trainsets (Vande Bharat) count from 1.
    private var ordinalOffset: Int { rake.first?.kind == .loco ? 1 : 0 }

    private var highlightPosition: Int? {
        guard let highlight else { return nil }
        return rake.first { $0.code == highlight }?.position
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(rake) { slot in
                        CoachCell(slot: slot,
                                  ordinal: slot.position - ordinalOffset,
                                  isMine: slot.position == highlightPosition)
                            .id(slot.position)
                    }
                }
                .padding(.vertical, 2)
            }
            .contentMargins(.horizontal, inset, for: .scrollContent)
            .scrollIndicators(.hidden)
            .onAppear { scroll(proxy, animated: false) }
            .onChange(of: highlightPosition) { scroll(proxy, animated: true) }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let target = highlightPosition else { return }
        // deferred one runloop: on first appearance the cells haven't been
        // laid out yet and scrollTo silently does nothing
        DispatchQueue.main.async {
            if animated {
                withAnimation(.snappy(duration: 0.4)) { proxy.scrollTo(target, anchor: .center) }
            } else {
                proxy.scrollTo(target, anchor: .center)
            }
        }
    }
}

private struct CoachCell: View {
    let slot: CoachSlot
    let ordinal: Int
    let isMine: Bool

    private static let coachSize = CGSize(width: 46, height: 36)
    private static let locoSize = CGSize(width: 54, height: 36)

    var body: some View {
        let isLoco = slot.kind == .loco
        let size = isLoco ? Self.locoSize : Self.coachSize

        VStack(spacing: 5) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(isMine ? DS.action : .clear)

            ZStack {
                shape
                label
            }
            .frame(width: size.width, height: size.height)
            .shadow(color: isMine ? DS.action.opacity(0.35) : .clear, radius: 6, y: 2)

            Text(isLoco ? "ENG" : "\(ordinal)")
                .font(.system(size: 10, weight: isMine ? .bold : .medium))
                .foregroundStyle(isMine ? DS.action : DS.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var shape: some View {
        switch slot.kind {
        case .loco:
            // the nose faces the direction of travel
            UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 6,
                                   bottomTrailingRadius: 6, topTrailingRadius: 6,
                                   style: .continuous)
                .fill(DS.ink)
        case .reserved, .general:
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isMine ? DS.action : DS.sheet)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(isMine ? DS.action : DS.separator, lineWidth: 1)
                )
                .overlay(alignment: .top) {
                    if let jc = slot.jClass {
                        Capsule()
                            .fill(isMine ? .white : jc.tint)
                            .frame(height: 3)
                            .padding(.horizontal, 7)
                            .padding(.top, 4)
                    }
                }
        case .luggage, .generator, .pantry:
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(DS.fill)
        }
    }

    @ViewBuilder
    private var label: some View {
        if slot.kind == .loco {
            Image(systemName: "train.side.front.car")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        } else {
            Text(slot.code)
                .font(.system(size: slot.code.count > 3 ? 10 : 12, weight: .bold))
                .foregroundStyle(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 3)
                .padding(.top, slot.jClass == nil ? 0 : 3)
        }
    }

    private var labelColor: Color {
        if isMine { return .white }
        switch slot.kind {
        case .reserved, .general: return DS.ink
        default: return DS.secondary
        }
    }

    private var accessibilityText: String {
        if slot.kind == .loco { return "Engine" }
        var parts = ["Coach \(slot.code)"]
        if let jc = slot.jClass { parts.append(jc.label) }
        parts.append("position \(ordinal)")
        if isMine { parts.append("your coach") }
        return parts.joined(separator: ", ")
    }
}

/// The coach strip as a titled card: the position sentence, the strip, a
/// class legend and the honesty footnote. Used by the trip detail and the
/// PNR result.
struct CoachPositionCard: View {
    let train: Train
    /// The traveller's coach, if a berth is assigned.
    var highlight: String?
    /// Live formation from the chart (real PNRs); beats the modeled rake.
    var rakeOverride: [CoachSlot]? = nil
    /// Card title; nil when the host screen draws its own section header.
    var title: String? = "Coach Position"

    var body: some View {
        let rake = rakeOverride ?? Reservation.rake(train)
        let offset = rake.first?.kind == .loco ? 1 : 0
        let from = offset == 1 ? "engine" : "front"
        let mine = highlight.flatMap { code in rake.first { $0.code == code } }
        let classes = legendClasses(rake)

        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                if let title {
                    Text(title).font(.dsSection).foregroundStyle(DS.ink)
                }
                summary(mine: mine, offset: offset, from: from, count: rake.count - offset)
            }

            CoachStripView(rake: rake, highlight: highlight, inset: 16)
                .padding(.horizontal, -16)

            if classes.count > 1 {
                HStack(spacing: 12) {
                    ForEach(classes, id: \.self) { jc in
                        HStack(spacing: 5) {
                            Capsule().fill(jc.tint).frame(width: 12, height: 4)
                            Text(jc.rawValue)
                                .font(.dsCaption)
                                .foregroundStyle(DS.secondary)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(jc.label)
                    }
                }
            }

            Text(rakeOverride != nil
                ? "Live formation from the chart. Rakes can run reversed."
                : "Composition is indicative. Rakes can run reversed.")
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
        }
        .dsCard()
    }

    @ViewBuilder
    private func summary(mine: CoachSlot?, offset: Int, from: String, count: Int) -> some View {
        if let mine {
            (Text(mine.code).foregroundStyle(DS.action)
                + Text(" is coach \(mine.position - offset) from the \(from)").foregroundStyle(DS.ink))
                .font(.dsHeadline)
        } else if let highlight {
            Text("Coach \(highlight) isn't in this composition")
                .font(.dsHeadline)
                .foregroundStyle(DS.ink)
        } else {
            Text("\(count) coaches, counted from the \(from)")
                .font(.dsCallout)
                .foregroundStyle(DS.secondary)
        }
    }

    private func legendClasses(_ rake: [CoachSlot]) -> [JClass] {
        var seen = Set<JClass>()
        return rake.compactMap(\.jClass)
            .filter { seen.insert($0).inserted }
            .sorted { $0.order < $1.order }
    }
}
