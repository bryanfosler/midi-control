import SwiftUI

/// A horizontal bat-style toggle switch matching real metal guitar pedal toggles.
/// **Option B visual**: thin metal stem pivots from center hex nut; dome cap at tip.
/// The stem leans ±28° left/right; straight up = center (3-way only).
///
/// Interaction: DragGesture(minimumDistance: 0) on the outer VStack.
/// - onEnded fires for any mouse-down + mouse-up (click or tiny drag).
/// - startLocation.x in .local space maps directly to slot index via x / slotWidth.
struct ToggleSwitch3Way: View {
    let parameter: ParameterDefinition
    let options: [ToggleOption]
    @Binding var value: Int
    let onChange: (Int) -> Void
    let theme: PedalColorTheme
    var pedalId: String = ""
    /// Optional tint color for the dome cap (nil = chrome gradient)
    var batColor: Color? = nil

    @State private var liveIndex: Int = 0

    private func indexFromValue(_ val: Int) -> Int {
        var bestIndex = 0
        var bestDist = Int.max
        for i in 0..<options.count {
            let dist = abs(options[i].value - val)
            if dist < bestDist { bestDist = dist; bestIndex = i }
        }
        return bestIndex
    }

    private func select(index: Int) {
        liveIndex = index
        let newValue = options[index].value
        value = newValue
        onChange(newValue)
    }

    var body: some View {
        VStack(spacing: 3) {
            // ── Option labels above the switch ──
            HStack(spacing: 0) {
                ForEach(0..<options.count, id: \.self) { i in
                    Text(options[i].name)
                        .font(.system(size: 8, weight: liveIndex == i ? .bold : .regular))
                        .foregroundStyle(
                            liveIndex == i
                                ? theme.labelColor
                                : theme.labelColor.opacity(0.40)
                        )
                        .frame(width: slotWidth)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(width: trackWidth)

            // ── Switch housing (visual only) ──
            ZStack {
                // Housing outer shadow
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.black.opacity(0.55))
                    .frame(width: trackWidth + 2, height: trackHeight + 2)
                    .blur(radius: 2)
                    .offset(y: 1.5)

                // Housing body
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(
                        colors: [Color(white: 0.14), Color(white: 0.22)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: trackWidth, height: trackHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color(white: 0.42), Color(white: 0.20)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 0.75
                            )
                    )

                // Inner recess / channel
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black.opacity(0.35))
                    .frame(width: trackWidth - 4, height: trackHeight - 3)

                // Position dividers between slots
                HStack(spacing: 0) {
                    ForEach(0..<(options.count - 1), id: \.self) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color(white: 0.32))
                            .frame(width: 1, height: trackHeight * 0.55)
                    }
                    Spacer()
                }
                .frame(width: trackWidth)

                // Hex mounting nut — the visible pivot point of the bat stem
                HexNut(size: trackHeight - 2)
                    .opacity(0.70)

                // ── Metal bat lever (stem + dome cap) ──
                batView
            }
            .frame(width: trackWidth, height: trackHeight)

