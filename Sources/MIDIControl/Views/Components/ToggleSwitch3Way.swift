import SwiftUI

/// A horizontal bat-style toggle switch matching real metal guitar pedal toggles.
/// Options are arranged left-to-right; the bat lever slides between positions.
/// Labels appear above each slot.
///
/// Interaction: DragGesture(minimumDistance: 0) on the outer VStack.
/// - onEnded fires for any mouse-down + mouse-up (click or tiny drag).
/// - startLocation.x in .local space maps directly to slot index via x / slotWidth.
/// - .frame(width: trackWidth) constrains the VStack so the local coordinate
///   space is exactly 0 … trackWidth, making the slot calculation reliable.
struct ToggleSwitch3Way: View {
    let parameter: ParameterDefinition
    let options: [ToggleOption]
    @Binding var value: Int
    let onChange: (Int) -> Void
    let theme: PedalColorTheme
    var pedalId: String = ""
    /// Optional tint color for the bat lever (e.g. red for Ch2, gold for Ch1)
    var batColor: Color? = nil

    // liveIndex drives the bat position immediately on click via @State re-render.
    // Without this, PedalState (a class) mutations don't propagate to viewModel's
    // objectWillChange, so the parent view doesn't re-render and the bat stays frozen.
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
        liveIndex = index                    // immediate visual update via @State
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

                // Hex mounting nut detail — visible at center of mechanism
                HexNut(size: trackHeight - 2)
                    .opacity(0.55)

                // ── Metal bat lever ──
                batView
                    .offset(x: batOffset)
                    .animation(
                        .interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14),
                        value: liveIndex
                    )
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
        // Constrain width so .local coordinate space is exactly 0…trackWidth
        .frame(width: trackWidth)
        .contentShape(Rectangle())
        // DragGesture(minimumDistance:0) fires on any mouse-down + mouse-up.
        // onEnded gives startLocation in .local space → reliable slot calculation.
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onEnded { gesture in
                    // Ignore if the user actually dragged (not a tap)
                    guard abs(gesture.translation.width)  < 10,
                          abs(gesture.translation.height) < 10 else { return }
                    let idx = min(options.count - 1,
                                  max(0, Int(gesture.startLocation.x / slotWidth)))
                    select(index: idx)
                }
        )
        // Sync liveIndex from binding when value changes externally (e.g. preset load)
        .onAppear { liveIndex = indexFromValue(value) }
        .onChange(of: value) { liveIndex = indexFromValue(value) }
        .help(ParameterDescriptions.description(for: parameter.id, cc: parameter.cc, pedalId: pedalId))
    }

    // MARK: - Bat / Lever
    //
    // The bat simulates a real 3D toggle:
    //   Center position → top-down view of the dome → circle
    //   Left  position  → dome tilted left  → portrait oval rotated -22°
    //   Right position  → dome tilted right → portrait oval rotated +22°

    private var batView: some View {
        // Center = circle viewed from straight above.
        // Left/Right = bat tilts along its pivot axis — from above this looks like
        // a vertical (portrait) oval that shifts horizontally toward the selected side.
        // NO rotation: the oval stays upright (90°) at all times.
        let isCenter  = options.count == 3 && liveIndex == 1
        let batDiameter: CGFloat = trackHeight - 4

        // Tilted bat: narrower width (we see less of the dome face),
        // taller height (the rod length becomes apparent from above).
        let ovalW: CGFloat = batDiameter * (isCenter ? 1.0 : 0.58)
        let ovalH: CGFloat = batDiameter * (isCenter ? 1.0 : 1.55)

        // Horizontal displacement: the top of the bat leans toward the selected side.
        let xShift: CGFloat = {
            let d: CGFloat = slotWidth * 0.22
            if options.count == 2 { return liveIndex == 0 ? -d : d }
            switch liveIndex {
            case 0:  return -d
            case 2:  return  d
            default: return  0
            }
        }()

        // Fill — either the provided tint or default chrome
        let fill = AnyShapeStyle(batFill(ovalH: ovalH))

        return ZStack {
            // Drop shadow
            Ellipse()
                .fill(Color.black.opacity(0.50))
                .frame(width: ovalW + 2, height: ovalH + 2)
                .blur(radius: 1.5)
                .offset(x: xShift, y: 1.5)

            // Bat body — portrait oval, shifted left/right (no rotation)
            Ellipse()
                .fill(fill)
                .frame(width: ovalW, height: ovalH)
                .offset(x: xShift)

            // Specular highlight near the top of the dome
            Ellipse()
                .fill(Color.white.opacity(isCenter ? 0.72 : 0.55))
                .frame(width: ovalW * 0.50, height: ovalW * 0.28)
                .offset(x: xShift, y: -(ovalH * 0.26))
        }
        .animation(.interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14), value: liveIndex)
    }

    private func batFill(ovalH: CGFloat) -> some ShapeStyle {
        if let c = batColor {
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: c.opacity(0.98), location: 0.00),
                    .init(color: c.opacity(0.76), location: 0.50),
                    .init(color: c.opacity(0.54), location: 1.00),
                ],
                startPoint: .top, endPoint: .bottom
            ))
        }
        return AnyShapeStyle(LinearGradient(
            stops: [
                .init(color: Color(white: 0.94), location: 0.00),
                .init(color: Color(white: 0.78), location: 0.45),
                .init(color: Color(white: 0.58), location: 1.00),
            ],
            startPoint: .top, endPoint: .bottom
        ))
    }

    // MARK: - Dimensions

    private var slotWidth:   CGFloat { 28 }
    private var trackWidth:  CGFloat { slotWidth * CGFloat(options.count) }
    private var trackHeight: CGFloat { 22 }

    private var batOffset: CGFloat {
        let trackCenter = trackWidth / 2
        let slotCenter  = slotWidth * (CGFloat(liveIndex) + 0.5)
        return slotCenter - trackCenter
    }
}

// MARK: - Hex Mounting Nut

/// Draws a hexagonal toggle-switch mounting nut using Canvas.
/// Mimics the chrome hex nut visible on real guitar pedal toggle switches.
private struct HexNut: View {
    let size: CGFloat  // overall bounding box (square)

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width  / 2
            let cy = size.height / 2
            let r  = min(size.width, size.height) / 2 - 0.5

            // Build hexagon path (flat-top orientation)
            var hex = Path()
            for i in 0..<6 {
                let angle = Double(i) * (.pi / 3) + .pi / 6
                let pt = CGPoint(x: cx + r * CGFloat(cos(angle)),
                                 y: cy + r * CGFloat(sin(angle)))
                if i == 0 { hex.move(to: pt) } else { hex.addLine(to: pt) }
            }
            hex.closeSubpath()

            // Chrome gradient fill
            ctx.fill(hex, with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(white: 0.82), location: 0.00),
                    .init(color: Color(white: 0.58), location: 0.45),
                    .init(color: Color(white: 0.38), location: 1.00),
                ]),
                startPoint: CGPoint(x: cx - r, y: cy - r),
                endPoint:   CGPoint(x: cx + r, y: cy + r)
            ))

            // Dark stroke for edge definition
            ctx.stroke(hex, with: .color(Color(white: 0.22)), lineWidth: 0.75)

            // Inner circle (center bore hole)
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
