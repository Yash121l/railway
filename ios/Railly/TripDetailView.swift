import MapKit
import SwiftUI

private func toneColor(_ delayMin: Int) -> Color {
    delayMin > 5 ? .lateRed : .onTime
}

/// Sub-16pt variant: the darker green passes AA at caption/row sizes where the
/// fill green wouldn't. Large numerals keep `toneColor`.
private func toneTextColor(_ delayMin: Int) -> Color {
    delayMin > 5 ? .lateRed : .textGreen
}

/// Route map: flown portion solid, remainder dashed — Flighty's arc treatment.
private struct TripMapView: View {
    let live: LiveStatus

    var body: some View {
        let route = RailRouteCache.route(for: live.train)
        let pos = CLLocationCoordinate2D(latitude: live.positionLat, longitude: live.positionLng)
        let lats = live.train.stops.map(\.lat)
        let lngs = live.train.stops.map(\.lng)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (lats.min()! + lats.max()!) / 2,
                longitude: (lngs.min()! + lngs.max()!) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(2, (lats.max()! - lats.min()!) * 1.5),
                longitudeDelta: max(2, (lngs.max()! - lngs.min()!) * 1.5)
            )
        )

        Map(initialPosition: .region(region)) {
            if live.phase == .enroute {
                // Both halves come off the same polyline the marker sits on, so
                // the line meets the train exactly instead of jumping to it.
                MapPolyline(coordinates: route.travelled(toLeg: live.prevStopIdx,
                                                         frac: live.legFraction))
                    .stroke(Color.arcBlue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                MapPolyline(coordinates: route.remaining(fromLeg: live.prevStopIdx,
                                                         frac: live.legFraction))
                    .stroke(Color.arcBlue.opacity(0.45),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [1, 6]))
            } else {
                MapPolyline(coordinates: route.coords)
                    .stroke(
                        Color.arcBlue.opacity(live.phase == .arrived ? 1 : 0.5),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
            }
            ForEach(Array(live.train.stops.enumerated()), id: \.offset) { _, stop in
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: stop.lat, longitude: stop.lng)) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1.5))
                        .accessibilityLabel(stop.name)
                }
            }
            if live.phase == .enroute {
                Annotation("", coordinate: pos) {
                    Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.arcBlue, lineWidth: 3).frame(width: 16, height: 16))
                        .shadow(color: Color.arcBlue, radius: 7)
                        .accessibilityLabel("\(live.train.displayName) current position")
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .colorScheme(.dark)
    }
}

private struct StatusBanner: View {
    let live: LiveStatus
    let now: Date
    var rake: RakeLink? = nil

