import SwiftUI

/// First-run welcome, three swipeable pages: what Railly does, the color
/// language, and why the live picture is an honest timetable projection
/// rather than a GPS feed. RaillyApp presents it once, as a sheet.
struct EstimatesIntroView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let lastPage = 2

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") { dismiss() }
                    .font(.dsSubhead)
                    .foregroundStyle(DS.secondary)
                    .opacity(page < lastPage ? 1 : 0)
                    .disabled(page == lastPage)
            }
            .frame(height: 44)
            .padding(.horizontal, DS.gutter)

            TabView(selection: $page) {
                WelcomePage().tag(0)
                ColorsPage().tag(1)
                HonestPage().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PageDots(count: lastPage + 1, current: page)
                .padding(.vertical, 18)

            DSButton(title: page == lastPage ? "Start Tracking" : "Continue") {
                if page < lastPage {
                    withAnimation(.snappy(duration: 0.35)) { page += 1 }
                } else {
                    dismiss()
                }
            }
            .padding(.horizontal, DS.gutter)
            .padding(.bottom, 12)
        }
        .background(DS.sheet)
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? DS.ink : DS.fill2)
                    .frame(width: i == current ? 20 : 7, height: 7)
            }
        }
        .animation(.snappy(duration: 0.3), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}

/// Shared page scaffold: an illustration, then title and body.
private struct IntroPage<Art: View, Extra: View>: View {
    let eyebrow: String
    let title: String
    let text: String
    @ViewBuilder let art: Art
    @ViewBuilder let extra: Extra

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                art
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 26)
                Text(eyebrow).eyebrow(DS.action)
                Text(title)
                    .font(.dsLargeTitle)
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
                Text(text)
                    .font(.dsBody)
                    .foregroundStyle(DS.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                extra
                    .padding(.top, 20)
            }
            .padding(.horizontal, DS.gutter)
            .padding(.bottom, 12)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Page 1: what Railly does

/// A night globe with a route arcing across it and a mini sheet beneath:
/// the whole app in one picture.
private struct GlobeArt: View {
    @State private var drawn = false
    @State private var pulse = false

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Livery.nightTop, Livery.nightBottom],
                                     startPoint: .top, endPoint: .bottom))

            GeometryReader { geo in
                let w = geo.size.width
                let d = w * 0.78
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Livery.globeLit, Livery.globeShade],
                                             center: UnitPoint(x: 0.35, y: 0.3),
                                             startRadius: 4, endRadius: d * 0.6))
                        .overlay(Circle().stroke(DS.route.opacity(0.35), lineWidth: 1.5))
                        .frame(width: d, height: d)
                        .position(x: w / 2, y: d * 0.62)
                    ArcShape()
                        .trim(from: 0, to: drawn ? 1 : 0)
                        .stroke(DS.onTime, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: w, height: d)
                    Circle()
                        .fill(DS.onTime.opacity(0.3))
                        .frame(width: pulse ? 34 : 16, height: pulse ? 34 : 16)
                        .position(ArcShape.point(in: CGSize(width: w, height: d), t: 0.62))
                        .opacity(drawn ? 1 : 0)
                    Circle()
                        .fill(.white)
                        .frame(width: 13, height: 13)
                        .overlay(Circle().fill(DS.onTime).frame(width: 8, height: 8))
                        .position(ArcShape.point(in: CGSize(width: w, height: d), t: 0.62))
                        .opacity(drawn ? 1 : 0)
                }
            }

            MiniSheet()
                .padding(.horizontal, 22)
        }
        .frame(height: 290)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).delay(0.2)) { drawn = true }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(1.4)) { pulse = true }
        }
    }
}

private struct ArcShape: Shape {
    static func point(in size: CGSize, t: CGFloat) -> CGPoint {
        let p0 = CGPoint(x: size.width * 0.2, y: size.height * 0.62)
        let c = CGPoint(x: size.width * 0.5, y: size.height * 0.05)
        let p1 = CGPoint(x: size.width * 0.8, y: size.height * 0.46)
        let u = 1 - t
        return CGPoint(x: u * u * p0.x + 2 * u * t * c.x + t * t * p1.x,
                       y: u * u * p0.y + 2 * u * t * c.y + t * t * p1.y)
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.62))
        p.addQuadCurve(to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.46),
                       control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.05))
        return p
    }
}

