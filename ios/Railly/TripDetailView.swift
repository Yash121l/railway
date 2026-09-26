import SwiftUI

/// A journey's detail, as the content of the home sheet. The globe behind the
/// sheet draws the route and the train; this is everything you'd read off a
/// departure board, your ticket, and the running status, top to bottom.
struct TripDetailView: View {
    let id: String

    init(id: String) { self.id = id }

    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @EnvironmentObject private var router: Router
    @ObservedObject private var liveAct = LiveActivityManager.shared
    @AppStorage("railly.alert.basics") private var alertWaitlist = true
    @AppStorage("railly.alert.arrival") private var alertChart = true

    // NavigationPath, not a typed path: AvailabilityView is pushed as an
    // AvailRoute, and a typed path silently drops pushes of any other type.
    @State private var path = NavigationPath()
    @State private var tick: TimeInterval = 15
    @State private var confirmDelete = false
    @State private var altContext: AltContext?
    @State private var pendingTrain: String?
    @State private var showEditBooking = false
    @State private var shareImage: Image?
    @State private var pnrCheck: PNRCheck = .idle
    @State private var showAllStops = false
    @State private var showAllUpdates = false
    @State private var addedCount = 0

    private let updatesID = "updates"

    var body: some View {
        NavigationStack(path: $path) {
            TimelineView(.periodic(from: .now, by: tick)) { ctx in
                if let trip = getTrip(id, ctx.date) {
                    detail(trip, now: ctx.date)
                } else {
                    missing
                }
            }
            .background(DS.sheet)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AvailRoute.self) { route in
                AvailabilityView(number: route.number)
            }
        }
        .confirmationDialog("Delete this trip?", isPresented: $confirmDelete,
                            titleVisibility: .visible) {
            Button("Delete Trip", role: .destructive) {
                store.remove(id)
                router.unfocus()
            }
        }
        .sheet(item: $altContext, onDismiss: {
            // the lookup modal hangs off the same sheet, so it can only
            // present once this one has fully gone
            if let number = pendingTrain {
                pendingTrain = nil
                router.showTrain(number)
            }
        }) { ctx in
            AlternateTrainsSheet(context: ctx) { pendingTrain = $0 }
                .environmentObject(bank)
        }
        .sheet(isPresented: $showEditBooking) {
            BookingEditView(id: id)
                .environmentObject(store)
        }
        .sensoryFeedback(.success, trigger: addedCount)
        .sensoryFeedback(.impact(weight: .medium), trigger: liveAct.activeNumber)
    }

    private var missing: some View {
        VStack(spacing: 14) {
            Text("This trip isn't available")
                .font(.dsHeadline)
                .foregroundStyle(DS.ink)
            Text("Its schedule is no longer cached on this device.")
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
            DSButton(title: "Close", style: .secondary) { router.unfocus() }
        }
        .padding(DS.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Layout

    private func detail(_ trip: HeldTrip, now: Date) -> some View {
        let live = trip.live
        let train = trip.train
        let tone = trip.tone(now)
        let moving = live.phase == .enroute || live.phase == .boarding
        let feed = FeedState(train.number, live.runDate)
        let rake = (live.phase == .scheduled || live.phase == .boarding)
            ? rakeLink(for: train, runDate: live.runDate, now: now) : nil
        let rec = store.record(forId: id)
        let pnrDigits = trip.isHeld ? (rec?.pnr ?? "").filter(\.isNumber) : ""
        // re-render the share card only when the picture meaningfully changes
        let shareKey = "\(trip.id)|\(live.phase)|\(trip.arrivalDelayMin)|\(Int(live.progress * 40))"

        return VStack(spacing: 0) {
            DetailHeader(trip: trip, onClose: { router.unfocus() }, onAdd: { add(trip) })
            Rectangle().fill(DS.separator).frame(height: 1)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        let banner = StatusBanner(trip: trip, now: now, tone: tone, rake: rake,
                                                  feed: feed, tappable: !live.events.isEmpty)
                        if live.events.isEmpty {
                            banner
                        } else {
                            Button {
                                withAnimation(.snappy) { proxy.scrollTo(updatesID, anchor: .top) }
                            } label: { banner }
                            .buttonStyle(.plain)
                            .accessibilityHint("Shows the updates")
                        }

                        sections(trip, now: now, tone: tone, feed: feed, rake: rake, rec: rec)
                            .padding(.horizontal, DS.gutter)
                            .padding(.top, 20)
                            .padding(.bottom, 32)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if router.detent != Router.peek {
                toolbar(trip, pnrDigits: pnrDigits)
            }
        }
        .onChange(of: moving, initial: true) { _, isMoving in
            tick = isMoving ? 1 : 15
        }
        .task(id: shareKey) {
            shareImage = renderTripShareCard(trip)
        }
        .task(id: id) {
            if moving {
                Analytics.shared.log(.liveWindowOpen, ["train": train.number])
            }
            await refreshLive(train.number, live.runDate)
        }
        .task(id: pnrDigits) {
            await checkPNR(pnrDigits)
        }
    }

    @ViewBuilder
    private func sections(_ trip: HeldTrip, now: Date, tone: StatusTone, feed: FeedState,
                          rake: RakeLink?, rec: TripRecord?) -> some View {
        let live = trip.live
        let train = trip.train
        let coach = bookedCoach(rec)

        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 0) {
                EndpointBlock(trip: trip, now: now, tone: tone, departing: true)
                JourneySpan(trip: trip)
                EndpointBlock(trip: trip, now: now, tone: tone, departing: false)
            }

            if live.phase == .arrived, trip.arrivalDelayMin >= 180,
               LiveFeed.shared.hasFeedData(train.number, live.runDate) {
                RefundBanner(delayMin: trip.arrivalDelayMin)
            }

            if trip.isHeld, let rec {
                booking(trip, rec: rec, now: now)
            }

            if coach != nil || live.phase != .arrived {
                VStack(alignment: .leading, spacing: 12) {
                    DSSectionHeader(title: coach != nil ? "Your Coach" : "Coach Position")
                    CoachPositionCard(train: train, highlight: coach, title: nil)
                }
            }

            if live.phase == .enroute || live.phase == .boarding {
                LiveRunCard(live: live, now: now, estimated: !feed.fresh)
            }

            StopTimeline(live: live, tone: tone, expanded: $showAllStops)

            if !live.events.isEmpty {
                UpdatesSection(events: live.events, fromFeed: feed.hasData,
                               expanded: $showAllUpdates)
                    .id(updatesID)
            }

            if !JClass.reservable(from: train.classes).isEmpty {
                NavigationLink(value: AvailRoute(number: train.number)) {
                    LinkRow(systemImage: "chair.lounge.fill",
                            title: "Check seats on other dates",
                            detail: "Availability and fares by class")
                }
                .buttonStyle(DSPressStyle())
            }

            GoodToKnow(trip: trip, now: now, rake: rake) { number in
                router.showTrain(number)
            }

            Text(sourceLine(train, feed: feed))
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: Booking

    @ViewBuilder
    private func booking(_ trip: HeldTrip, rec: TripRecord, now: Date) -> some View {
        let seat = seatAssigned(rec)
        if rec.pnr != nil || seat {
            let chart = trip.booking.flatMap {
                chartingStatus(trip.train, runDate: trip.live.runDate, booking: $0, now: now)
            }
            HStack(alignment: .top, spacing: 12) {
                if let pnr = rec.pnr {
                    PNRCard(pnr: pnr, check: pnrCheck, chart: chart) { showEditBooking = true }
                }
                SeatCard(coach: seat ? rec.coach : nil, seat: seat ? rec.seat : nil,
                         party: rec.berths?.count ?? 0) { showEditBooking = true }
            }
            .fixedSize(horizontal: false, vertical: true)
        } else {
            Button { showEditBooking = true } label: {
                LinkRow(systemImage: "ticket.fill",
                        title: "Add your booking",
                        detail: "PNR, coach and berth for this trip")
            }
            .buttonStyle(DSPressStyle())
        }
    }

    /// A coach and berth are assigned when both are present and not the
    /// em-dash placeholder a chart-pending PNR import used to write.
    private func seatAssigned(_ rec: TripRecord) -> Bool {
        guard let coach = rec.coach, coach != "—", !coach.isEmpty,
              let seat = rec.seat, seat != "—", !seat.isEmpty else { return false }
        return true
    }

    private func bookedCoach(_ rec: TripRecord?) -> String? {
        guard let coach = rec?.coach, coach != "—", !coach.isEmpty else { return nil }
        return coach
    }

    private func checkPNR(_ digits: String) async {
        // demo launches answer PNRs from the simulator, which wouldn't match
        // the seeded booking; chartingStatus covers them instead
        guard digits.count == 10, !isSnapshotLaunch() else {
            pnrCheck = .idle
            return
        }
        pnrCheck = .checking
        switch await PNRService.lookup(digits, now: Date()) {
        case .found(let info): pnrCheck = .status(PNRSummary(info))
        case .notFound(let reason): pnrCheck = .rejected(reason)
        case .offline: pnrCheck = .idle
        }
    }

    // MARK: Actions

    private func add(_ trip: HeldTrip) {
        store.add(trip.train, runDate: trip.live.runDate)
        Analytics.shared.log(.tripAdded, ["source": "detail", "train": trip.train.number])
        addedCount += 1
    }

    private func toggleLiveActivity(_ trip: HeldTrip) {
        if liveAct.isLive(trip.train.number) { liveAct.stop() } else { liveAct.start(trip) }
    }

    /// Prefilled mail draft to the feedback address, carrying the run being
    /// looked at so a data correction lands with context attached.
    private func reportIssueURL(_ trip: HeldTrip) -> URL {
        let train = trip.train
        let body = """
        Train: \(train.number) \(train.displayName)
        Route: \(train.origin.code) → \(train.destination.code)
        Run date: \(trip.live.runDate)

        What looks wrong:
        """
        var comps = URLComponents()
        comps.scheme = "mailto"
        comps.path = "feedback@railly.app"
        comps.queryItems = [
            URLQueryItem(name: "subject", value: "Railly data issue: \(train.number) \(train.displayName)"),
            URLQueryItem(name: "body", value: body),
        ]
        return comps.url ?? URL(string: "mailto:feedback@railly.app")!
    }

    private func shareSummary(_ trip: HeldTrip) -> String {
        let live = trip.live
        let status = trip.arrivalDelayMin > 5 ? "running \(trip.arrivalDelayMin)m late" : "on time"
        return "\(trip.train.number) \(trip.train.displayName): \(routeTitle(trip.train)), \(status). "
            + "Arrives \(fmtTime(live.arrivesEst)). Tracked with Railly."
    }

    // MARK: Toolbar

    private func toolbar(_ trip: HeldTrip, pnrDigits: String) -> some View {
        let live = trip.live
        let broadcasting = liveAct.isLive(trip.train.number)
        let canBroadcast = liveAct.isAvailable && (live.phase != .arrived || broadcasting)

        return HStack(spacing: 10) {
            shareButton(trip)
            if pnrDigits.count == 10 {
                alertsMenu(pnrDigits)
            }
            moreMenu(trip)
            Spacer(minLength: 8)
            if !trip.isHeld {
                DSPill(title: "Add Trip", systemImage: "plus") { add(trip) }
            } else if canBroadcast {
                DSPill(title: broadcasting ? "Live Activity On" : "Live Activity",
                       systemImage: broadcasting ? "bolt.fill" : "bolt",
                       tint: broadcasting ? DS.onTimeText : DS.action,
                       filled: !broadcasting) {
                    toggleLiveActivity(trip)
                }
            }
        }
        .padding(.horizontal, DS.gutter)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(alignment: .top) {
            DS.sheet
                .overlay(alignment: .top) { Rectangle().fill(DS.separator).frame(height: 1) }
                .ignoresSafeArea(edges: .bottom)
        }
        .onChange(of: alertWaitlist) { _, on in if on { PNRWatch.beginWatching() } }
        .onChange(of: alertChart) { _, on in if on { PNRWatch.beginWatching() } }
    }

    @ViewBuilder
    private func shareButton(_ trip: HeldTrip) -> some View {
        if let shareImage {
            ShareLink(item: shareImage,
                      preview: SharePreview(routeTitle(trip.train), image: shareImage)) {
                ToolbarGlyph(systemImage: "square.and.arrow.up")
            }
            .simultaneousGesture(TapGesture().onEnded {
                Analytics.shared.log(.shareCardSent, ["card": "trip", "train": trip.train.number])
            })
            .accessibilityLabel("Share trip")
        } else {
            ShareLink(item: shareSummary(trip)) {
                ToolbarGlyph(systemImage: "square.and.arrow.up")
            }
            .accessibilityLabel("Share trip")
        }
    }

    /// PNR alerts are app-wide switches (Settings → Alerts) applied to every
    /// watched PNR; the menu says so rather than implying a per-trip mute.
    private func alertsMenu(_ digits: String) -> some View {
        let on = alertWaitlist || alertChart
        return Menu {
            Section("Alerts for all watched PNRs") {
                Toggle(isOn: $alertWaitlist) {
                    Label("Waitlist movement", systemImage: "arrow.up.circle")
                }
                Toggle(isOn: $alertChart) {
                    Label("Chart prepared", systemImage: "doc.text")
                }
            }
            Button {
                Task { await checkPNR(digits) }
            } label: {
                Label("Check PNR Now", systemImage: "arrow.clockwise")
            }
        } label: {
            ToolbarGlyph(systemImage: on ? "bell.fill" : "bell.slash")
        }
        .accessibilityLabel(on ? "PNR alerts on" : "PNR alerts off")
    }

    private func moreMenu(_ trip: HeldTrip) -> some View {
        let train = trip.train
        return Menu {
            // tracked trains can broadcast too, and a running activity must
            // always be stoppable, even after its trip was deleted
            if liveAct.isLive(train.number) || (liveAct.isAvailable && trip.live.phase != .arrived) {
                let on = liveAct.isLive(train.number)
                Button { toggleLiveActivity(trip) } label: {
                    Label(on ? "Stop Live Activity" : "Start Live Activity",
                          systemImage: on ? "bolt.slash" : "bolt.fill")
                }
            }
            Button {
                altContext = AltContext(origin: train.origin.code,
                                        destination: train.destination.code,
                                        destinationName: train.destination.name,
                                        exclude: train.number)
            } label: {
                Label("Alternate Trains", systemImage: "arrow.triangle.branch")
            }
            if trip.isHeld {
                Button { showEditBooking = true } label: {
                    Label("Edit Booking", systemImage: "square.and.pencil")
                }
            }
            Link(destination: reportIssueURL(trip)) {
                Label("Report Data Issue", systemImage: "exclamationmark.bubble")
            }
            Divider()
            if trip.isHeld {
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete Trip", systemImage: "trash")
                }
            } else {
                Button { add(trip) } label: {
                    Label("Add to My Trips", systemImage: "plus.circle")
                }
            }
        } label: {
            ToolbarGlyph(systemImage: "ellipsis")
        }
        .accessibilityLabel("More")
    }
}

