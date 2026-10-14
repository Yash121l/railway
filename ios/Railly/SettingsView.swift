import SwiftUI

/// Flighty's Settings sheet, for rails. Every control here is real: alert
/// prefs persist, units change how the app renders, account data actually
/// exports and deletes.

/// The traveller's name drives the avatar monogram, the logbook header, and
/// the passport's machine-readable zone. Unset falls back to a neutral name.
func profileDisplayName(_ raw: String) -> String {
    let n = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return n.isEmpty ? "Traveller" : n
}

/// First letter of the name, for the round avatar.
func profileAvatarInitial(_ raw: String) -> String {
    String(profileDisplayName(raw).first!).uppercased()
}

/// Passport MRZ rendering: uppercase, alphanumerics kept, every other run of
/// characters collapsed to a single "<" separator ("Yash L." → "YASH<L").
func profileMRZName(_ raw: String) -> String {
    var out = ""
    var sepPending = false
    for ch in profileDisplayName(raw).uppercased() {
        if ch.isLetter || ch.isNumber {
            if sepPending && !out.isEmpty { out.append("<") }
            out.append(ch)
            sepPending = false
        } else {
            sepPending = true
        }
    }
    return out.isEmpty ? "TRAVELLER" : out
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @AppStorage("railly.profileName") private var profileName = ""

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 13) {
                        Text(profileAvatarInitial(profileName))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(hex: 0x2563AB))
                            .frame(width: 56, height: 56)
                            .background(Color(hex: 0xCFE3F8), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("Traveller", text: $profileName)
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(Color.inkline)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                            Text("\(store.records.count) trip\(store.records.count == 1 ? "" : "s")")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.subGray)
                        }
                    }
                    .padding(.vertical, 4)

                }

                Section("Alerts") {
                    NavigationLink {
                        AlertsSettingsView()
                    } label: {
                        settingsRow("bell.badge.fill", .lateRed, "My Trains")
                    }
                }

                Section("Extensions") {
                    NavigationLink {
                        LiveActivitiesSettingsView()
                    } label: {
                        settingsRow("bolt.fill", .proPurple, "Live Activities")
                    }
                    NavigationLink {
                        comingSoon("Lock Screen Widgets",
                                   "Countdown and live-run widgets are on the roadmap.")
                    } label: {
                        settingsRow("lock.iphone", .inkline, "Lock Screen Widgets")
                    }
                    NavigationLink {
                        comingSoon("Apple Watch",
                                   "Platform numbers on your wrist, the moment they change.")
                    } label: {
                        settingsRow("applewatch", .inkline, "Apple Watch")
                    }
                }

                Section("Customize") {
                    NavigationLink {
                        UnitsSettingsView()
                    } label: {
                        settingsRow("ruler", Color(hex: 0x0A84FF), "Units")
                    }
                }

                Section("Manage") {
                    NavigationLink {
                        AccountDataView()
                    } label: {
                        settingsRow("externaldrive.fill", .subGray, "Account Data")
                    }
                    NavigationLink {
                        DataSourcesView()
                    } label: {
                        settingsRow("antenna.radiowaves.left.and.right", .onTime, "Data Sources")
                    }
                    NavigationLink {
                        LiveDataSettingsView()
                    } label: {
                        settingsRow("dot.radiowaves.up.forward", .arcBlue, "Live Data")
                    }
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        settingsRow("hand.raised.fill", .subGray, "Privacy")
                    }
                }

                Section("Help Center") {
                    NavigationLink {
                        FAQView()
                    } label: {
                        settingsRow("questionmark.circle.fill", Color(hex: 0x0A84FF), "FAQ")
                    }
                    Link(destination: URL(string: "mailto:feedback@railly.app?subject=Railly%20Feedback")!) {
                        settingsRow("paperplane.fill", .arcBlue, "Send Feedback")
                    }
                    NavigationLink {
                        WhatsNewView()
                    } label: {
                        settingsRow("sparkles", .gateAmber, "What's New")
                    }
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        settingsRow("tram.fill", .inkline, "About Railly")
                    }
                } footer: {
                    VStack(spacing: 4) {
                        Text("Railly \(version)")
                        Text("Come ride with me, let's ride, let's ride away…")
                            .italic()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func settingsRow(_ icon: String, _ tint: Color, _ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 29, height: 29)
                .background(tint, in: RoundedRectangle(cornerRadius: 7))
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(Color.inkline)
        }
    }

    private func comingSoon(_ title: String, _ blurb: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.fadedGray)
            Text(blurb)
                .font(.system(size: 15))
                .foregroundStyle(Color.subGray)
                .multilineTextAlignment(.center)
            Text("COMING SOON")
                .font(.system(size: 11, weight: .bold))
                .kerning(1)
                .foregroundStyle(Color.fadedGray)
        }
        .padding(30)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Alerts

struct AlertsSettingsView: View {
    @AppStorage("railly.alert.basics") private var basics = true
    @AppStorage("railly.alert.arrival") private var arrival = true