    var body: some View {
        // en route, what matters is the delay at the DESTINATION —
        // the current interpolated delay can read "on time" while the
        // forecast still loses 40 minutes crossing Madhya Pradesh
        let arrDelay = live.stopTimings[live.stopTimings.count - 1].delayMin
        // pre-departure, a late inbound rake can push the start out past the
        // seeded origin delay — the forecast takes the worse of the two
        let startDelay = max(live.delayMin, rake?.propagatedDelayMin ?? 0)
        let late: Bool = {
            switch live.phase {
            case .enroute: return arrDelay > 5
            case .arrived: return live.delayMin > 5
            case .boarding, .scheduled: return startDelay > 5
            }
        }()
        let destCity = cityFor(live.train.destination.code, live.train.destination.name)

        VStack(alignment: .leading, spacing: 3) {
            switch live.phase {
            case .enroute:
                let remaining = max(0, live.arrivesEst.timeIntervalSince(now) / 60)
                headline("Arriving in ", fmtDuration(remaining), late: late)
                detail(late
                    ? "\(live.events.first(where: { $0.kind == .delay })?.text ?? "Running behind schedule") — reaches \(destCity) \(arrDelay)m late ›"
                    : "Running on time — reaches \(destCity) at \(fmtTime(live.arrivesEst)) ›")
            case .boarding, .scheduled:
                let toDep = max(0, live.stopTimings[0].depEst.timeIntervalSince(now) / 60)
                headline("Departure in ", fmtDuration(toDep), late: late)
                detail(preDepartureDetail(startDelay: startDelay))
            case .arrived:
                headline("Arrived ", late ? "\(live.delayMin)m late" : "on time", late: late)
                detail("Reached \(destCity) at \(fmtTime(live.arrivesEst)) ›")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(late ? Color.lateTint : Color.onTimeTint)
    }

    private func preDepartureDetail(startDelay: Int) -> String {
        if let rake, rake.delayMin > 5 {
            return startDelay > 5
                ? "Inbound rake \(rake.inbound.number) is \(rake.delayMin)m late — expect a \(startDelay)m late start ›"
                : "Inbound rake \(rake.inbound.number) ran \(rake.delayMin)m late but the turnaround holds the \(fmtTime(live.departsAt)) start ›"
        }
        return startDelay > 5
            ? "Railly predicts a \(startDelay)m late start — the railway hasn't announced it yet ›"
            : "Inbound rake is on schedule for a \(fmtTime(live.departsAt)) departure ›"
    }

    private func headline(_ prefix: String, _ value: String, late: Bool) -> some View {
        (Text(prefix).foregroundStyle(Color.inkline)
            + Text(value).foregroundStyle(late ? Color.lateRed : Color.onTime).fontWeight(.bold))
            .font(.system(.headline))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .rollingNumbers(value: value)
    }

    private func detail(_ s: String) -> some View {
        Text(s)
            .font(.system(.subheadline))
            .foregroundStyle(Color(hex: 0x374151))
    }
}

/// Giant colored time block per journey end, with the amber platform chip.
private struct EndBlock: View {
    let trip: HeldTrip
    let isDeparture: Bool

    var body: some View {
        let train = trip.train
        let idx = isDeparture ? 0 : train.stops.count - 1
        let stop = train.stops[idx]
        let timing = trip.live.stopTimings[idx]
        let sched = isDeparture ? timing.depSched : timing.arrSched
        let est = isDeparture ? timing.depEst : timing.arrEst
        let late = timing.delayMin > 5

        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Image(systemName: isDeparture ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 21, height: 21)
                        .background(Color.inkline, in: Circle())
                    Text("\(stop.code) · \(stop.name)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.inkline)
                        .lineLimit(1)
                }
                HStack(alignment: .firstTextBaseline, spacing: 9) {
                    Text(fmtTime(est))
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(toneColor(timing.delayMin))
                        .monospacedDigit()
                    if late {
                        Text(fmtTime(sched))
                            .font(.system(size: 14))
                            .strikethrough()
                            .foregroundStyle(Color.fadedGray)
                    }
                }
                (Text(late ? "\(timing.delayMin)m Late" : "On Time")
                    .foregroundStyle(toneTextColor(timing.delayMin)).fontWeight(.semibold)
                    + Text(" • \(fmtDay(est))").foregroundStyle(Color.subGray))
                    .font(.system(size: 13))
            }
            Spacer()
            let hasPlatform = stop.platform != nil
            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: isDeparture ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .black))
                    Text(stop.platform.map { "PF\($0)" } ?? "--")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(hasPlatform ? .black : Color.subGray)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(hasPlatform ? Color.gateAmber : Color.fillGray,
                            in: RoundedRectangle(cornerRadius: 10))
                Text(stop.platform.map { "Platform \($0)" } ?? "Platform TBA")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.subGray)
            }
        }
        .padding(.vertical, 12)
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color.inkline)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subGray)
                }
            }
            content
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