// MARK: - Shared bits

private func routeTitle(_ train: Train) -> String {
    "\(cityFor(train.origin.code, train.origin.name)) to \(cityFor(train.destination.code, train.destination.name))"
}

/// "1h 5m" for a delay in minutes.
private func delayText(_ minutes: Int) -> String { fmtDuration(Double(minutes)) }

/// Where a run's numbers come from right now.
private struct FeedState {
    /// a fresh real snapshot is driving the run
    let fresh: Bool
    /// a real snapshot has landed at any age
    let hasData: Bool
    /// age of the stored snapshot, when there is one
    let age: TimeInterval?

    init(_ number: String, _ runDate: String) {
        fresh = LiveFeed.shared.isLive(number, runDate)
        age = LiveFeed.shared.snapshotAge(number, runDate)
        hasData = age != nil
    }
}

/// Where every number on this screen comes from, said plainly. The drawn
/// line is real OpenStreetMap track only where a segment is bundled for that
/// leg; the note says which.
private func sourceLine(_ train: Train, feed: FeedState) -> String {
    let route = RailRouteCache.route(for: train)
    let path: String
    if route.approximatedLegs == 0 {
        path = "Route drawn on OpenStreetMap track."
    } else if route.tracedLegs == 0 {
        path = "Halts are exact; the line between them is drawn straight."
    } else {
        path = "\(route.tracedLegs) of \(route.tracedLegs + route.approximatedLegs) legs "
            + "drawn on OpenStreetMap track, the rest straight between halts."
    }
    let live = feed.hasData
        ? "Delays from the live running feed; position placed on the track from them."
        : "Live position and delays estimated from the timetable."
    return "Schedule and platforms from erail.in. \(live)\n\(path)"
}

