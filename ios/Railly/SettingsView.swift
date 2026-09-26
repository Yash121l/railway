import SwiftUI

/// Settings, Flighty-style. Every control here is real: alert prefs persist,
/// units change how the app renders, account data actually exports, imports
/// and deletes.

/// The traveller's name drives the avatar monogram, the profile header, and
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

/// An icon on a tinted rounded tile, then the title and an optional value.
private struct SettingsRow: View {
    let icon: String
    let tint: Color
    let title: String
    var value: String? = nil
    var valueColor: Color = DS.secondary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title)
                .font(.dsBody)
                .foregroundStyle(DS.ink)
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(.dsCallout)
                    .foregroundStyle(valueColor)
            }
        }
        .padding(.vertical, 2)
    }
}

/// The shared look for every settings screen: grouped rows on the canvas gray.
private extension View {
    func settingsList() -> some View {
        self.listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DS.canvas)
            .tint(DS.action)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore
    @AppStorage("railly.profileName") private var profileName = ""
    @AppStorage(IndianRailAPI.keyDefault) private var apiKey = ""
    @AppStorage("railly.liveActivities") private var liveActivities = true

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    private var liveConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        ProfileAvatar(name: profileName, size: 54)
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("Add Your Name", text: $profileName)
                                .font(.dsHeadline)
                                .foregroundStyle(DS.ink)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                            Text("\(store.records.count) trip\(store.records.count == 1 ? "" : "s") on this device")
                                .font(.dsFootnote)
                                .foregroundStyle(DS.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Alerts") {
                    NavigationLink {
                        AlertsSettingsView()
                    } label: {
                        SettingsRow(icon: "bell.badge.fill", tint: DS.late, title: "PNR Alerts")
                    }
                    NavigationLink {
                        LiveActivitiesSettingsView()
                    } label: {
                        SettingsRow(icon: "bolt.fill", tint: DS.passport, title: "Live Activities",
                                    value: liveActivities ? "On" : "Off")
                    }
                }

                Section("Customize") {
                    NavigationLink {
                        UnitsSettingsView()
                    } label: {
                        SettingsRow(icon: "ruler.fill", tint: DS.action, title: "Units")
                    }
                    NavigationLink {
                        LiveDataSettingsView()
                    } label: {
                        SettingsRow(icon: "dot.radiowaves.up.forward", tint: DS.onTime, title: "Live Data",
                                    value: liveConfigured ? "Live" : "Estimated",
                                    valueColor: liveConfigured ? DS.onTimeText : DS.secondary)
                    }
                }

                Section("Manage") {
                    NavigationLink {
                        AccountDataView()
                    } label: {
                        SettingsRow(icon: "externaldrive.fill", tint: DS.secondary, title: "Account Data")
                    }
                }

                Section {
                    NavigationLink {
                        FAQView()
                    } label: {
                        SettingsRow(icon: "questionmark", tint: DS.action, title: "FAQ")
                    }
                    Link(destination: URL(string: "mailto:feedback@railly.app?subject=Railly%20Feedback")!) {
                        HStack {
                            SettingsRow(icon: "paperplane.fill", tint: DS.route, title: "Send Feedback")
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(DS.tertiary)
                        }
                    }
                    NavigationLink {
                        WhatsNewView()
                    } label: {
                        SettingsRow(icon: "sparkles", tint: DS.rac, title: "What's New")
                    }
                    NavigationLink {
                        DataSourcesView()
                    } label: {
                        SettingsRow(icon: "antenna.radiowaves.left.and.right", tint: DS.onTime, title: "Data Sources")
                    }
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRow(icon: "tram.fill", tint: DS.ink, title: "About Railly")
                    }
                } header: {
                    Text("Help")
                } footer: {
                    VStack(spacing: 4) {
                        Text("Come ride with me, let's ride, let's ride away…")
                            .italic()
                        Text("Railly \(version)")
                    }
                    .font(.dsFootnote)
                    .foregroundStyle(DS.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)
                }
            }
            .settingsList()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Alerts

struct AlertsSettingsView: View {
    @AppStorage("railly.alert.basics") private var basics = true
    @AppStorage("railly.alert.arrival") private var arrival = true