/// flighty's booking-code card: outline, icon, value, and a blue COPY chip
/// that flips to a green COPIED confirmation on tap.
private struct BookingCard: View {
    let icon: String
    let value: String
    let caption: String
    var copyAction: (() -> Void)? = nil
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundStyle(Color.inkline)
                Spacer()
                if let copyAction {
                    Button {
                        copyAction()
                        copied = true
                        Task {
                            try? await Task.sleep(for: .seconds(1.4))
                            copied = false
                        }
                    } label: {
                        Text(copied ? "COPIED" : "COPY")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(copied ? Color.textGreen : Color.chipBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(copied ? Color.onTime.opacity(0.14) : Color(hex: 0xE7F0FF),
                                        in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(trigger: copied) { _, now in now ? .success : nil }
                }
            }
            Text(value)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color.inkline)
                .monospacedDigit()
                .padding(.top, 8)
            Text(caption)
                .font(.system(size: 13))
                .foregroundStyle(Color.subGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .stroke(Color.cardStroke, lineWidth: 1)
        )
    }
}

struct TripDetailView: View {
    /// The route a trip's origin/destination define — carried into the
    /// Alternate Trains sheet so it can match offline without re-deriving.
    struct AltContext: Identifiable {
        let id = UUID()
        let origin: String
        let destination: String
        let originName: String
        let destinationName: String
        let exclude: String
    }