private struct AltContext: Identifiable {
    let id = UUID()
    let origin: String
    let destination: String
    let destinationName: String
    let exclude: String
}

/// Circle toolbar glyph, the DSCircleButton look for labels that can't be a
/// Button (ShareLink, Menu).
private struct ToolbarGlyph: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(DS.ink)
            .frame(width: 44, height: 44)
            .background(DS.fill, in: Circle())
            .contentShape(Circle())
    }
}

// MARK: - Header

private struct DetailHeader: View {
    let trip: HeldTrip
    let onClose: () -> Void
    let onAdd: () -> Void

    var body: some View {
        let train = trip.train
        HStack(spacing: 12) {
            TrainMark(category: train.category, size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(train.number) · \(fmtDay(trip.live.departsAt))")
                    .eyebrow()
                    .lineLimit(1)
                Text(routeTitle(train))
                    .font(.dsTitle)
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 8)
            if !trip.isHeld {
                DSPill(title: "Add", systemImage: "plus", action: onAdd)
                    .accessibilityLabel("Add to My Trips")
            }
            DSCircleButton(systemImage: "xmark", label: "Close", action: onClose)
        }
        .padding(.horizontal, DS.gutter)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }
}

// MARK: - Status banner

private struct StatusBanner: View {
    let trip: HeldTrip
    let now: Date
    let tone: StatusTone
    let rake: RakeLink?
    let feed: FeedState
    let tappable: Bool