/// Placeholder bars in the shape of a trip row, so the picture explains the
/// layout without inventing a journey.
private struct MiniSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Capsule().fill(DS.fill2).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
            HStack(spacing: 10) {
                Circle().fill(DS.fill).frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 6) {
                    Capsule().fill(DS.ink.opacity(0.85)).frame(width: 128, height: 9)
                    HStack(spacing: 6) {
                        EndpointGlyph(departing: true, tone: .onTime, size: 13)
                        Capsule().fill(DS.onTime).frame(width: 40, height: 7)
                        Spacer()
                        EndpointGlyph(departing: false, tone: .onTime, size: 13)
                        Capsule().fill(DS.onTime).frame(width: 40, height: 7)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(DS.sheet, in: UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20, style: .continuous))
    }
}

private struct WelcomePage: View {
    var body: some View {
        IntroPage(
            eyebrow: "Welcome to Railly",
            title: "Your train, on the globe",
            text: "Add a train number or PNR and Railly follows the run on a satellite globe: countdown, platform, delays and your coach, all in one sheet.",
            art: { GlobeArt() },
            extra: {
                VStack(alignment: .leading, spacing: 14) {
                    feature("tram.fill", "Every Indian Railways train", "Real timetables, run days and platforms.")
                    feature("person.text.rectangle.fill", "A Passport that fills itself", "Every completed trip adds track kilometres and rail time.")
                    feature("lock.fill", "Yours, on this device", "No account. Your trips are stored only on this device.")
                }
            })
    }

    private func feature(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.action)
                .frame(width: 34, height: 34)
                .background(DS.action.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.dsHeadline).foregroundStyle(DS.ink)
                Text(detail).font(.dsFootnote).foregroundStyle(DS.secondary)
            }
        }
    }
}

// MARK: - Page 2: the color language

private struct ColorsPage: View {
    var body: some View {
        IntroPage(
            eyebrow: "The color language",
            title: "One color per journey",
            text: "A trip wears a single status color from origin to destination, so you can read it from across the platform.",
            art: { EmptyView() },
            extra: {
                VStack(spacing: 0) {
                    legend(title: "Green is on time",
                           detail: "Within five minutes of the timetable.") {
                        EndpointGlyph(departing: true, tone: .onTime, size: 30)
                    }
                    divider
                    legend(title: "Red is running late",
                           detail: "More than five minutes behind, start to finish.") {
                        EndpointGlyph(departing: false, tone: .late, size: 30)
                    }
                    divider
                    legend(title: "Gray is still a day out",
                           detail: "Far-off trips stay neutral until the run is close.") {
                        EndpointGlyph(departing: true, tone: .scheduled, size: 30)
                    }
                    divider
                    legend(title: "Amber is your platform",
                           detail: "The one number you scan for at the station.") {
                        PlatformBadge(platform: nil, size: 0.8)
                    }
                    divider
                    legend(title: "Blue is the one thing to tap",
                           detail: "Each screen has a single primary action.") {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(DS.action, in: Circle())
                    }
                }
                .dsCard(padding: 0)
            })
        .padding(.top, 8)
    }

    private var divider: some View {
        Rectangle().fill(DS.separator).frame(height: 1).padding(.leading, 76)
    }

    private func legend<Swatch: View>(title: String, detail: String,
                                      @ViewBuilder swatch: () -> Swatch) -> some View {
        HStack(spacing: 14) {
            swatch()
                .frame(width: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.dsHeadline).foregroundStyle(DS.ink)
                Text(detail).font(.dsFootnote).foregroundStyle(DS.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Page 3: estimates, honestly

private struct HonestPage: View {
    var body: some View {
        IntroPage(
            eyebrow: "Estimates, honestly",
            title: "Projected, and always labeled",
            text: "India has no public live-position feed. Railly reads the same timetable the station boards do and projects where each train should be along its real track, right now.",
            art: {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(DS.action)
                    .frame(width: 72, height: 72)
                    .background(DS.action.opacity(0.1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            },
            extra: {
                VStack(alignment: .leading, spacing: 12) {
                    point(title: "Anything projected wears this tag",
                          detail: "Positions, speeds and delay forecasts. Timetables and platforms come from the real feed.") {
                        EstimateTag()
                    }
                    point(title: "Real data takes over when you have it",
                          detail: "Add an indianrailapi.com key in Settings → Live Data and live positions and delays replace the projection, with the source shown.") {
                        DSChip(text: "Live", color: DS.onTime, filled: true)
                    }
                }
            })
    }

    private func point<Tag: View>(title: String, detail: String,
                                  @ViewBuilder tag: () -> Tag) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            tag()
            Text(title).font(.dsHeadline).foregroundStyle(DS.ink)
            Text(detail)
                .font(.dsFootnote)
                .foregroundStyle(DS.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsWell(radius: DS.cardRadius)
    }
}
