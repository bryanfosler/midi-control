import SwiftUI

/// **Option A** — rotating lever / paddle bat switch variant.
///
/// The bat is a single tapered paddle shape (wide dome at tip, narrow at pivot base).
/// It rotates as one unified piece around the hex nut center, like a clock hand.
/// Left = −40°, Center = 0° (3-way only), Right = +40°.
///
/// To A/B compare vs Option B (ToggleSwitch3Way):
///   In PedalEnclosure.swift, change `ToggleSwitch3Way(` → `ToggleSwitch3WayRotating(`
///   Build and run, then revert to whichever you prefer and delete the other file.
///
/// Note: CLAUDE.md flagged rotationEffect on the old oval bat as "looks wrong".
/// This paddle variant uses a custom animatable Shape (not rotationEffect on a View),
/// so the rotation is internal to the path — a different approach worth retrying.
struct ToggleSwitch3WayRotating: View {
    let parameter: ParameterDefinition
    let options: [ToggleOption]
    @Binding var value: Int
    let onChange: (Int) -> Void
    let theme: PedalColorTheme
    var pedalId: String = ""
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
            ZStack {
                // Hex nut — pivot base, mounted directly on pedal face (no housing box)
                HexNutA(size: trackHeight - 2)
                    .opacity(0.60)

                // ── Rotating paddle lever ──
                batView
            }
            .frame(width: trackWidth, height: trackHeight)

            // Option labels below the housing
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

    // MARK: - Bat / Lever (Option A: Rotating Paddle)
    //
    // RotatingPaddle is a custom Shape with Animatable conformance.
    // The path is built upright (pointing straight up from pivot center),
    // then rotated inside the path itself using CGAffineTransform.
    // SwiftUI interpolates `angle` via animatableData on each animation frame,
    // redrawing the path — no rotationEffect modifier needed.

    private var batView: some View {
        let angleDeg: Double = {
            if options.count == 2 { return liveIndex == 0 ? -40.0 : 40.0 }
            switch liveIndex {
            case 0:  return -40.0
            case 2:  return  40.0
            default: return   0.0
            }
        }()

        return ZStack {
            // Drop shadow — offset paddle drawn black + blurred
            RotatingPaddle(angle: angleDeg)
                .fill(Color.black.opacity(0.50))
                .frame(width: trackWidth, height: trackHeight)
                .blur(radius: 1.5)
                .offset(x: 1, y: 1.5)
                .animation(.interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14),
                           value: liveIndex)

            // Paddle body — chrome gradient
            RotatingPaddle(angle: angleDeg)
                .fill(AnyShapeStyle(paddleFill()))
                .frame(width: trackWidth, height: trackHeight)
                .animation(.interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14),
                           value: liveIndex)

            // Edge stroke for shape definition
            RotatingPaddle(angle: angleDeg)
                .stroke(Color(white: 0.30), lineWidth: 0.75)
                .frame(width: trackWidth, height: trackHeight)
                .animation(.interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14),
                           value: liveIndex)
        }
    }

    private func paddleFill() -> some ShapeStyle {
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
                .init(color: Color(white: 0.80), location: 0.40),
                .init(color: Color(white: 0.58), location: 1.00),
            ],
            startPoint: .top, endPoint: .bottom))
    }

    // MARK: - Dimensions

    private var slotWidth:  CGFloat { 28 }
    private var trackWidth: CGFloat { slotWidth * CGFloat(options.count) }
    private var trackHeight: CGFloat { 22 }
}

// MARK: - Rotating Paddle Shape

/// Tapered paddle: wide dome tip, narrow base at pivot.
/// Built upright (pointing up from pivot) then rotated via CGAffineTransform.
/// Animatable: SwiftUI interpolates `angle` between frames for smooth spring motion.
private struct RotatingPaddle: Shape {
    /// Degrees from vertical. Positive = leans right, negative = leans left.
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx    = rect.midX
        let cy    = rect.midY   // pivot = hex nut center = housing center

        let paddleH: CGFloat = 16   // total length from pivot to dome top
        let topW:   CGFloat = 12   // dome width (widest point)
        let botW:   CGFloat =  5   // base width at pivot
        let domeR   = topW / 2
        let neckY   = cy - (paddleH - domeR)   // y where dome arc begins

        // Upright paddle path (pointing straight up from pivot)
        var p = Path()
        p.move(to:    CGPoint(x: cx - botW / 2, y: cy))
        p.addLine(to: CGPoint(x: cx - domeR,    y: neckY))
        p.addArc(center:     CGPoint(x: cx, y: neckY),
                 radius:     domeR,
                 startAngle: .degrees(180),
                 endAngle:   .degrees(0),
                 clockwise:  false)
        p.addLine(to: CGPoint(x: cx + botW / 2, y: cy))
        p.closeSubpath()

        // Rotate the entire path around the pivot point (cx, cy)
        let radians = CGFloat(angle * .pi / 180)
        let t = CGAffineTransform(translationX: -cx, y: -cy)
            .concatenating(CGAffineTransform(rotationAngle: radians))
            .concatenating(CGAffineTransform(translationX: cx, y: cy))
        return p.applying(t)
    }
}

// MARK: - Hex Mounting Nut (local copy — same as in ToggleSwitch3Way)

private struct HexNutA: View {
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