    var body: some View {
        let line = headline
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                (Text(line.prefix).foregroundStyle(DS.ink)
                    + Text(line.value).foregroundStyle(line.color))
                    .font(.dsHeadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .rollingNumbers(value: line.value)
                Spacer(minLength: 8)
                sourceBadge
            }
            (Text(explanation) + Text(tappable ? "  ›" : "").fontWeight(.semibold))
                .font(.dsBody)
                .foregroundStyle(DS.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.gutter)
        .padding(.vertical, 14)
        .background(tone.wash)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var sourceBadge: some View {
        if feed.fresh {
            DSChip(text: "LIVE", color: DS.onTimeText)
        } else if let age = feed.age {
            DSChip(text: "AS OF \(max(1, Int((age / 60).rounded())))M AGO", color: DS.rac)
        } else {
            EstimateTag()
        }
    }

    private var headline: (prefix: String, value: String, color: Color) {
        let live = trip.live
        switch live.phase {
        case .scheduled, .boarding:
            let mins = max(1, live.stopTimings[0].depEst.timeIntervalSince(now) / 60)
            let value = mins >= 48 * 60
                ? "\(Int((mins / (24 * 60)).rounded())) days"
                : fmtDuration(mins)
            return ("Departs in ", value, tone.text)
        case .enroute:
            let mins = max(0, live.arrivesEst.timeIntervalSince(now) / 60)
            return ("Arriving in ", fmtDuration(mins), tone.text)
        case .arrived:
            let late = trip.arrivalDelayMin > 5
            return ("Arrived ", late ? "\(delayText(trip.arrivalDelayMin)) late" : "on time",
                    late ? DS.lateText : DS.onTimeText)
        }
    }

    private var explanation: String {
        let live = trip.live
        let train = trip.train
        let origin = cityFor(train.origin.code, train.origin.name)
        let dest = cityFor(train.destination.code, train.destination.name)

        switch live.phase {
        case .scheduled, .boarding:
            let depTime = fmtTime(live.departsAt)
            if let rake {
                if rake.delayMin <= 5 {
                    return "Inbound rake \(rake.inbound.number) is on schedule for the \(depTime) departure."
                }
                return rake.propagatedDelayMin > 5
                    ? "Inbound rake \(rake.inbound.number) is \(delayText(rake.delayMin)) late, so expect a \(delayText(rake.propagatedDelayMin)) late start."
                    : "Inbound rake \(rake.inbound.number) is \(delayText(rake.delayMin)) late, but the turnaround still covers the \(depTime) start."
            }
            let startDelay = live.stopTimings[0].delayMin
            if tone != .scheduled && startDelay > 5 {
                return "Projected to leave \(origin) \(delayText(startDelay)) late, at \(fmtTime(live.stopTimings[0].depEst)). The railway hasn't announced a delay."
            }
            if let pf = train.origin.platform {
                return "Leaves \(origin) at \(depTime) from platform \(pf)."
            }
            return "Leaves \(origin) at \(depTime). Platform not yet announced."

        case .enroute:
            let arrival = trip.arrivalDelayMin > 5
                ? "Reaches \(dest) at \(fmtTime(live.arrivesEst)), \(delayText(trip.arrivalDelayMin)) late."
                : "Reaches \(dest) on time at \(fmtTime(live.arrivesEst))."
            guard let event = explainingEvent else { return arrival }
            let detail = event.detail.map { ", \($0)" } ?? ""
            return "\(event.text)\(detail). \(arrival)"

        case .arrived:
            let late = trip.arrivalDelayMin > 5
            return late
                ? "Reached \(dest) at \(fmtTime(live.arrivesEst)), against a scheduled \(fmtTime(live.arrivesSched))."
                : "Reached \(dest) at \(fmtTime(live.arrivesEst)), on schedule."
        }
    }

    /// The most recent event that explains the running (a delay, recovery,
    /// long halt or platform change within the last three hours), else the
    /// latest event of any kind. Events arrive newest first.
    private var explainingEvent: TrainEvent? {
        let events = trip.live.events
        let telling = events.first { e in
            switch e.kind {
            case .delay, .recovery, .halt, .platform:
                return now.timeIntervalSince(e.time) < 3 * 3600
            default:
                return false
            }
        }
        return telling ?? events.first
    }
}

/// IR pays a full TDR refund when the train reaches 3h+ late. Only shown on
/// real feed data: a projection is no basis for a money claim.
private struct RefundBanner: View {
    let delayMin: Int

    var body: some View {
        Link(destination: URL(string: "https://www.irctc.co.in/nget/tdr-details")!) {
            HStack(spacing: 12) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DS.onTime)
                VStack(alignment: .leading, spacing: 2) {
                    Text("You may be owed a full refund")
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                    Text("Reached \(delayText(delayMin)) late. File a TDR within 3 days.")
                        .font(.dsFootnote)
                        .foregroundStyle(DS.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.onTimeWash, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
        }
        .buttonStyle(DSPressStyle())
    }
}

// MARK: - Departure & arrival

private struct EndpointBlock: View {
    let trip: HeldTrip
    let now: Date
    let tone: StatusTone
    let departing: Bool

    var body: some View {
        let train = trip.train
        let idx = departing ? 0 : train.stops.count - 1
        let stop = train.stops[idx]
        let timing = trip.live.stopTimings[idx]
        let sched = departing ? timing.depSched : timing.arrSched
        let est = departing ? timing.depEst : timing.arrEst
        // a far-off run hasn't committed to a forecast, so no delay is shown
        let committed = tone != .scheduled
        let late = committed && timing.delayMin > 5
        let endTone: StatusTone = (tone == .onTime || tone == .late) ? (late ? .late : .onTime) : tone
        let nextDay = !departing && isNextDay(est, after: trip.live.stopTimings[0].depEst)

        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    EndpointGlyph(departing: departing, tone: endTone)
                    Text("\(stop.code) · \(stop.name)")
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    timeText(committed ? est : sched, nextDay: nextDay, size: 46)
                        .foregroundStyle(endTone.heroTime)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .rollingNumbers(value: fmtTime(est))
                    if late {
                        Text(fmtTime(sched))
                            .font(.dsCallout)
                            .strikethrough()
                            .foregroundStyle(DS.tertiary)
                            .accessibilityLabel("scheduled \(fmtTime(sched))")
                    }
                }
                (Text(statusWord(late: late, committed: committed, delay: timing.delayMin))
                    .foregroundStyle(late ? DS.lateText : committed ? DS.onTimeText : DS.secondary)
                    .fontWeight(.semibold)
                    + Text(" · \(fmtDay(committed ? est : sched))").foregroundStyle(DS.secondary))
                    .font(.dsFootnote)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 6) {
                PlatformBadge(platform: stop.platform, departing: departing)
                Text(stop.platform.map { "Platform \($0)" } ?? "Platform TBA")
                    .font(.dsCaption)
                    .foregroundStyle(DS.secondary)
            }
            .padding(.top, 30)
        }
    }

    private func statusWord(late: Bool, committed: Bool, delay: Int) -> String {
        if !committed { return "Scheduled" }
        return late ? "\(delayText(delay)) late" : "On Time"
    }
}

