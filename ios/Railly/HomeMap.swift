import MapKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The globe behind the sheet. Unfocused it rests over India with every held
/// route drawn on real track and live trains glowing; focused it flies to one
/// route, splits it at the train, and shows the train's telemetry up top.
///
/// Every train placement goes through `RailRoute`, so the marker always sits on
/// the line that's drawn. Positions and speeds are timetable projections unless
/// a fresh live snapshot exists, and the map says so.
struct HomeMapView: View {
    let trips: [HeldTrip]
    let focused: HeldTrip?
    let now: Date
    let bottomInset: CGFloat
    /// The window's top safe inset, measured by the shell (the map lays out
    /// ignoring the safe area, so it can't read it from its own environment).
    let topInset: CGFloat

    @EnvironmentObject private var router: Router
    @State private var position: MapCameraPosition = .camera(HomeMapView.globeCamera)
    @State private var heading: CLLocationDirection = 0
    @AppStorage("railly.mapSatellite") private var satellite = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let indiaCenter = CLLocationCoordinate2D(latitude: 22.5, longitude: 80.5)
    /// Far enough out that the globe's limb shows around the subcontinent.
    private static let globeDistance: CLLocationDistance = 16_000_000
    private static var globeCamera: MapCamera {
        MapCamera(centerCoordinate: indiaCenter, distance: globeDistance, heading: 0, pitch: 0)
    }
    /// Room under the status bar for the telemetry capsule, so a fitted route
    /// never tucks beneath it.
    private static let chromeClearance: CGFloat = 56
    private static let lineStyle = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
    private static let glowStyle = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)

    var body: some View {
        let top = topInset

        ZStack(alignment: .top) {
            Map(position: $position, interactionModes: [.pan, .zoom, .rotate]) {
                if let focused {
                    focusedContent(focused)
                } else {
                    overviewContent
                }
            }
            .mapStyle(satellite
                ? .imagery(elevation: .realistic)
                : .standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll))
            .mapControls { MapCompass().mapControlVisibility(.hidden) }
            .environment(\.colorScheme, .dark)
            // Map frames its camera inside the safe area: the sheet covers the
            // bottom, the status bar and telemetry the top.
            // constant padding: changing it in the same update as the camera
            // relaid the map out and snapped the fly instead of animating it
            .safeAreaPadding(.top, top + Self.chromeClearance)
            .safeAreaPadding(.bottom, bottomInset)
            .onMapCameraChange { heading = $0.camera.heading }

            LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: top + 72)
                .allowsHitTesting(false)

            chrome
                .padding(.top, top + 6)
                .environment(\.colorScheme, .dark)
        }
        .onAppear { position = target }
        // next runloop turn, so the camera move isn't swallowed by the same
        // transaction that swaps the map's content
        .onChange(of: focused?.id) { DispatchQueue.main.async { fly() } }
        .onChange(of: bottomInset) {
            if !position.positionedByUser { fly() }
        }
    }

    // MARK: Camera

    private var target: MapCameraPosition {
        guard let focused else { return .camera(Self.globeCamera) }
        return .region(fitting(RailRouteCache.route(for: focused.train).coords))
    }

    private func fly() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .easeInOut(duration: 1.5)) {
            position = target
        }
    }

    private func fitting(_ coords: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coords.first else {
            return MKCoordinateRegion(center: Self.indiaCenter,
                                      span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30))
        }
        var minLat = first.latitude, maxLat = first.latitude
        var minLng = first.longitude, maxLng = first.longitude
        for c in coords {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLng = min(minLng, c.longitude); maxLng = max(maxLng, c.longitude)
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                           longitude: (minLng + maxLng) / 2),
            span: MKCoordinateSpan(latitudeDelta: max(1, (maxLat - minLat) * 1.35),
                                   longitudeDelta: max(1, (maxLng - minLng) * 1.35)))
    }

    // MARK: Overview

    private var routeTrains: [Train] {
        var seen = Set<String>()
        return trips.compactMap { seen.insert($0.train.number).inserted ? $0.train : nil }
    }

    private var movingTrips: [HeldTrip] {
        trips.filter { $0.live.phase == .enroute }
    }

    @MapContentBuilder
    private var overviewContent: some MapContent {
        ForEach(routeTrains) { train in
            let coords = RailRouteCache.route(for: train).coords
            MapPolyline(coordinates: coords).stroke(DS.route.opacity(0.22), style: Self.glowStyle)
            MapPolyline(coordinates: coords).stroke(DS.route, style: Self.lineStyle)
        }
        ForEach(movingTrips) { trip in
            Annotation("", coordinate: trainPoint(trip).coordinate) {
                Button {
                    router.focus(trip.id)
                } label: {
                    LiveDot()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Train \(trip.train.number) on rails now")
            }
        }
    }

    // MARK: Focused

    @MapContentBuilder
    private func focusedContent(_ trip: HeldTrip) -> some MapContent {
        let route = RailRouteCache.route(for: trip.train)
        let live = trip.live

        if live.phase == .enroute {
            let travelled = route.travelled(toLeg: live.prevStopIdx, frac: live.legFraction)
            MapPolyline(coordinates: route.remaining(fromLeg: live.prevStopIdx, frac: live.legFraction))
                .stroke(Color.white.opacity(0.6),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [0.5, 6]))
            MapPolyline(coordinates: travelled).stroke(DS.route.opacity(0.35), style: Self.glowStyle)
            MapPolyline(coordinates: travelled).stroke(DS.route, style: Self.lineStyle)
        } else {
            MapPolyline(coordinates: route.coords).stroke(DS.route.opacity(0.35), style: Self.glowStyle)
            MapPolyline(coordinates: route.coords).stroke(DS.route, style: Self.lineStyle)
        }

        ForEach(Array(1..<max(1, route.stopVertex.count - 1)), id: \.self) { i in
            Annotation("", coordinate: route.coords[route.stopVertex[i]]) {
                Circle()
                    .fill(.white)
                    .frame(width: 5, height: 5)
                    .opacity(live.stopTimings[i].passed ? 1 : 0.7)
                    .accessibilityHidden(true)
            }
        }

        Annotation("", coordinate: route.coords[route.stopVertex[0]]) {
            EndpointPin(code: trip.train.origin.code)
        }
        Annotation("", coordinate: route.coords[route.stopVertex[route.stopVertex.count - 1]]) {
            EndpointPin(code: trip.train.destination.code)
        }

        if live.phase == .enroute || live.phase == .boarding {
            let spot = trainPoint(trip)
            Annotation("", coordinate: spot.coordinate) {
                TrainMarker(moving: live.phase == .enroute && !live.atStation,
                            rotation: spot.bearing - heading)
                    .accessibilityLabel("Train \(trip.train.number)"
                        + (isLive(trip) ? "" : ", estimated position"))
            }
        }
    }

    private func trainPoint(_ trip: HeldTrip) -> (coordinate: CLLocationCoordinate2D, bearing: Double) {
        RailRouteCache.route(for: trip.train)
            .point(leg: trip.live.prevStopIdx, frac: trip.live.legFraction)
    }

    private func isLive(_ trip: HeldTrip) -> Bool {
        LiveFeed.shared.isLive(trip.train.number, trip.live.runDate)
    }

    // MARK: Chrome

    private var chrome: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 8) {
                if let focused, focused.live.phase == .enroute {
                    TelemetryCapsule(trip: focused)
                }
                let tags = honestyTags
                if !tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { MapTag(tag: $0) }
                    }
                }
            }
            .padding(.horizontal, 70)
            .frame(maxWidth: .infinity)
            .animation(.snappy, value: focused?.id)

            VStack(spacing: 10) {
                GlassCircleButton(systemImage: satellite ? "map.fill" : "globe.asia.australia.fill",
                                  label: satellite ? "Show map" : "Show satellite") {
                    withAnimation(.easeInOut(duration: 0.3)) { satellite.toggle() }
                }
                if position.positionedByUser {
                    GlassCircleButton(systemImage: "location.fill", label: "Recenter") { fly() }
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 14)
            .animation(.snappy, value: position.positionedByUser)
            .sensoryFeedback(.selection, trigger: satellite)
        }
    }

    /// What the map must admit: projected positions, and a path that is only
    /// straight chords between halts.
    private var honestyTags: [HonestyTag] {
        if let focused {
            var tags: [HonestyTag] = []
            if focused.live.phase == .enroute && !isLive(focused) { tags.append(.estimated) }
            if RailRouteCache.route(for: focused.train).pathIsApproximate { tags.append(.approximateTrack) }
            return tags
        }
        return movingTrips.contains { !isLive($0) } ? [.estimatedPositions] : []
    }
}

