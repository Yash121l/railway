import MapKit
import SwiftUI

private func toneColor(_ delayMin: Int) -> Color {
    delayMin > 5 ? .lateRed : .onTime
}

/// Route map: flown portion solid, remainder dashed — Flighty's arc treatment.
private struct TripMapView: View {
    let live: LiveStatus

    var body: some View {
        let coords = live.train.stops.map {
            CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng)
        }
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
                MapPolyline(coordinates: Array(coords[0...live.prevStopIdx]) + [pos])
                    .stroke(Color.arcBlue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                MapPolyline(coordinates: [pos] + Array(coords[live.nextStopIdx...]))
                    .stroke(Color.arcBlue.opacity(0.45),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [1, 6]))
            } else {
                MapPolyline(coordinates: coords)
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
                }
            }
            if live.phase == .enroute {
                Annotation("", coordinate: pos) {
                    Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.arcBlue, lineWidth: 3).frame(width: 16, height: 16))
                        .shadow(color: Color.arcBlue, radius: 7)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .colorScheme(.dark)
    }
}

private struct StatusBanner: View {
    let live: LiveStatus
    let now: Date

    var body: some View {
        let late = live.delayMin > 5
        let destCity = cityFor(live.train.destination.code, live.train.destination.name)

        VStack(alignment: .leading, spacing: 3) {
            switch live.phase {
            case .enroute:
                let remaining = max(0, live.arrivesEst.timeIntervalSince(now) / 60)
                headline("Arriving in ", fmtDuration(remaining), late: late)
                detail(late
                    ? "\(live.events.first(where: { $0.kind == .delay })?.text ?? "Running behind schedule") — reaches \(destCity) \(live.delayMin)m late ›"
                    : "Running on time — reaches \(destCity) at \(fmtTime(live.arrivesEst)) ›")
            case .boarding, .scheduled:
                let toDep = max(0, live.stopTimings[0].depEst.timeIntervalSince(now) / 60)
                headline("Departure in ", fmtDuration(toDep), late: late)
                detail(late
                    ? "Railly predicts a \(live.delayMin)m late start — the railway hasn't announced it yet ›"
                    : "Inbound rake is on schedule for a \(fmtTime(live.departsAt)) departure ›")
            case .arrived:
                headline("Arrived ", late ? "\(live.delayMin)m late" : "on time", late: late)
                detail("Reached \(destCity) at \(fmtTime(live.arrivesEst)) ›")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(late ? Color(hex: 0xFBF0EE) : Color(hex: 0xF2F8F4))
    }

    private func headline(_ prefix: String, _ value: String, late: Bool) -> some View {
        (Text(prefix).foregroundStyle(Color.inkline)
            + Text(value).foregroundStyle(late ? Color.lateRed : Color.onTime).fontWeight(.bold))
            .font(.system(size: 18, weight: .semibold))
    }

    private func detail(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 14))
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
                    .foregroundStyle(toneColor(timing.delayMin)).fontWeight(.semibold)
                    + Text(" • \(fmtDay(est))").foregroundStyle(Color.subGray))
                    .font(.system(size: 13))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(stop.platform.map { "PF \($0)" } ?? "PF --")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(Color.gateAmber, in: RoundedRectangle(cornerRadius: 9))
                Text(isDeparture ? "Coach \(trip.coach)" : "Platform")
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
                .stroke(Color(hex: 0xECECEE), lineWidth: 1)
        )
    }
}

struct TripDetailView: View {
    let id: String

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
        .background(Color.white)
    }

    private func detail(trip: HeldTrip, now: Date) -> some View {
        let live = trip.live
        let train = trip.train

        return ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    TripMapView(live: live)
                        .frame(height: 300)
                    if live.phase == .enroute {
                        Text("\(live.speedKmh) KM/H · \(live.delayMin > 5 ? "+\(live.delayMin)M" : "ON TIME")")
                            .font(.system(size: 11, weight: .bold))
                            .kerning(0.8)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .background(Color(hex: 0x1C1E22).opacity(0.9), in: Capsule())
                            .padding(14)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 11) {
                        TrainMark(category: train.category, size: 44)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(train.number) • \(fmtDay(live.departsAt).uppercased())")
                                .font(.system(size: 12, weight: .semibold))
                                .kerning(0.5)
                                .foregroundStyle(Color.subGray)
                            Text("\(cityFor(train.origin.code, train.origin.name)) to \(cityFor(train.destination.code, train.destination.name))")
                                .font(.system(size: 23, weight: .bold))
                                .foregroundStyle(Color.inkline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                    StatusBanner(live: live, now: now)

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
                        .foregroundStyle(Color.fadedGray)
                        EndBlock(trip: trip, isDeparture: false)
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 14) {
                        if live.phase == .enroute {
                            liveRun(live: live, now: now)
                        }
                        if !live.events.isEmpty {
                            updates(live.events)
                        }
                        timetable(live: live)
                        booking(trip)
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
        }
        .background(Color.black)
        .ignoresSafeArea(edges: .top)
    }

    private func liveRun(live: LiveStatus, now: Date) -> some View {
        SectionCard(title: "Live Run",
                    subtitle: "\(Int((live.progress * 100).rounded()))% of \(Int(live.totalKm)) km") {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.fillGray)
                    Capsule().fill(Color.arcBlue)
                        .frame(width: max(6, geo.size.width * live.progress))
                }
            }
            .frame(height: 7)

            let hereIdx = live.atStation ? live.prevStopIdx : live.nextStopIdx
            let hereStop = live.train.stops[hereIdx]
            let hereTiming = live.stopTimings[hereIdx]
            HStack {
                stat("\(Int(live.progressKm)) km", "Covered")
                Spacer()
                stat("\(live.speedKmh) km/h", "Speed")
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
                    .foregroundStyle(toneColor(hereTiming.delayMin))
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
        SectionCard(title: "Updates", subtitle: "\(events.count) updates for this trip") {
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
                        .foregroundStyle(Color.fadedGray)
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
        default: return "smallcircle.filled.circle"
        }
    }

    private func color(for kind: TrainEventKind) -> Color {
        switch kind {
        case .delay: return .lateRed
        case .recovery, .arrived: return .onTime
        case .platform: return Color(hex: 0xB58900)
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
            .foregroundStyle(Color.fadedGray)

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
                        .foregroundStyle(toneColor(t.delayMin))
                        .monospacedDigit()
                        .frame(width: 70, alignment: .trailing)
                }
                .opacity(t.passed && !t.current ? 0.45 : 1)
            }
        }
    }

    private func booking(_ trip: HeldTrip) -> some View {
        SectionCard(title: "My Booking") {
            HStack {
                stat(trip.pnr, "PNR")
                Spacer()
                stat("\(trip.coach) · \(trip.seat)", "Coach · Seat")
            }
        }
    }
}
