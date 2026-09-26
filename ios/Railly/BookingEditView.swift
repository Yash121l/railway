import SwiftUI

/// Edit the ticket on a held trip: PNR, coach, and berth. Writes straight to
/// TripStore so the coach strip, PNR card, and Live Activity all pick up the
/// change. Leaving coach and berth empty keeps the trip on a PNR-only card
/// until the chart assigns a seat.
struct BookingEditView: View {
    let id: String
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss

    @State private var coach = ""
    @State private var seat = ""
    @State private var pnrDigits = ""
    @State private var loaded = false

    private var partialPNR: Bool { !pnrDigits.isEmpty && pnrDigits.count != 10 }

    private var subtitle: String {
        guard let rec = store.record(forId: id) else { return "Your ticket" }
        let name = TrainBank.shared.cached(rec.number)?.displayName ?? rec.number
        return "\(name) · \(fmtDay(istDateTime(rec.runDate, minutes: 12 * 60)))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Booking")
                        .font(.dsLargeTitle)
                        .foregroundStyle(DS.ink)
                    Text(subtitle)
                        .font(.dsBody)
                        .foregroundStyle(DS.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                DSCircleButton(systemImage: "xmark", label: "Cancel") { dismiss() }
            }
            .padding(.horizontal, DS.gutter)
            .padding(.top, 22)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TicketFields(pnrDigits: $pnrDigits, coach: $coach, berth: $seat)
                    Text("Leave coach and berth empty until the chart assigns them. Railly shows just the PNR until it does.")
                        .font(.dsFootnote)
                        .foregroundStyle(DS.secondary)
                }
                .padding(.horizontal, DS.gutter)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(DS.sheet)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DSButton(title: "Save", action: save)
                .disabled(partialPNR)
                .opacity(partialPNR ? 0.4 : 1)
                .padding(.horizontal, DS.gutter)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(DS.sheet)
        }
        .presentationDetents([.large])
        .presentationCornerRadius(DS.sheetRadius)
        .task {
            guard !loaded, let rec = store.record(forId: id) else { return }
            coach = rec.coach.flatMap { $0 == "—" ? nil : $0 } ?? ""
            seat = rec.seat.flatMap { $0 == "—" ? nil : $0 } ?? ""
            pnrDigits = (rec.pnr ?? "").filter(\.isNumber)
            loaded = true
        }
    }

    private func save() {
        let c = coach.trimmingCharacters(in: .whitespaces)
        let s = seat.trimmingCharacters(in: .whitespaces)
        store.setBooking(
            id,
            coach: c.isEmpty ? nil : c.uppercased(),
            seat: s.isEmpty ? nil : s,
            pnr: pnrDigits.isEmpty ? nil : groupPNR(pnrDigits)
        )
        dismiss()
    }
}

/// PNR, coach, and berth inputs in gray wells. `pnrDigits` holds digits only;
/// the field shows them with the 3-7 split.
struct TicketFields: View {
    @Binding var pnrDigits: String
    @Binding var coach: String
    @Binding var berth: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            field("PNR", systemImage: "ticket") {
                TextField("10-digit PNR", text: Binding(
                    get: { groupPNR(pnrDigits) },
                    set: { pnrDigits = String($0.filter(\.isNumber).prefix(10)) }
                ))
                .monospacedDigit()
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
            }
            if !pnrDigits.isEmpty && pnrDigits.count != 10 {
                Text("A PNR has 10 digits · \(pnrDigits.count) so far")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.lateText)
            }
            HStack(spacing: 12) {
                field("Coach", systemImage: "tram") {
                    TextField("B4", text: $coach)
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        #endif
                        .autocorrectionDisabled()
                }
                field("Berth", systemImage: "bed.double") {
                    TextField("34 LB", text: $berth)
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        #endif
                        .autocorrectionDisabled()
                }
            }
        }
    }

    private func field<Content: View>(_ title: String, systemImage: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.dsEyebrow)
                .kerning(0.7)
                .textCase(.uppercase)
                .foregroundStyle(DS.secondary)
            content()
                .font(.dsHeadline)
                .foregroundStyle(DS.ink)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsWell()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