// MARK: - Map parts

/// Dark translucent chrome over the globe: Liquid Glass where available.
private struct DarkGlass<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular.tint(.black.opacity(0.3)), in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(.white.opacity(0.14), lineWidth: 0.5))
        }
    }
}

private struct GlassCircleButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .modifier(DarkGlass(shape: Circle()))
        }
        .buttonStyle(DSPressStyle())
        .accessibilityLabel(label)
    }
}

/// "57 KM/H · NEXT RTM": the focused train's telemetry, top center.
private struct TelemetryCapsule: View {
    let trip: HeldTrip

    var body: some View {
        let live = trip.live
        let stops = trip.train.stops
        let next = stops[live.nextStopIdx].code
        HStack(spacing: 12) {
            if live.atStation {
                reading(icon: "pause.circle.fill", label: "AT", value: stops[live.prevStopIdx].code)
            } else {
                let speed = fmtSpeed(live.speedKmh, caps: true).split(separator: " ").map(String.init)
                HStack(spacing: 5) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    (Text(speed.first ?? "").font(.dsCallout.weight(.bold))
                        + Text(speed.count > 1 ? speed[1] : "").font(.dsEyebrow))
                        .monospacedDigit()
                        .rollingNumbers(value: speed.first ?? "")
                }
            }
            Rectangle().fill(.white.opacity(0.22)).frame(width: 1, height: 14)
            reading(icon: "signpost.right.fill", label: "NEXT", value: next)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .modifier(DarkGlass(shape: Capsule()))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(next: next))
    }

    private func reading(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(label).font(.dsEyebrow).foregroundStyle(.white.opacity(0.7))
            Text(value).font(.dsCallout.weight(.bold))
        }
    }

    private func accessibilityText(next: String) -> String {
        let live = trip.live
        let now = live.atStation
            ? "Halted at \(trip.train.stops[live.prevStopIdx].code)"
            : "Speed \(fmtSpeed(live.speedKmh))"
        return "\(now), next stop \(next)"
    }
}