/// Duration, track distance and the overnight flag on a thin vertical
/// connector between the two endpoint glyphs.
private struct JourneySpan: View {
    let trip: HeldTrip

    var body: some View {
        let live = trip.live
        let overnight = isNextDay(live.arrivesSched, after: live.departsAt)
        HStack(spacing: 14) {
            Rectangle()
                .fill(DS.fill2)
                .frame(width: 2, height: 34)
                .padding(.leading, 8)
            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text(fmtDuration(Double(trip.train.destination.arrMin)))
                Text("·")
                Text("\(Int(live.totalKm.rounded()).formatted()) km")
                if overnight {
                    Text("·")
                    Image(systemName: "moon")
                    Text("Overnight")
                }
            }
            .font(.dsFootnote)
            .foregroundStyle(DS.secondary)
            .monospacedDigit()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Booking cards

private enum PNRCheck: Equatable {
    case idle, checking
    case status(PNRSummary)
    /// the live service answered and rejected the PNR, in its own words
    case rejected(String)
}

/// The party's worst current status, the one that decides whether you board.
private struct PNRSummary: Equatable {
    enum Kind { case confirmed, rac, waiting }
    let text: String
    let kind: Kind
    let charted: Bool

    init(_ info: PNRInfo) {
        charted = info.chartPrepared
        let worst = info.passengers.map(\.current).min { Self.rank($0) < Self.rank($1) }
        switch worst {
        case .cnf, .noSeat, nil:
            text = "CNF"; kind = .confirmed
        case .rac(let n, _, _):
            text = n > 0 ? "RAC \(n)" : "RAC"; kind = .rac
        case .waitlist(let wl, let n):
            text = n > 0 ? "\(wl.rawValue) \(n)" : wl.rawValue; kind = .waiting
        case .notConfirmed:
            text = "NOT CNF"; kind = .waiting
        }
    }

    private static func rank(_ s: SeatStatus) -> Int {
        switch s {
        case .notConfirmed: return 0
        case .waitlist: return 1
        case .rac: return 2
        case .cnf, .noSeat: return 3
        }
    }

    var color: Color {
        switch kind {
        case .confirmed: return DS.onTimeText
        case .rac: return DS.rac
        case .waiting: return DS.lateText
        }
    }
}

private struct PNRCard: View {
    let pnr: String
    let check: PNRCheck
    let chart: ChartingStatus?
    let onEdit: () -> Void
    @State private var copied = false

    private var digits: String { pnr.filter(\.isNumber) }

    /// 3-3-4, the way a PNR is read aloud.
    private var grouped: String {
        let d = Array(digits)
        guard d.count == 10 else { return pnr }
        return "\(String(d[0..<3])) \(String(d[3..<6])) \(String(d[6..<10]))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: "ticket")
                    .font(.system(size: 19))
                    .foregroundStyle(DS.ink)
                Spacer()
                Button {
                    #if os(iOS)
                    UIPasteboard.general.string = digits
                    #endif
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.4))
                        copied = false
                    }
                } label: {
                    DSChip(text: copied ? "COPIED" : "COPY",
                           color: copied ? DS.onTimeText : DS.action)
                        .animation(.snappy(duration: 0.2), value: copied)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Copy PNR")
                .sensoryFeedback(trigger: copied) { _, now in now ? .success : nil }
            }
            Spacer(minLength: 14)
            Text(grouped)
                .font(.dsHeadline)
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 6) {
                Text("PNR").font(.dsFootnote).foregroundStyle(DS.secondary)
                statusChip
            }
            .padding(.top, 3)
            if case .rejected(let reason) = check {
                Text(reason)
                    .font(.dsCaption)
                    .foregroundStyle(DS.lateText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .dsCard(padding: 14)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Edit booking")
    }

    @ViewBuilder
    private var statusChip: some View {
        switch check {
        case .status(let s):
            DSChip(text: s.text, color: s.color)
            if s.charted {
                Text("Charted").font(.dsCaption).foregroundStyle(DS.secondary)
            }
        case .checking:
            ProgressView().controlSize(.mini)
        case .idle, .rejected:
            if let chart {
                if chart.prepared {
                    DSChip(text: "CNF", color: DS.onTimeText)
                } else {
                    DSChip(text: chart.waitlistStatus,
                           color: chart.waitlistStatus.hasPrefix("RAC") ? DS.rac : DS.lateText)
                }
            }
        }
    }
}

private struct SeatCard: View {
    let coach: String?
    let seat: String?
    let party: Int
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: "bed.double")
                    .font(.system(size: 19))
                    .foregroundStyle(DS.ink)
                    .frame(height: 22)
                Spacer(minLength: 14)
                if let coach, let seat {
                    Text("\(coach) · \(seat)")
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text("Not assigned")
                        .font(.dsHeadline)
                        .foregroundStyle(DS.secondary)
                }
                Text(party > 1 ? "\(party) berths on this PNR" : "Coach · Berth")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
                    .padding(.top, 3)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .dsCard(padding: 14)
        }
        .buttonStyle(DSPressStyle())
        .accessibilityHint("Edit booking")
    }
}