    var body: some View {
        List {
            Section {
                alertToggle($basics, "Waitlist movement",
                            "When a watched PNR changes status: waitlist to RAC, RAC to confirmed.")
                alertToggle($arrival, "Chart prepared",
                            "When the reservation chart prepares and your berth is final.")
            } header: {
                Text("Watched PNRs")
            } footer: {
                Text("Notifications need iOS permission; Railly asks the first time one would fire. Delay, cancellation and platform alerts aren't built yet, so there's no switch for them.")
            }
        }
        .settingsList()
        .navigationTitle("PNR Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func alertToggle(_ binding: Binding<Bool>, _ title: String,
                             _ desc: String) -> some View {
        Toggle(isOn: binding) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.dsHeadline)
                    .foregroundStyle(DS.ink)
                Text(desc)
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
            }
        }
        .tint(DS.onTime)
        .padding(.vertical, 2)
        .onChange(of: binding.wrappedValue) { _, on in
            if on { PNRWatch.requestAuthorizationIfNeeded() }
        }
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
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                }
                .tint(DS.onTime)
            } footer: {
                Text("Your train's run on the Lock Screen and in the Dynamic Island: position, delay, and the next halt, updating in place.")
            }
        }
        .settingsList()
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
                Text("Speed over the ground, shown on the map and in trip detail.")
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
                Text("Indian Railways publishes timetables in 24-hour IST. Every time in Railly is IST.")
            }
        }
        .settingsList()
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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Your trips live only on this device. Back them up, bring them back, or clear them out.")
                    .font(.dsBody)
                    .foregroundStyle(DS.secondary)

                groupHeader("Export & Import")
                VStack(spacing: 0) {
                    ShareLink(item: store.exportJSON(bank: bank),
                              preview: SharePreview("Railly trips export")) {
                        actionRow("square.and.arrow.up", "Export Your Trips", DS.action)
                    }
                    Rectangle().fill(DS.separator).frame(height: 1).padding(.leading, 52)
                    Button {
                        showImporter = true
                    } label: {
                        actionRow("square.and.arrow.down", "Import Trips", DS.action)
                    }
                }
                .dsWell(radius: 18)
                footnote("A JSON file with every trip and its ticket details (coach, berth, PNR). Importing merges; trips you already have are kept.")

                groupHeader("Storage")
                Button {
                    confirmClearCache = true
                } label: {
                    actionRow("arrow.clockwise", "Clear Route Cache", DS.action)
                }
                .dsWell(radius: 18)
                footnote("\(store.records.count) trip\(store.records.count == 1 ? "" : "s") stored · \(bank.diskCacheCount) fetched schedules (\(ByteCountFormatter.string(fromByteCount: Int64(bank.diskCacheBytes), countStyle: .file))) in the route cache. Cleared schedules refetch when opened.")

                groupHeader("Danger Zone")
                Button {
                    confirmDeleteAll = true
                } label: {
                    actionRow("exclamationmark.triangle", "Delete All Trips", DS.lateText)
                }
                .background(DS.lateWash, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .disabled(store.records.isEmpty)
                .opacity(store.records.isEmpty ? 0.5 : 1)
                footnote("Permanently removes every trip, your watched PNRs and their saved statuses from this device. Railly keeps no copy anywhere else.",
                         color: DS.lateText)
            }
            .padding(.horizontal, DS.gutter)
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
        .background(DS.sheet)
        .navigationTitle("Account Data")
        .navigationBarTitleDisplayMode(.large)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                // Files from iCloud Drive or other apps arrive security-scoped.
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                do {
                    let data = try Data(contentsOf: url)
                    let added = try store.importJSON(data)
                    importResult = added == 0
                        ? "Nothing new to add. Those trips are already here."
                        : "Added \(added) trip\(added == 1 ? "" : "s")."
                } catch {
                    importResult = "That file isn't a Railly export."
                }
            case .failure:
                importResult = "Couldn't read that file."
            }
        }
        .alert("Import", isPresented: Binding(
            get: { importResult != nil },
            set: { if !$0 { importResult = nil } })) {
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

    private func groupHeader(_ title: String) -> some View {
        Text(title)
            .font(.dsSubhead)
            .foregroundStyle(DS.secondary)
            .textCase(.uppercase)
            .padding(.leading, 4)
            .padding(.top, 28)
            .padding(.bottom, 8)
    }

    private func actionRow(_ icon: String, _ title: String, _ color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24)
            Text(title).font(.dsBody)
            Spacer()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 16)
        .frame(height: 56)
        .contentShape(Rectangle())
    }

    private func footnote(_ text: String, color: Color = DS.secondary) -> some View {
        Text(text)
            .font(.dsFootnote)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
            .padding(.top, 8)
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
                    .font(.dsBody)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Live Train Status")
            } footer: {
                Text("Paste an indianrailapi.com API key to drive real train positions, delays, PNR status, and seat availability from the live feeds. Without one, Railly estimates them from the timetable and PRS booking rules. The key is stored only on this device.")
            }

            Section {
                HStack {
                    Text("Status").font(.dsBody).foregroundStyle(DS.ink)
                    Spacer()
                    if configured {
                        DSChip(text: "Live", color: DS.onTime, filled: true)
                    } else {
                        EstimateTag()
                    }
                }
                Link(destination: URL(string: "https://indianrailapi.com/api-collection/live-train-status")!) {
                    Text("Get a free API key")
                        .font(.dsBody)
                        .foregroundStyle(DS.action)
                }
            }
        }
        .settingsList()
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
                          status: "LIVE", color: DS.onTime)
            }
            Section("Offline Search") {
                sourceRow("\(Catalog.trains.count) trains · \(Catalog.stations.count) stations",
                          "The full network index ships inside the app, so search works instantly, even in a tunnel.",
                          status: "BUNDLED", color: DS.action)
            }
            Section {
                sourceRow("Live positions & delay forecast",
                          "India has no public live-position feed, so Railly projects each train along its real route from the published timetable and models delays the way they actually accumulate. Positions are estimates, clearly marked.",
                          status: "ESTIMATED", color: DS.secondary)
            } footer: {
                Text("Railly is a demo and is not affiliated with Indian Railways, IRCTC, or erail.in.")
            }
        }
        .settingsList()
        .navigationTitle("Data Sources")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sourceRow(_ title: String, _ desc: String,
                           status: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.dsHeadline)
                    .foregroundStyle(DS.ink)
                Spacer(minLength: 8)
                DSChip(text: status, color: color, filled: true)
            }
            Text(desc)
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - FAQ / What's New / About