    var body: some View {
        List {
            Section {
                Text("Pick the notification types you receive for your trains.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.subGray)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
            Section {
                alertToggle($basics, "Waitlist movement",
                            "When a watched PNR changes status — waitlist to RAC, RAC to confirmed.")
                alertToggle($arrival, "Chart prepared",
                            "When the reservation chart prepares and your berth is final.")
            } footer: {
                Text("Notifications require iOS notification permission. Railly asks the first time an alert would fire.")
            }
        }
        .navigationTitle("My Trains")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func alertToggle(_ binding: Binding<Bool>, _ title: String,
                             _ desc: String) -> some View {
        Toggle(isOn: binding) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.inkline)
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.subGray)
            }
        }
        .tint(Color.onTime)
        .padding(.vertical, 2)
        .onChange(of: binding.wrappedValue) { _, on in
            if on { PNRWatch.requestAuthorizationIfNeeded() }
        }
    }
}

// MARK: - Privacy

struct PrivacySettingsView: View {
    @State private var enabled = Analytics.isEnabled

    var body: some View {
        List {
            Section {
                Toggle(isOn: $enabled) {
                    Text("Share Usage Analytics")
                        .font(.system(size: 16, weight: .semibold))
                }
                .tint(Color.onTime)
                .onChange(of: enabled) { _, on in
                    Analytics.shared.setEnabled(on)
                }
            } footer: {
                Text("Anonymous counts of which features get used, plus crash reports and screen recordings with every text field masked. Never your PNR, passenger status, or saved trips. Sent to PostHog; see railly.app/privacy.")
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Live Activities

struct LiveActivitiesSettingsView: View {
    @AppStorage("railly.liveActivities") private var enabled = true

    var body: some View {
        List {
            Section {
                Toggle(isOn: $enabled) {
                    Text("Live Activities")
                        .font(.system(size: 16, weight: .semibold))
                }
                .tint(Color.onTime)
            } footer: {
                Text("Your train's live run on the Lock Screen and in the Dynamic Island — position, delay, and the next halt, updating in place.")
            }
        }
        .navigationTitle("Live Activities")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Units

struct UnitsSettingsView: View {
    @AppStorage("railly.speedMph") private var speedMph = false
    @AppStorage("railly.time12") private var time12 = false

    var body: some View {
        List {
            Section {
                Picker("Train Speed", selection: $speedMph) {
                    Text("km/h").tag(false)
                    Text("mph").tag(true)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } header: {
                Text("Train Speed")
            } footer: {
                Text("Speed over the ground, shown on the live map and in Live Run.")
            }
            Section {
                Picker("Time Format", selection: $time12) {
                    Text("24-hour").tag(false)
                    Text("12-hour").tag(true)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } header: {
                Text("Time Format")
            } footer: {
                Text("Indian Railways timetables are published in 24-hour IST. All times in Railly are IST.")
            }
        }
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Account data

struct AccountDataView: View {
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @State private var confirmDeleteAll = false
    @State private var confirmClearCache = false
    @State private var showImporter = false
    @State private var importResult: String?

    var body: some View {
        List {
            Section {
                ShareLink(item: store.exportJSON(bank: bank),
                          preview: SharePreview("Railly trips export")) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.arcBlue)
                        Text("Export Your Trips")
                            .foregroundStyle(Color.arcBlue)
                    }
                }
                Button {
                    showImporter = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundStyle(Color.arcBlue)
                        Text("Import Trips")
                            .foregroundStyle(Color.arcBlue)
                    }
                }
            } header: {
                Text("Export & import")
            } footer: {
                Text("\(store.records.count) trips stored on this device · \(bank.diskCacheCount) fetched schedules (\(ByteCountFormatter.string(fromByteCount: Int64(bank.diskCacheBytes), countStyle: .file))) in the route cache.")
            }

            Section {
                Button(role: .destructive) {
                    confirmClearCache = true
                } label: {
                    Text("Clear Route Cache")
                }
                Button(role: .destructive) {
                    confirmDeleteAll = true
                } label: {
                    Text("Delete All Trips")
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("Deleting trips removes them, your watched PNRs and their saved statuses from this device permanently. Railly keeps no copy anywhere else.")
            }
        }
        .navigationTitle("Account Data")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                do {
                    let data = try Data(contentsOf: url)
                    let added = try store.importJSON(data)
                    importResult = added == 0
                        ? "Nothing new to add — those trips are already here."
                        : "Added \(added) trip\(added == 1 ? "" : "s")."
                } catch {
                    importResult = "That file isn't a Railly export."
                }
            case .failure:
                importResult = "Couldn't read that file."
            }
        }
        .alert("Import", isPresented: .constant(importResult != nil)) {
            Button("OK") { importResult = nil }
        } message: {
            Text(importResult ?? "")
        }
        .confirmationDialog("Delete all \(store.records.count) trips? This can't be undone.",
                            isPresented: $confirmDeleteAll, titleVisibility: .visible) {
            Button("Delete All Trips", role: .destructive) { store.removeAll() }
        }
        .confirmationDialog("Clear cached schedules? Held trips refetch when opened.",
                            isPresented: $confirmClearCache, titleVisibility: .visible) {
            Button("Clear Cache", role: .destructive) { bank.clearDiskCache() }
        }
    }
}

// MARK: - Live data

struct LiveDataSettingsView: View {
    @AppStorage(IndianRailAPI.keyDefault) private var apiKey = ""

    private var configured: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        List {
            Section {
                SecureField("indianrailapi.com API key", text: $apiKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Live Train Status")
            } footer: {
                Text("Paste an indianrailapi.com API key to drive real train positions, delays, PNR status, and seat availability from the live feeds. Without one, Railly estimates them from the timetable and PRS booking rules. The key is stored only on this device.")
            }

            Section {
                HStack {
                    Text("Status").foregroundStyle(Color.inkline)
                    Spacer()
                    Text(configured ? "Live" : "Estimated")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(configured ? Color.onTime : Color.gateAmber)
                }
                Link(destination: URL(string: "https://indianrailapi.com/api-collection/live-train-status")!) {
                    Text("Get a free API key")
                        .foregroundStyle(Color.arcBlue)
                }
            }
        }
        .navigationTitle("Live Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data sources

struct DataSourcesView: View {
    var body: some View {
        List {
            Section("Schedules & Platforms") {
                sourceRow("Indian Railways via erail.in",
                          "Live timetables, run days, coach classes, platforms, and station coordinates for every train on the network. Fetched on demand, cached on device.",
                          status: "LIVE", color: .onTime)
            }
            Section("Offline Search") {
                sourceRow("\(Catalog.trains.count) trains · \(Catalog.stations.count) stations",
                          "The full network index ships inside the app, so search works instantly — even in a tunnel.",
                          status: "BUNDLED", color: .arcBlue)
            }
            Section {
                sourceRow("Live positions & delay forecast",
                          "India has no public live-position feed, so Railly projects each train along its real route from the published timetable and models delays the way they actually accumulate. Positions are estimates, clearly marked.",
                          status: "ESTIMATED", color: .gateAmber)
            } footer: {
                Text("Railly is a demo and is not affiliated with Indian Railways, IRCTC, or erail.in.")
            }
        }
        .navigationTitle("Data Sources")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sourceRow(_ title: String, _ desc: String,
                           status: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkline)
                Spacer()
                Text(status)
                    .font(.system(size: 9, weight: .heavy))
                    .kerning(0.6)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(color, in: Capsule())
            }
            Text(desc)
                .font(.system(size: 13))
                .foregroundStyle(Color.subGray)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - FAQ / What's New / About

struct FAQView: View {
    private let items: [(String, String)] = [
        ("Where does the data come from?",
         "Train schedules, run days, platforms, and routes come live from erail.in, the same feed powering one of India's most-used enquiry sites. Search runs on a bundled index of the whole network."),
        ("Are the live positions real?",
         "They're estimates. India's live NTES feed has no public API, so Railly projects each train along its real route from the published timetable, with a realistic delay model. Everything estimated is labeled."),
        ("Why is a train missing or renamed?",
         "Indian Railways renumbers and renames services constantly. Railly always shows what the live feed says today — which sometimes disagrees with what's printed on your ticket."),
        ("Do I need an account?",
         "No. Trips live on your device. Export them anytime from Settings → Account Data."),
        ("What does Railly cost?",
         "Nothing. There is no paid tier, no subscription and no in-app purchase. If that ever changes we'll say so before it does, not by gating something that already worked."),
        ("Which notifications does Railly actually send?",
         "Two, both about a PNR you're watching: when its status moves, and when the chart prepares. Delay, cancellation and platform-change alerts are not built yet — the app won't offer you a switch for something it can't do."),
    ]

    var body: some View {
        List {
            ForEach(items, id: \.0) { q, a in
                DisclosureGroup {
                    Text(a)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.subGray)
                        .padding(.vertical, 4)
                } label: {
                    Text(q)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkline)
                }
            }
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WhatsNewView: View {
    var body: some View {
        List {
            Section("July 2026") {
                newItem("The whole network, for real",
                        "Search all \(Catalog.trains.count) real IR trains and \(Catalog.stations.count) stations. Schedules, platforms, and routes now come from the live feed.")
                newItem("Add your own trips",
                        "Hold tickets on real dates, with the run-day calendar enforced. Past trips build your logbook.")
                newItem("Settings, properly",
                        "Alert preferences, units that actually change the app, data export, and a full account-data page.")
            }
        }
        .navigationTitle("What's New")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func newItem(_ title: String, _ desc: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkline)
            Text(desc)
                .font(.system(size: 13))
                .foregroundStyle(Color.subGray)
        }
        .padding(.vertical, 3)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "tram.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.inkline)
            Text("Railly")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Color.inkline)
            Text("Flighty-grade tracking for Indian Railways.\nBuilt as a love letter to both.")
                .font(.system(size: 15))
                .foregroundStyle(Color.subGray)
                .multilineTextAlignment(.center)
            Text("Not affiliated with Indian Railways, IRCTC, erail.in, or Flighty.")
                .font(.system(size: 12))
                .foregroundStyle(Color.fadedGray)
                .multilineTextAlignment(.center)
                .padding(.top, 18)
        }
        .padding(30)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