/// A full-width tappable card row: icon, title, detail, chevron.
private struct LinkRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.action)
                .frame(width: 36, height: 36)
                .background(DS.action.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.dsHeadline).foregroundStyle(DS.ink)
                Text(detail).font(.dsFootnote).foregroundStyle(DS.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.tertiary)
        }
        .dsCard(padding: 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Live run

private struct LiveRunCard: View {
    let live: LiveStatus
    let now: Date
    let estimated: Bool

    var body: some View {
        let hereIdx = live.atStation ? live.prevStopIdx : live.nextStopIdx
        let here = live.train.stops[hereIdx]
        let hereTiming = live.stopTimings[hereIdx]
        let hereTime = live.atStation ? hereTiming.depEst : hereTiming.arrEst
        let covered = "\(Int(live.progressKm.rounded()).formatted()) km"
        let speed = live.atStation ? "Stopped" : fmtSpeed(live.speedKmh)
        let toGo = fmtDuration(max(0, live.arrivesEst.timeIntervalSince(now) / 60))

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                DSSectionHeader(title: "Live Run",
                                subtitle: "\(Int((live.progress * 100).rounded()))% of \(Int(live.totalKm.rounded()).formatted()) km")
                if estimated { EstimateTag() }
            }
            VStack(alignment: .leading, spacing: 16) {
                DSProgress(value: live.progress, tint: DS.action, height: 6)
                    .animation(.linear(duration: 1), value: live.progress)
                HStack(alignment: .top) {
                    DSStat(label: "Covered", value: covered)
                        .rollingNumbers(value: covered)
                    Spacer()
                    DSStat(label: "Speed", value: speed)
                        .rollingNumbers(value: speed)
                    Spacer()
                    DSStat(label: "To go", value: toGo, alignment: .trailing)
                        .rollingNumbers(value: toGo)
                }
                Rectangle().fill(DS.separator).frame(height: 1)
                HStack(spacing: 8) {
                    (Text(live.atStation ? "At " : "Next ").foregroundStyle(DS.secondary)
                        + Text(here.name).foregroundStyle(DS.ink).fontWeight(.semibold))
                        .font(.dsCallout)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(live.atStation ? "Departs \(fmtTime(hereTime))" : fmtTime(hereTime))
                        .font(.dsCallout.weight(.semibold))
                        .foregroundStyle(hereTiming.delayMin > 5 ? DS.lateText : DS.onTimeText)
                        .monospacedDigit()
                }
            }
            .dsCard()
        }
    }
}

// MARK: - Journey timeline

private struct StopTimeline: View {
    let live: LiveStatus
    let tone: StatusTone
    @Binding var expanded: Bool

    private enum Row: Identifiable {
        case stop(Int)
        case gap(count: Int, after: Int)

        var id: String {
            switch self {
            case .stop(let i): return "s\(i)"
            case .gap(_, let after): return "g\(after)"
            }
        }
    }

    private var stops: [Stop] { live.train.stops }

    private var keyStops: [Int] {
        let n = stops.count
        return Array(Set([0, live.prevStopIdx, live.nextStopIdx, n - 1])).sorted()
    }

    private var rows: [Row] {
        if expanded { return stops.indices.map { .stop($0) } }
        var out: [Row] = []
        var last: Int?
        for i in keyStops {
            if let last, i - last > 1 { out.append(.gap(count: i - last - 1, after: last)) }
            out.append(.stop(i))
            last = i
        }
        return out
    }

    var body: some View {
        let n = stops.count
        let halts = max(0, n - 2)
        let showEstimate = tone != .scheduled

        VStack(alignment: .leading, spacing: 12) {
            DSSectionHeader(title: "Journey",
                            subtitle: halts == 0 ? "Non-stop" : "\(halts) halts between \(stops[0].code) and \(stops[n - 1].code)")
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Scheduled").frame(width: 66, alignment: .trailing)
                    if showEstimate {
                        Text("Estimated").frame(width: 66, alignment: .trailing)
                    }
                }
                .font(.dsCaption)
                .foregroundStyle(DS.secondary)
                .padding(.bottom, 4)

                ForEach(rows) { row in
                    switch row {
                    case .stop(let i):
                        StopRow(live: live, index: i, showEstimate: showEstimate)
                    case .gap(let count, let after):
                        gapRow(count: count, reached: reached(after + 1))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DS.sheet, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous).stroke(DS.separator, lineWidth: 1))

            if n > keyStops.count {
                Button {
                    withAnimation(.snappy(duration: 0.35)) { expanded.toggle() }
                } label: {
                    Text(expanded ? "Show fewer stops" : "Show all \(n) stops")
                        .font(.dsSubhead)
                        .foregroundStyle(DS.action)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .dsWell()
                }
                .buttonStyle(DSPressStyle())
            }
        }
    }

    private func reached(_ i: Int) -> Bool {
        let t = live.stopTimings[i]
        return t.passed || t.current || (live.phase == .enroute && i <= live.prevStopIdx)
    }

    private func gapRow(count: Int, reached: Bool) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.35)) { expanded = true }
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 30)
                Text("\(count) more \(count == 1 ? "stop" : "stops")")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.action)
                Spacer()
            }
            .frame(height: 30)
            .background(alignment: .leading) {
                RailLine()
                    .stroke(reached ? DS.route : DS.fill2,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 4]))
                    .frame(width: 2)
                    .padding(.leading, 10)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A vertical line through the middle of its frame.
private struct RailLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}

private struct StopRow: View {
    let live: LiveStatus
    let index: Int
    let showEstimate: Bool

    private static let dotY: CGFloat = 19