    let id: String
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var bank: TrainBank
    @ObservedObject private var liveAct = LiveActivityManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var altContext: AltContext?
    @State private var showEditBooking = false
    @State private var shareImage: Image?
    private let updatesCardID = "updates-card"

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let now = ctx.date
            if let trip = getTrip(id, now) {
                detail(trip: trip, now: now)
            } else {
                Text("This trip doesn't exist.")
                    .foregroundStyle(Color.subGray)
            }
        }
        // registered outside the per-second TimelineView so the destination
        // survives re-renders and registers reliably with the stack
        .navigationDestination(for: AvailRoute.self) { route in
            AvailabilityView(number: route.number)
        }
        .background(Color.white)
        .confirmationDialog("Delete this trip?", isPresented: $confirmDelete,
                            titleVisibility: .visible) {
            Button("Delete Trip", role: .destructive) {
                store.remove(id)
                dismiss()
            }
        }
        .sheet(item: $altContext) { ctx in
            AlternateTrainsSheet(context: ctx)
        }
        .sheet(isPresented: $showEditBooking) {
            BookingEditView(id: id)
                .environmentObject(store)
        }
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
        let route = "\(cityFor(trip.train.origin.code, trip.train.origin.name)) to \(cityFor(trip.train.destination.code, trip.train.destination.name))"
        let status = live.delayMin > 5 ? "running \(live.delayMin)m late" : "on time"
        return "\(trip.train.number) \(trip.train.name) — \(route), \(status). Arrives \(fmtTime(live.arrivesEst)). Tracked with Railly."
    }

    /// Title on the share sheet's preview card.
    private func shareTitle(_ trip: HeldTrip) -> String {
        "\(cityFor(trip.train.origin.code, trip.train.origin.name)) → \(cityFor(trip.train.destination.code, trip.train.destination.name))"
    }

    private func detail(trip: HeldTrip, now: Date) -> some View {
        let live = trip.live
        let train = trip.train
        // Where's My Rake — the inbound paired service, only while we wait to leave
        let rake = (live.phase == .scheduled || live.phase == .boarding)
            ? rakeLink(for: train, runDate: live.runDate, now: now) : nil
        // re-render the share card only when the picture meaningfully changes,
        // not on every one-second TimelineView tick
        let shareKey = "\(trip.id)|\(live.phase)|\(live.stopTimings.last?.delayMin ?? live.delayMin)|\(Int(live.progress * 40))"

        return ScrollViewReader { proxy in
            ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    TripMapView(live: live)
                        .frame(height: 300)
                        .topMapScrim()
                    // flighty's in-flight telemetry capsule, top-center
                    if live.phase == .enroute {
                        HStack(spacing: 8) {
                            Image(systemName: "gauge.with.needle")
                                .font(.system(size: 12, weight: .semibold))
                            Text(fmtSpeed(live.speedKmh, caps: true))
                                .rollingNumbers(value: "\(live.speedKmh)")
                            Rectangle().fill(.white.opacity(0.25)).frame(width: 1, height: 14)
                            Image(systemName: "tram.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("NEXT \(live.train.stops[live.nextStopIdx].code)")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .kerning(0.4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0x1C1E22).opacity(0.88), in: Capsule())
                        .padding(.top, 104)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 11) {
                        TrainMark(category: train.category, size: 44)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(train.number) • \(fmtDay(live.departsAt).uppercased())")
                                .font(.system(.caption, weight: .semibold))
                                .kerning(0.5)
                                .foregroundStyle(Color.subGray)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text("\(cityFor(train.origin.code, train.origin.name)) to \(cityFor(train.destination.code, train.destination.name))")
                                .font(.system(.title2, weight: .bold))
                                .foregroundStyle(Color.inkline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: 8)
                        liveSourceChip(train.number, live.runDate)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                    Button {
                        withAnimation { proxy.scrollTo(updatesCardID, anchor: .top) }
                    } label: {
                        StatusBanner(live: live, now: now, rake: rake)
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 0) {
                        EndBlock(trip: trip, isDeparture: true)
                        HStack(spacing: 7) {
                            Image(systemName: "clock")
                            Text(fmtDuration(Double(train.destination.arrMin)))
                            Text("•")
                            Text("\(Int(live.totalKm)) km")
                            if istDateISO(live.arrivesSched) != istDateISO(live.departsAt) {
                                Text("•")
                                Image(systemName: "moon")
                                Text("Overnight")
                            }
                            Rectangle().fill(Color.hairline).frame(height: 1)
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(Color.subGray)
                        EndBlock(trip: trip, isDeparture: false)
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 14) {
                        if let rake {
                            wheresMyRakeCard(rake, originCode: train.origin.code,
                                             originName: train.origin.name)
                        }
                        if live.phase == .arrived,
                           (live.stopTimings.last?.delayMin ?? 0) >= 180,
                           LiveFeed.shared.hasFeedData(train.number, live.runDate) {
                            tdrRefundBanner(live)
                        }
                        if live.phase == .enroute {
                            liveRun(live: live, now: now)
                        }
                        if !live.events.isEmpty {
                            updates(live.events)
                                .id(updatesCardID)
                        }
                        timetable(live: live)
                        if let rec = store.record(forId: id),
                           rec.pnr != nil || seatAssigned(rec) {
                            bookingSection(rec)
                        }
                        // Flighty-style live broadcast to lock screen + island
                        if liveAct.isAvailable && live.phase != .arrived {
                            liveActivityButton(trip)
                        }
                        // the platform ritual: where the coach stops
                        if trip.booking != nil || live.phase != .arrived {
                            CoachPositionCard(train: train,
                                              highlight: trip.booking?.coach)
                        }
                        // still ticketless on a future run — seats matter
                        if trip.booking == nil, live.phase == .scheduled,
                           !JClass.reservable(from: train.classes).isEmpty {
                            availabilityLink(train)
                        }
                        if !trip.isHeld {
                            addToTrips(trip)
                        }
                        Text(sourceNote(for: train))
                            .font(.system(size: 11))
                            .foregroundStyle(Color.subGray)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 44)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                        .fill(.white)
                )
                .offset(y: -26)
            }
            .readableColumn()
        }
        .scrollIndicators(.hidden)
        // white, not black: the map bleeds up top on its own; a black scroll
        // background showed through under the tab bar below the sheet.
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
        .mapDetailBar(title: "")
        // pull real running status for the train being viewed (no-op without
        // an indianrailapi.com key)
        .task(id: id) {
            if live.phase == .enroute || live.phase == .boarding {
                Analytics.shared.log(.liveWindowOpen, ["train": train.number])
            }
            let parts = id.split(separator: "_", maxSplits: 1).map(String.init)
            if parts.count == 2 { await refreshLive(parts[0], parts[1]) }
        }
        .task(id: shareKey) {
            shareImage = renderTripShareCard(trip)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let shareImage {
                    ShareLink(item: shareImage,
                              preview: SharePreview(shareTitle(trip), image: shareImage)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        Analytics.shared.log(.shareCardSent, ["card": "trip", "train": train.number])
                    })
                } else {
                    ShareLink(item: shareSummary(trip)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if let shareImage {
                        ShareLink(item: shareImage,
                                  preview: SharePreview(shareTitle(trip), image: shareImage)) {
                            Label("Share Trip", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        ShareLink(item: shareSummary(trip)) {
                            Label("Share Trip", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button {
                        altContext = AltContext(
                            origin: train.origin.code,
                            destination: train.destination.code,
                            originName: train.origin.name,
                            destinationName: train.destination.name,
                            exclude: train.number
                        )
                    } label: {
                        Label("Alternate Trains", systemImage: "arrow.triangle.branch")
                    }
                    if liveAct.isAvailable {
                        let on = liveAct.isLive(trip.train.number)
                        Button {
                            if on { liveAct.stop() } else { liveAct.start(trip) }
                        } label: {
                            Label(on ? "Stop Live Activity" : "Start Live Activity",
                                  systemImage: on ? "bolt.slash" : "bolt.fill")
                        }
                    }
                    if trip.isHeld {
                        Button {
                            showEditBooking = true
                        } label: {
                            Label("Edit Booking", systemImage: "square.and.pencil")
                        }
                    }
                    Divider()
                    Link(destination: reportIssueURL(trip)) {
                        Label("Report Data Issue", systemImage: "exclamationmark.bubble")
                    }
                    if trip.isHeld {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete Trip", systemImage: "trash")
                        }
                    } else {
                        Button {
                            store.add(trip.train, runDate: trip.live.runDate)
                            Analytics.shared.log(.tripAdded, ["source": "detail", "train": train.number])
                        } label: {
                            Label("Add to My Trips", systemImage: "plus.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        }
    }

    /// Live-source badge: green "LIVE" while a fresh real snapshot is driving
    /// the run, amber "AS OF Nm AGO" once it goes stale (we keep rendering the
    /// last real delays rather than switching back to the sim), nothing at all
    /// when the run is purely simulated.
    @ViewBuilder
    private func liveSourceChip(_ number: String, _ runDate: String) -> some View {
        if let age = LiveFeed.shared.snapshotAge(number, runDate) {
            let fresh = LiveFeed.shared.isLive(number, runDate)
            let tone = fresh ? Color.onTime : Color.gateAmber
            HStack(spacing: 5) {
                Circle().fill(tone).frame(width: 7, height: 7)
                Text(fresh ? "LIVE" : "AS OF \(max(1, Int((age / 60).rounded())))M AGO")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.5)
                    .foregroundStyle(fresh ? Color.textGreen : Color.subGray)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tone.opacity(0.12), in: Capsule())
        }
    }

    /// Where's My Rake — the paired return service (12951 ↔ 12952) whose rake
    /// turns around to become this train. A late rake in is a late start out;
    /// tapping tracks the inbound service itself.
    private func wheresMyRakeCard(_ link: RakeLink, originCode: String,
                                  originName: String) -> some View {
        let late = link.delayMin > 5
        return NavigationLink {
            ResolveDetailView(token: link.inbound.number)
        } label: {
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.uturn.down")
                        .font(.system(size: 11, weight: .bold))
                    Text("WHERE'S MY RAKE")
                        .font(.system(size: 11, weight: .bold)).kerning(0.8)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.fadedGray)
                }
                .foregroundStyle(Color.subGray)

                HStack(spacing: 11) {
                    TrainMark(category: link.inbound.category, size: 36)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(link.inbound.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.inkline)
                            .lineLimit(1)
                        Text("\(link.inbound.number) · arrives \(cityFor(originCode, originName)) \(fmtTime(link.arrivesEst))")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.subGray)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Text(late ? "\(link.delayMin)m late" : "On time")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(late ? Color.lateRed : Color.textGreen)
                        .monospacedDigit()
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background((late ? Color.lateRed : Color.onTime).opacity(0.1),
                                    in: Capsule())
                }

                Text(link.propagatedDelayMin > 5
                    ? "Tight turnaround — Railly expects a \(link.propagatedDelayMin)m late start"
                    : late
                        ? "Enough turnaround buffer to still leave on time"
                        : "Rake is in on schedule for an on-time start")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.subGray)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .stroke(Color.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    /// IR pays a full TDR refund when the train reaches 3h+ late — surface it
    /// the moment the trip lands so the traveller files inside the 3-day window.
    private func tdrRefundBanner(_ live: LiveStatus) -> some View {
        let delay = live.stopTimings.last?.delayMin ?? 0
        return Link(destination: URL(string: "https://www.irctc.co.in/nget/tdr-details")!) {
            HStack(spacing: 12) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.onTime)
                VStack(alignment: .leading, spacing: 2) {
                    Text("You're owed a full refund")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.inkline)
                    Text("Reached \(fmtDuration(Double(delay))) late — file a TDR within 3 days")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.fadedGray)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.onTimeTint, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func liveRun(live: LiveStatus, now: Date) -> some View {
        SectionCard(title: "Live Run",
                    subtitle: "\(Int((live.progress * 100).rounded()))% of \(Int(live.totalKm)) km") {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.fillGray)
                    Capsule().fill(Color.arcBlue)
                        .frame(width: max(6, geo.size.width * live.progress))
                        .animation(.linear(duration: 1), value: live.progress)
                }
            }
            .frame(height: 7)

            let hereIdx = live.atStation ? live.prevStopIdx : live.nextStopIdx
            let hereStop = live.train.stops[hereIdx]
            let hereTiming = live.stopTimings[hereIdx]
            HStack {
                stat("\(Int(live.progressKm)) km", "Covered")
                Spacer()
                stat(fmtSpeed(live.speedKmh), "Speed")
                Spacer()
                stat(fmtDuration(max(0, live.arrivesEst.timeIntervalSince(now) / 60)), "To go")
            }
            HStack {
                (Text(live.atStation ? "At " : "Next ").foregroundStyle(Color.subGray)
                    + Text(hereStop.name).foregroundStyle(Color.inkline).fontWeight(.semibold))
                    .font(.system(size: 14))
                Spacer()
                Text(fmtTime(live.atStation ? hereTiming.depEst : hereTiming.arrEst))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(toneTextColor(hereTiming.delayMin))
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 13)).foregroundStyle(Color.subGray)
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.inkline)
                .monospacedDigit()
        }
    }

    private func updates(_ events: [TrainEvent]) -> some View {
        SectionCard(title: "Updates",
                    subtitle: "\(events.count) updates · estimated from schedule") {
            ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: icon(for: event.kind))
                        .font(.system(size: 12))
                        .foregroundStyle(color(for: event.kind))
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(event.text)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.inkline)
                        if let detail = event.detail {
                            Text(detail)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.subGray)
                        }
                    }
                    Spacer()
                    Text(fmtTime(event.time))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.subGray)
                        .monospacedDigit()
                }
            }
        }
    }

    private func icon(for kind: TrainEventKind) -> String {
        switch kind {
        case .delay: return "exclamationmark.triangle"
        case .recovery: return "chart.line.downtrend.xyaxis"
        case .platform: return "bell"
        case .arrived: return "checkmark.seal"
        case .halt: return "pause.circle"
        case .summary: return "sun.horizon"
        default: return "smallcircle.filled.circle"
        }
    }

    private func color(for kind: TrainEventKind) -> Color {
        switch kind {
        case .delay: return .lateRed
        case .recovery, .arrived: return .onTime
        case .platform: return .racAmber
        case .summary: return .arcBlue
        case .halt: return .subGray
        default: return .fadedGray
        }
    }

    private func timetable(live: LiveStatus) -> some View {
        SectionCard(title: "Detailed Timetable",
                    subtitle: "Scheduled and estimated for every halt") {
            HStack {
                Spacer()
                Text("Scheduled").frame(width: 70, alignment: .trailing)
                Text("Estimated").frame(width: 70, alignment: .trailing)
            }
            .font(.system(size: 12))
            .foregroundStyle(Color.subGray)

            ForEach(Array(live.train.stops.enumerated()), id: \.offset) { i, stop in
                let t = live.stopTimings[i]
                let sched = i == 0 ? t.depSched : t.arrSched
                let est = i == 0 ? t.depEst : t.arrEst
                HStack {
                    Text(stop.name)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkline)
                        .lineLimit(1)
                    if t.current {
                        Text("HERE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.arcBlue)
                    }
                    Spacer()
                    Text(fmtTime(sched))
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkline)
                        .monospacedDigit()
                        .frame(width: 70, alignment: .trailing)
                    Text(fmtTime(est))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(toneTextColor(t.delayMin))
                        .monospacedDigit()
                        .frame(width: 70, alignment: .trailing)
                }
                .opacity(t.passed && !t.current ? 0.45 : 1)
            }
        }
    }

    /// Broadcast this run to the Lock Screen and Dynamic Island — the same
    /// live picture the app shows, following you out of the app.
    private func liveActivityButton(_ trip: HeldTrip) -> some View {
        let on = liveAct.isLive(trip.train.number)
        return Button {
            if on { liveAct.stop() } else { liveAct.start(trip) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: on ? "bolt.fill" : "bolt")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(on ? Color.gateAmber : Color.arcBlue)
                    .frame(width: 34, height: 34)
                    .background((on ? Color.gateAmber : Color.arcBlue).opacity(0.14),
                                in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 1) {
                    Text(on ? "Live Activity is on" : "Track on your Lock Screen")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkline)
                    Text(on
                        ? "Live status on the Lock Screen & Dynamic Island"
                        : "Follow this train without opening Railly")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.subGray)
                        .lineLimit(1)
                }
                Spacer()
                Text(on ? "STOP" : "START")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(on ? Color.lateRed : Color.chipBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((on ? Color.lateRed : Color.chipBlue).opacity(0.1),
                                in: Capsule())
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .stroke(Color.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact, trigger: on)
    }

    /// Ticketless on an upcoming run: the seat question is the next thing
    /// the traveller asks — answer it one tap away.
    private func availabilityLink(_ train: Train) -> some View {
        NavigationLink(value: AvailRoute(number: train.number)) {
            HStack(spacing: 8) {
                Image(systemName: "chair.lounge")
                    .font(.system(size: 13, weight: .semibold))
                Text("Seat availability & fares")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.fadedGray)
            }
            .foregroundStyle(Color.arcBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color(hex: 0xEAF3FF), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    /// For trains being tracked without a ticket: one tap to hold the run.
    private func addToTrips(_ trip: HeldTrip) -> some View {
        Button {
            store.add(trip.train, runDate: trip.live.runDate)
            Analytics.shared.log(.tripAdded, ["source": "detail", "train": trip.train.number])
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add to My Trips")
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.arcBlue))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: trip.isHeld)
    }

    /// A coach & berth are assigned when both are present and not the em-dash
    /// placeholder a chart-pending PNR import used to write.
    private func seatAssigned(_ rec: TripRecord) -> Bool {
        guard let coach = rec.coach, coach != "—", !coach.isEmpty,
              let seat = rec.seat, seat != "—", !seat.isEmpty else { return false }
        return true
    }

    /// The ticket cards: PNR always, coach·berth only once a seat is assigned.
    /// With no seat the PNR card is alone in the row and widens to fill it.
    private func bookingSection(_ rec: TripRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TICKET")
                    .font(.system(size: 11, weight: .bold)).kerning(0.8)
                    .foregroundStyle(Color.subGray)
                Spacer()
                Button {
                    showEditBooking = true
                } label: {
                    Text("EDIT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.chipBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: 0xE7F0FF), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 12) {
                if let pnr = rec.pnr {
                    BookingCard(icon: "ticket", value: pnr, caption: "PNR") {
                        #if os(iOS)
                        UIPasteboard.general.string = pnr
                        #endif
                    }
                }
                if seatAssigned(rec), let coach = rec.coach, let seat = rec.seat {
                    let party = rec.berths?.count ?? 0
                    BookingCard(icon: "bed.double", value: "\(coach) · \(seat)",
                                caption: party > 1 ? "\(party) berths on this PNR" : "Coach · Berth",
                                copyAction: nil)
                }
            }
        }
    }
}