struct FAQView: View {
    private let items: [(String, String)] = [
        ("Where does the data come from?",
         "Train schedules, run days, platforms, and routes come live from erail.in, the same feed powering one of India's most-used enquiry sites. Search runs on a bundled index of the whole network."),
        ("Are the live positions real?",
         "They're estimates. India's live NTES feed has no public API, so Railly projects each train along its real route from the published timetable, with a realistic delay model. Everything estimated is labeled. Add an indianrailapi.com key in Settings → Live Data and real positions take over."),
        ("Why is a train missing or renamed?",
         "Indian Railways renumbers and renames services constantly. Railly always shows what the live feed says today, which sometimes disagrees with what's printed on your ticket."),
        ("Do I need an account?",
         "No. Trips live on your device. Export them anytime from Settings → Account Data."),
        ("What does Railly cost?",
         "Nothing. There is no paid tier, no subscription and no in-app purchase. If that ever changes we'll say so before it does, not by gating something that already worked."),
        ("Which notifications does Railly actually send?",
         "Two, both about a PNR you're watching: when its status moves, and when the chart prepares. Delay, cancellation and platform-change alerts are not built yet, and the app won't offer you a switch for something it can't do."),
    ]

    var body: some View {
        List {
            ForEach(items, id: \.0) { q, a in
                DisclosureGroup {
                    Text(a)
                        .font(.dsCallout)
                        .foregroundStyle(DS.ink2)
                        .padding(.vertical, 4)
                } label: {
                    Text(q)
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                }
                .tint(DS.secondary)
            }
        }
        .settingsList()
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WhatsNewView: View {
    var body: some View {
        List {
            Section("September 2026") {
                newItem("One screen, one globe",
                        "Your trips now float over a satellite globe. Tap a trip and the globe flies to its route.")
                newItem("Passport and Delay Report",
                        "Your profile adds up every completed trip: track kilometres, rail time, top routes and trains, and how much time delays cost you.")
                newItem("Share cards, redrawn",
                        "Trip cards show the real route shape, and every estimated time says so.")
            }
            Section("July 2026") {
                newItem("The whole network, for real",
                        "Search all \(Catalog.trains.count) real IR trains and \(Catalog.stations.count) stations. Schedules, platforms, and routes now come from the live feed.")
                newItem("Add your own trips",
                        "Hold tickets on real dates, with the run-day calendar enforced. Past trips build your Passport.")
                newItem("Settings, properly",
                        "Alert preferences, units that actually change the app, data export and import, and a full account-data page.")
            }
        }
        .settingsList()
        .navigationTitle("What's New")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func newItem(_ title: String, _ desc: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.dsHeadline)
                .foregroundStyle(DS.ink)
            Text(desc)
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
        }
        .padding(.vertical, 3)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "tram.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(DS.ink, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            Text("Railly")
                .font(.dsLargeTitle)
                .foregroundStyle(DS.ink)
            Text("Flighty-grade tracking for Indian Railways.\nBuilt as a love letter to both.")
                .font(.dsCallout)
                .foregroundStyle(DS.secondary)
                .multilineTextAlignment(.center)
            Text("Not affiliated with Indian Railways, IRCTC, erail.in, or Flighty.")
                .font(.dsCaption)
                .foregroundStyle(DS.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 18)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.sheet)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
