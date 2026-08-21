import SwiftUI

/// Edit the ticket on a held trip — coach, berth, and PNR. Opened from the
/// trip's booking card or the ellipsis menu; writes straight to TripStore so
/// the coach strip, PNR card, and Live Activity all pick up the change. Leaving
/// coach and berth empty keeps the trip on a PNR-only card until the chart
/// assigns a seat.
struct BookingEditView: View {
    let id: String
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss

    @State private var coach = ""
    @State private var seat = ""
    @State private var pnrDigits = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    field(title: "PNR", systemImage: "ticket") {
                        TextField("10-digit PNR", text: Binding(
                            get: { groupPNR(pnrDigits) },
                            set: { pnrDigits = String($0.filter(\.isNumber).prefix(10)) }
                        ))
                        .monospacedDigit()
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    }
                    HStack(spacing: 12) {
                        field(title: "Coach", systemImage: "bed.double") {
                            TextField("B4", text: $coach)
                                #if os(iOS)
                                .textInputAutocapitalization(.characters)
                                #endif
                                .autocorrectionDisabled()
                        }
                        field(title: "Berth", systemImage: "number") {
                            TextField("34 LB", text: $seat)
                        }
                    }
                    Text("Leave coach and berth empty until the chart assigns them — Railly shows just the PNR until it does.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subGray)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Color.white)
            .navigationTitle("Edit Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .task {
                guard !loaded, let rec = store.record(forId: id) else { return }
                coach = rec.coach.flatMap { $0 == "—" ? nil : $0 } ?? ""
                seat = rec.seat.flatMap { $0 == "—" ? nil : $0 } ?? ""
                pnrDigits = (rec.pnr ?? "").filter(\.isNumber)
                loaded = true
            }
        }
    }

    private func field<Content: View>(title: String, systemImage: String,
                                       @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .bold)).kerning(0.5)
                .foregroundStyle(Color.subGray)
            content()
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.inkline)
                .padding(.horizontal, 14)
                .frame(height: 56)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.fillGray, in: RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() {
        let c = coach.trimmingCharacters(in: .whitespaces)
        let s = seat.trimmingCharacters(in: .whitespaces)
        store.setBooking(
            id,
            coach: c.isEmpty ? nil : c,
            seat: s.isEmpty ? nil : s,
            pnr: pnrDigits.isEmpty ? nil : groupPNR(pnrDigits)
        )
        dismiss()
    }
}