    var body: some View {
        let stop = live.train.stops[index]
        let t = live.stopTimings[index]
        let n = live.train.stops.count
        let isOrigin = index == 0
        let sched = isOrigin ? t.depSched : t.arrSched
        let est = isOrigin ? t.depEst : t.arrEst
        let origin = live.stopTimings[0].depSched
        let halt = stop.depMin - stop.arrMin
        let isNext = live.phase == .enroute && !live.atStation && index == live.nextStopIdx
        let dim = t.passed && !t.current

        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(stop.name)
                        .font(t.current || isNext ? .dsHeadline : .dsCallout)
                        .foregroundStyle(dim ? DS.secondary : DS.ink)
                        .lineLimit(1)
                    if t.current {
                        DSChip(text: "NOW", color: DS.action)
                    } else if isNext {
                        DSChip(text: "NEXT", color: DS.action)
                    }
                }
                Text(caption(stop, halt: halt, first: isOrigin, last: index == n - 1))
                    .font(.dsCaption)
                    .foregroundStyle(DS.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            timeText(sched, nextDay: isNextDay(sched, after: origin), size: 14, weight: .medium)
                .foregroundStyle(dim ? DS.tertiary : DS.ink2)
                .monospacedDigit()
                .frame(width: 66, alignment: .trailing)
            if showEstimate {
                timeText(est, nextDay: isNextDay(est, after: origin), size: 14, weight: .semibold)
                    .foregroundStyle(t.delayMin > 5 ? DS.lateText : DS.onTimeText)
                    .opacity(dim ? 0.6 : 1)
                    .monospacedDigit()
                    .frame(width: 66, alignment: .trailing)
            }
        }
        .padding(.vertical, 10)
        .padding(.leading, 30)
        .background(alignment: .leading) { rail(t: t, n: n) }
        .accessibilityElement(children: .combine)
    }

    private func caption(_ stop: Stop, halt: Int, first: Bool, last: Bool) -> String {
        var parts = [stop.code]
        if let pf = stop.platform { parts.append("PF \(pf)") }
        if !first && !last && halt > 0 { parts.append("\(halt)m halt") }
        return parts.joined(separator: " · ")
    }

    private func rail(t: StopTiming, n: Int) -> some View {
        let reached = t.passed || t.current || (live.phase == .enroute && index <= live.prevStopIdx)
        let departed = t.passed
        let trainHere = live.phase == .enroute && !live.atStation && index == live.prevStopIdx

        return VStack(spacing: 0) {
            Rectangle()
                .fill(index == 0 ? .clear : (reached ? DS.route : DS.fill2))
                .frame(width: 2, height: Self.dotY - 6)
            dot(reached: reached, current: t.current)
            ZStack {
                Rectangle()
                    .fill(index == n - 1 ? .clear : (departed ? DS.route : DS.fill2))
                    .frame(width: 2)
                if trainHere {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(DS.action, in: Circle())
                        .overlay(Circle().stroke(DS.sheet, lineWidth: 2))
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 22)
    }

    private func dot(reached: Bool, current: Bool) -> some View {
        ZStack {
            if current {
                Circle().fill(DS.action.opacity(0.2)).frame(width: 20, height: 20)
                Circle().fill(DS.action).frame(width: 10, height: 10)
            } else {
                Circle()
                    .fill(reached ? DS.route : DS.sheet)
                    .overlay(Circle().stroke(reached ? DS.route : DS.tertiary, lineWidth: 2))
                    .frame(width: 10, height: 10)
            }
        }
        .frame(width: 20, height: 12)
    }
}

// MARK: - Updates

private struct UpdatesSection: View {
    let events: [TrainEvent]
    let fromFeed: Bool
    @Binding var expanded: Bool

    private static let collapsedCount = 3

    var body: some View {
        let shown = expanded ? events : Array(events.prefix(Self.collapsedCount))
        VStack(alignment: .leading, spacing: 12) {
            DSSectionHeader(title: "Updates",
                            subtitle: "\(events.count) \(events.count == 1 ? "update" : "updates") · "
                                + (fromFeed ? "from the live running feed" : "estimated from the timetable"))
            VStack(spacing: 0) {
                ForEach(Array(shown.enumerated()), id: \.offset) { i, event in
                    if i > 0 { Rectangle().fill(DS.separator).frame(height: 1).padding(.leading, 44) }
                    row(event)
                }
            }
            .dsCard(padding: 0)

            if events.count > Self.collapsedCount {
                Button {
                    withAnimation(.snappy(duration: 0.35)) { expanded.toggle() }
                } label: {
                    Text(expanded ? "Show fewer updates" : "Show all \(events.count) updates")
                        .font(.dsSubhead)
                        .foregroundStyle(DS.action)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .dsWell()
                }
                .buttonStyle(DSPressStyle())
            }
        }
    }

    private func row(_ event: TrainEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon(event.kind))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color(event.kind))
                .frame(width: 18)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.text)
                    .font(.dsCallout)
                    .foregroundStyle(DS.ink)
                if let detail = event.detail {
                    Text(detail)
                        .font(.dsFootnote)
                        .foregroundStyle(DS.secondary)
                }
            }
            Spacer(minLength: 8)
            Text(fmtTime(event.time))
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func icon(_ kind: TrainEventKind) -> String {
        switch kind {
        case .delay: return "exclamationmark.triangle.fill"
        case .recovery: return "chart.line.downtrend.xyaxis"
        case .platform: return "signpost.right.fill"
        case .arrived: return "checkmark.seal.fill"
        case .halt: return "pause.circle.fill"
        case .summary: return "sun.horizon.fill"
        case .departed, .stop: return "arrow.up.right.circle.fill"
        }
    }

    private func color(_ kind: TrainEventKind) -> Color {
        switch kind {
        case .delay: return DS.late
        case .recovery, .arrived: return DS.onTime
        case .platform: return DS.rac
        case .summary: return DS.action
        case .halt, .departed, .stop: return DS.tertiary
        }
    }
}

// MARK: - Good to know

/// Only facts the schedule, rake and rules actually state. Nothing here is
/// guessed: no pantry, no amenities, no cleanliness scores.
private struct GoodToKnow: View {
    let trip: HeldTrip
    let now: Date
    let rake: RakeLink?
    let onRake: (String) -> Void

    var body: some View {
        let train = trip.train
        let live = trip.live
        VStack(alignment: .leading, spacing: 12) {
            DSSectionHeader(title: "Good to Know")
            VStack(spacing: 10) {
                if let rake {
                    Button { onRake(rake.inbound.number) } label: {
                        rakeRow(rake)
                    }
                    .buttonStyle(DSPressStyle())
                }
                if let chart = chartFact(live) {
                    FactRow(systemImage: "doc.text", title: chart.title, detail: chart.detail)
                }
                if let overnight = overnightFact(live) {
                    FactRow(systemImage: "moon.stars", title: overnight.title, detail: overnight.detail)
                }
                haltsFact(train)
                if let classes = classesFact(train) {
                    FactRow(systemImage: "square.grid.2x2", title: "Classes on this train", detail: classes)
                }
                FactRow(systemImage: "calendar", title: runsTitle(train.days),
                        detail: "\(train.category.label) service, \(Int(train.distanceKm.rounded()).formatted()) km end to end")
            }
        }
    }