            // ── Parameter name ──
            Text(parameter.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(theme.labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: trackWidth)
        }
        .frame(width: trackWidth)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onEnded { gesture in
                    guard abs(gesture.translation.width)  < 10,
                          abs(gesture.translation.height) < 10 else { return }
                    let idx = min(options.count - 1,
                                  max(0, Int(gesture.startLocation.x / slotWidth)))
                    select(index: idx)
                }
        )
        .onAppear { liveIndex = indexFromValue(value) }
        .onChange(of: value) { liveIndex = indexFromValue(value) }
        .help(ParameterDescriptions.description(for: parameter.id, cc: parameter.cc, pedalId: pedalId))
    }

    // MARK: - Bat / Lever (Option B: Stem + Dome)
    //
    // A thin chrome stem extends upward from the hex nut pivot at housing center.
    // A small flat dome cap sits at the tip — the "handle" end of the toggle.
    // Left/Right: stem leans ±28° from vertical. Center (3-way): stem vertical.
    // BatStem conforms to Animatable so tipX/tipY interpolate smoothly via spring.

    private var batView: some View {
        let angleDeg: Double = {
            if options.count == 2 { return liveIndex == 0 ? -28.0 : 28.0 }
            switch liveIndex {
            case 0:  return -28.0
            case 2:  return  28.0
            default: return   0.0
            }
        }()

        let stemLen: CGFloat = 14
        let rad  = angleDeg * .pi / 180
        let tipX = CGFloat(sin(rad)) * stemLen    // ±6.6 at ±28°
        let tipY = -CGFloat(cos(rad)) * stemLen   // −12.4 at tilt, −14 at center

        let domeW: CGFloat = 10
        let domeH: CGFloat =  7

        return ZStack {
            // Stem drop shadow
            BatStem(tipX: tipX + 1.0, tipY: tipY + 1.5)
                .stroke(Color.black.opacity(0.40),
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                .animation(.interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14),
                           value: liveIndex)

            // Chrome stem (gradient runs top-to-bottom of the frame)
            BatStem(tipX: tipX, tipY: tipY)
                .stroke(
                    LinearGradient(
                        colors: [Color(white: 0.90), Color(white: 0.62)],
                        startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .animation(.interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14),
                           value: liveIndex)

            // Dome shadow
            Ellipse()
                .fill(Color.black.opacity(0.40))
                .frame(width: domeW + 2, height: domeH + 2)
                .blur(radius: 1)
                .offset(x: tipX + 1.0, y: tipY + 1.5)
                .animation(.interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14),
                           value: liveIndex)

            // Dome cap
            Ellipse()
                .fill(AnyShapeStyle(batDomeFill()))
                .frame(width: domeW, height: domeH)
                .offset(x: tipX, y: tipY)
                .animation(.interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14),
                           value: liveIndex)

            // Specular highlight on dome
            Ellipse()
                .fill(Color.white.opacity(0.65))
                .frame(width: domeW * 0.45, height: domeH * 0.35)
                .offset(x: tipX, y: tipY - domeH * 0.18)
                .animation(.interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14),
                           value: liveIndex)
        }
    }

    private func batDomeFill() -> some ShapeStyle {
        if let c = batColor {
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: c.opacity(0.98), location: 0.00),
                    .init(color: c.opacity(0.76), location: 0.50),
                    .init(color: c.opacity(0.54), location: 1.00),
                ],
                startPoint: .top, endPoint: .bottom))
        }
        return AnyShapeStyle(LinearGradient(
            stops: [
                .init(color: Color(white: 0.94), location: 0.00),
                .init(color: Color(white: 0.78), location: 0.45),
                .init(color: Color(white: 0.58), location: 1.00),
            ],
            startPoint: .top, endPoint: .bottom))
    }

    // MARK: - Dimensions

    private var slotWidth:  CGFloat { 28 }
    private var trackWidth: CGFloat { slotWidth * CGFloat(options.count) }
    private var trackHeight: CGFloat { 22 }
}

// MARK: - Bat Stem Shape

/// Draws an animatable line from housing center (rect.mid) to the bat tip position.
/// Conforms to Animatable so SwiftUI interpolates tipX/tipY during spring animations,
/// producing a smooth arc sweep rather than a snap when liveIndex changes.
private struct BatStem: Shape {
    var tipX: CGFloat
    var tipY: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(tipX, tipY) }
        set { tipX = newValue.first; tipY = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX + tipX, y: rect.midY + tipY))
        return p
    }
}

// MARK: - Hex Mounting Nut

/// Draws a hexagonal toggle-switch mounting nut using Canvas.
/// Mimics the chrome hex nut visible on real guitar pedal toggle switches.
private struct HexNut: View {
    let size: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width  / 2
            let cy = size.height / 2
            let r  = min(size.width, size.height) / 2 - 0.5

            var hex = Path()
            for i in 0..<6 {
                let angle = Double(i) * (.pi / 3) + .pi / 6
                let pt = CGPoint(x: cx + r * CGFloat(cos(angle)),
                                 y: cy + r * CGFloat(sin(angle)))
                if i == 0 { hex.move(to: pt) } else { hex.addLine(to: pt) }
            }
            hex.closeSubpath()

            ctx.fill(hex, with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(white: 0.82), location: 0.00),
                    .init(color: Color(white: 0.58), location: 0.45),
                    .init(color: Color(white: 0.38), location: 1.00),
                ]),
                startPoint: CGPoint(x: cx - r, y: cy - r),
                endPoint:   CGPoint(x: cx + r, y: cy + r)
            ))

            ctx.stroke(hex, with: .color(Color(white: 0.22)), lineWidth: 0.75)

            let boreR = r * 0.38
            var bore = Path()
            bore.addEllipse(in: CGRect(x: cx - boreR, y: cy - boreR,
                                       width: boreR * 2, height: boreR * 2))
            ctx.fill(bore, with: .color(Color.black.opacity(0.70)))
            ctx.stroke(bore, with: .color(Color(white: 0.40)), lineWidth: 0.5)
        }
        .frame(width: size, height: size)
    }
}