/// Other real trains on the same journey, matched offline against the resolved
/// train bank (bundled seeds + everything ever fetched). Rows reuse the Add
/// Trip search-result look; tapping one drops into the same resolve/add path.
private struct AlternateTrainsSheet: View {
    let context: TripDetailView.AltContext
    @EnvironmentObject private var bank: TrainBank
    @Environment(\.dismiss) private var dismiss

    /// A train serves the route when it stops at the origin and later the
    /// destination — those are the true alternates, ranked first. Any other
    /// train that still terminates or halts at the destination follows.
    private func servesRoute(_ t: Train) -> Bool {
        let codes = t.stops.map(\.code)
        guard let oi = codes.firstIndex(of: context.origin),
              let di = codes.lastIndex(of: context.destination) else { return false }
        return oi < di
    }

    private var alternates: [Train] {
        bank.trains.values
            .filter { t in
                guard t.number != context.exclude else { return false }
                // must actually reach the destination downstream of its origin
                guard let di = t.stops.map(\.code).lastIndex(of: context.destination),
                      di > 0 else { return false }
                return true
            }
            .sorted { lhs, rhs in
                let ls = servesRoute(lhs), rs = servesRoute(rhs)
                if ls != rs { return ls }
                return parseHM(lhs.departureTime) < parseHM(rhs.departureTime)
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if alternates.isEmpty {
                        emptyState
                    } else {
                        eyebrow("\(alternates.count) TRAINS TO \(cityFor(context.destination, context.destinationName).uppercased())")
                        ForEach(alternates) { t in
                            NavigationLink {
                                TrainAddView(number: t.number, dismissAll: { dismiss() })
                            } label: {
                                row(t)
                            }
                            .buttonStyle(.pressableRow)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Color.white)
            .navigationTitle("Alternate Trains")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func eyebrow(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .bold))
            .kerning(0.8)
            .foregroundStyle(Color.subGray)
            .padding(.top, 20)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ t: Train) -> some View {
        HStack(spacing: 11) {
            TrainMark(category: t.category, size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(t.number)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.subGray)
                    .monospacedDigit()
                Text(t.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.inkline)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(t.departureTime)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkline)
                    .monospacedDigit()
                Text("\(t.origin.code) → \(t.destination.code)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.subGray)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.fadedGray)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hairline).frame(height: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 30))
                .foregroundStyle(Color.fadedGray)
                .padding(.bottom, 4)
            Text("No alternates offline yet")
                .font(.system(size: 16))
                .foregroundStyle(Color.subGray)
            Text("Add or search trains on this route and they'll turn up here — no signal needed.")
                .font(.system(size: 13))
                .foregroundStyle(Color.subGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

/// Where every number on this screen comes from, said plainly.
///
/// The drawn line is real OpenStreetMap track shape only where we've bundled a
/// segment for that leg; everything else is a straight line between halts. The
/// train rides whichever of the two it is, so the note says which.
func sourceNote(for train: Train) -> String {
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
    return "Schedule, platforms & halts: Indian Railways via erail.in.\n"
        + path + "\nLive position and delays are estimated from the timetable."
}