    private func rakeRow(_ rake: RakeLink) -> some View {
        let late = rake.delayMin > 5
        let origin = cityFor(trip.train.origin.code, trip.train.origin.name)
        return HStack(spacing: 14) {
            TrainMark(category: rake.inbound.category, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your rake arrives as \(rake.inbound.number)")
                    .font(.dsHeadline)
                    .foregroundStyle(DS.ink)
                Text("\(rake.inbound.displayName) reaches \(origin) at \(fmtTime(rake.arrivesEst))")
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                DSChip(text: late ? "\(delayText(rake.delayMin)) late" : "On time",
                       color: late ? DS.lateText : DS.onTimeText)
                if !LiveFeed.shared.isLive(rake.inbound.number, rake.runDate) {
                    Text("Estimated").font(.dsCaption).foregroundStyle(DS.secondary)
                }
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.tertiary)
        }
        .dsCard(padding: 14)
        .contentShape(Rectangle())
    }

    private func chartFact(_ live: LiveStatus) -> (title: String, detail: String)? {
        guard live.phase == .scheduled || live.phase == .boarding else { return nil }
        let at = chartTime(departure: live.departsAt)
        let when = "\(fmtTime(at)), \(fmtDay(at))"
        return now < at
            ? ("Chart due \(when)", "Waitlist and RAC tickets are settled when it's prepared")
            : ("Chart was due \(when)", "Waitlist and RAC outcomes should now be final")
    }

    private func overnightFact(_ live: LiveStatus) -> (title: String, detail: String)? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: live.departsAt),
                                      to: cal.startOfDay(for: live.arrivesSched)).day ?? 0
        guard days > 0 else { return nil }
        let arrives = "Arrives \(fmtDay(live.arrivesSched)) at \(fmtTime(live.arrivesSched))"
        return days == 1
            ? ("Overnight journey", "\(arrives), the next day")
            : ("Arrives on day \(days + 1)", arrives)
    }

    @ViewBuilder
    private func haltsFact(_ train: Train) -> some View {
        let middle = train.stops.dropFirst().dropLast()
        if middle.isEmpty {
            FactRow(systemImage: "arrow.right.circle",
                    title: "Non-stop",
                    detail: "No halts between \(train.origin.name) and \(train.destination.name)")
        } else {
            let longest = middle.max { ($0.depMin - $0.arrMin) < ($1.depMin - $1.arrMin) }
            let minutes = longest.map { $0.depMin - $0.arrMin } ?? 0
            FactRow(systemImage: "pause.circle",
                    title: "\(middle.count) \(middle.count == 1 ? "halt" : "halts") on the way",
                    detail: longest.map { minutes > 0 ? "Longest is \(minutes)m at \($0.name)" : "All brief halts" } ?? "")
        }
    }

    private func classesFact(_ train: Train) -> String? {
        let classes = train.classes.compactMap(JClass.init(rawValue:)).sorted { $0.order < $1.order }
        guard !classes.isEmpty else { return nil }
        return classes.map { "\($0.rawValue) \($0.label)" }.joined(separator: " · ")
    }

    private func runsTitle(_ days: [Day]) -> String {
        if Set(days).count == 7 { return "Runs daily" }
        let ordered = Day.allCases.filter { days.contains($0) }
        return "Runs " + ordered.map(\.rawValue).joined(separator: ", ")
    }
}

private struct FactRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(DS.ink)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.dsHeadline).foregroundStyle(DS.ink)
                Text(detail)
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dsCard(padding: 14)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Alternate trains

/// Other real trains on the same journey, matched offline against the
/// resolved train bank (bundled seeds + everything ever fetched). Picking one
/// hands its number back; the detail then focuses that train on the globe.
private struct AlternateTrainsSheet: View {
    let context: AltContext
    let onPick: (String) -> Void
    @EnvironmentObject private var bank: TrainBank
    @Environment(\.dismiss) private var dismiss

    /// A train serves the route when it stops at the origin and later the
    /// destination; those are the true alternates, ranked first. Any other
    /// train that still halts at the destination follows.
    private func servesRoute(_ t: Train) -> Bool {
        let codes = t.stops.map(\.code)
        guard let oi = codes.firstIndex(of: context.origin),
              let di = codes.lastIndex(of: context.destination) else { return false }
        return oi < di
    }

    private var alternates: [Train] {
        bank.trains.values
            .filter { t in
                guard t.number != context.exclude,
                      let di = t.stops.map(\.code).lastIndex(of: context.destination) else { return false }
                return di > 0
            }
            .sorted { lhs, rhs in
                let ls = servesRoute(lhs), rs = servesRoute(rhs)
                if ls != rs { return ls }
                return parseHM(lhs.departureTime) < parseHM(rhs.departureTime)
            }
    }

    var body: some View {
        let list = alternates
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if list.isEmpty {
                        emptyState
                    } else {
                        Text("\(list.count) trains to \(cityFor(context.destination, context.destinationName))")
                            .eyebrow()
                            .padding(.top, 16)
                            .padding(.bottom, 6)
                        ForEach(list) { t in
                            Button {
                                onPick(t.number)
                                dismiss()
                            } label: {
                                row(t, direct: servesRoute(t))
                            }
                            .buttonStyle(.pressableRow)
                        }
                    }
                }
                .padding(.horizontal, DS.gutter)
                .padding(.bottom, 40)
            }
            .background(DS.sheet)
            .navigationTitle("Alternate Trains")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func row(_ t: Train, direct: Bool) -> some View {
        HStack(spacing: 12) {
            TrainMark(category: t.category, size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(t.number)
                    .font(.dsFootnote)
                    .foregroundStyle(DS.secondary)
                    .monospacedDigit()
                Text(t.displayName)
                    .font(.dsHeadline)
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(t.departureTime)
                    .font(.dsSubhead)
                    .foregroundStyle(DS.ink)
                    .monospacedDigit()
                Text(direct ? "\(context.origin) → \(context.destination)" : "\(t.origin.code) → \(t.destination.code)")
                    .font(.dsCaption)
                    .foregroundStyle(DS.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.tertiary)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.separator).frame(height: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 30))
                .foregroundStyle(DS.tertiary)
                .padding(.bottom, 4)
            Text("No alternates offline yet")
                .font(.dsHeadline)
                .foregroundStyle(DS.ink)
            Text("Search trains on this route and they'll turn up here, no signal needed.")
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