private enum HonestyTag: Hashable {
    case estimated, estimatedPositions, approximateTrack

    var text: String {
        switch self {
        case .estimated: return "Estimated"
        case .estimatedPositions: return "Estimated positions"
        case .approximateTrack: return "Approximate track"
        }
    }

    var symbol: String {
        self == .approximateTrack ? "point.topleft.down.to.point.bottomright.curvepath" : "waveform.path.ecg"
    }

    var spoken: String {
        self == .approximateTrack
            ? "\(text): drawn straight between halts"
            : "\(text): projected from the timetable"
    }
}

/// Small dark-glass label under the telemetry ("Estimated").
private struct MapTag: View {
    let tag: HonestyTag

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: tag.symbol).font(.system(size: 10, weight: .bold))
            Text(tag.text).font(.dsCaption.weight(.semibold))
        }
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 10)
        .frame(height: 26)
        .modifier(DarkGlass(shape: Capsule()))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tag.spoken)
    }
}

/// A soft expanding ring behind live things. Still under Reduce Motion.
private struct PulseRing: View {
    var size: CGFloat
    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .stroke(DS.route, lineWidth: 2)
            .frame(width: size, height: size)
            .scaleEffect(expanded ? 2.4 : 1)
            .opacity(expanded ? 0 : 0.8)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    expanded = true
                }
            }
            .accessibilityHidden(true)
    }
}

/// A live train on the overview globe: white dot, blue ring, soft pulse.
private struct LiveDot: View {
    var body: some View {
        ZStack {
            PulseRing(size: 14)
            Circle()
                .fill(.white)
                .frame(width: 9, height: 9)
                .overlay(Circle().stroke(DS.route, lineWidth: 3).frame(width: 14, height: 14))
                .shadow(color: DS.route.opacity(0.9), radius: 6)
        }
        .frame(width: 32, height: 32)
        .contentShape(Circle())
    }
}

/// The focused train: a white disc with a heading arrow, pulsing while live.
private struct TrainMarker: View {
    let moving: Bool
    let rotation: Double

    var body: some View {
        ZStack {
            PulseRing(size: 30)
            Circle()
                .fill(.white)
                .frame(width: 30, height: 30)
                .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
            Circle()
                .stroke(DS.route, lineWidth: 2.5)
                .frame(width: 30, height: 30)
            if moving {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.route)
                    .rotationEffect(.degrees(rotation))
            } else {
                Image(systemName: "tram.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.route)
            }
        }
    }
}

/// Origin/destination: a ringed dot with its station-code pill beside it. The
/// pill is an overlay so the annotation anchors on the dot, not the pair.
private struct EndpointPin: View {
    let code: String

    var body: some View {
        Circle()
            .fill(DS.route)
            .frame(width: 11, height: 11)
            .overlay(Circle().stroke(.white, lineWidth: 2.5))
            .overlay(alignment: .leading) {
                Text(code)
                    .font(.dsCaption.weight(.bold))
                    .kerning(0.4)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .frame(height: 22)
                    .background(DS.route, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .fixedSize()
                    .offset(x: 17)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Station \(code)")
    }
}
