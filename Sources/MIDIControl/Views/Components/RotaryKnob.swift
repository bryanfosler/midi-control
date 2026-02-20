import SwiftUI
import AppKit

/// A circular rotary knob with 270-degree sweep for CC 0–127 parameters.
///
/// Interactions:
///   • Click + drag UP      → increase value (clockwise)
///   • Click + drag DOWN    → decrease value (counter-clockwise)
///   • Shift + drag         → fine control (14px per unit)
///   • Single click, right half → +10% (~13 units, clockwise)
///   • Single click, left half  → −10% (counter-clockwise)
///   • Option + click       → reset to default value
///   • Scroll up / down     → ±1 unit; Shift for fine (0.15×)
struct RotaryKnob: View {
    let parameter: ParameterDefinition
    @Binding var value: Int
    let onChange: (Int) -> Void
    let theme: PedalColorTheme
    var pedalId: String = ""
    var overrideIndicatorColor: Color? = nil

    private let minAngle: Double = -135
    private let maxAngle: Double =  135

    // liveValue drives the visual during a drag for immediate response.
    // When not dragging, we show the bound `value`.
    @State private var liveValue: Int = 0
    @State private var isDragging: Bool = false
    @State private var dragStartValue: Int = 0
    @State private var dragStartY: CGFloat = 0
    @State private var scrollAccumulator: Double = 0

    // Delta-based drag with velocity acceleration:
    // lastDragY tracks the previous frame's position for per-frame delta calculation.
    // fractionalAccumulator preserves sub-unit motion so slow drags stay smooth.
    @State private var lastDragY: CGFloat = 0
    @State private var fractionalAccumulator: Double = 0

    private var displayValue: Int { isDragging ? liveValue : value }

    private var rotation: Double {
        let fraction = Double(displayValue) / 127.0
        return minAngle + fraction * (maxAngle - minAngle)
    }

    var body: some View {
        VStack(spacing: 4) {
            knobBody
            Text(parameter.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 76)
    }

    // MARK: - Knob Visual
    //
    // Design: raised dome center with an 11pt-wide knurled grip ring around it.
    // The grip ring uses Canvas crosshatch lines for a real diamond-knurl texture.
    // The indicator is recessed — a dark groove shadow with the color line on top.

    @ViewBuilder
    private var knobBody: some View {
        ZStack {
            // ── Arc track (static, 270° range guide) ──
            ArcShape(startAngle: minAngle, endAngle: maxAngle)
                .stroke(Color.white.opacity(0.09), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .frame(width: 66, height: 66)

            // ── Active arc with soft glow ──
            let arcColor = overrideIndicatorColor ?? theme.dipOnColor
            ArcShape(startAngle: minAngle, endAngle: rotation)
                .stroke(arcColor.opacity(0.55), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 66, height: 66)
                .blur(radius: 5)
            ArcShape(startAngle: minAngle, endAngle: rotation)
                .stroke(arcColor, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .frame(width: 66, height: 66)

            // ── Drop shadow (cast below knob) ──
            Circle()
                .fill(Color.black.opacity(0.65))
                .frame(width: 54, height: 54)
                .blur(radius: 7)
                .offset(y: 5)

            // ── Outer grip ring — dark machined aluminum base ──
            Circle()
                .fill(LinearGradient(
                    colors: [Color(white: 0.42), Color(white: 0.10)],
                    startPoint: .init(x: 0.20, y: 0.08),
                    endPoint:   .init(x: 0.80, y: 0.92)
                ))
                .frame(width: 56, height: 56)

            // ── Diamond knurling texture on the grip ring ──
            // Canvas clips to the ring (outerR=28, innerR=18) and draws
            // two sets of diagonal crosshatch lines to simulate knurling.
            KnurlingRing(outerR: 28, innerR: 18, lineSpacing: 2.8, lineOpacity: 0.40)
                .frame(width: 56, height: 56)

            // ── Inner dome rim — lighter edge separating knurl from dome ──
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(white: 0.55), Color(white: 0.20)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
                .frame(width: 42, height: 42)

            // ── Raised dome body — strong 3D shading ──
            Circle()
                .fill(RadialGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.38),            location: 0.00),
                        .init(color: theme.knobColor.opacity(0.90),        location: 0.35),
                        .init(color: theme.knobColor,                      location: 0.65),
                        .init(color: theme.knobColor.opacity(0.60),        location: 1.00),
                    ],
                    center: UnitPoint(x: 0.30, y: 0.26),
                    startRadius: 0, endRadius: 23
                ))
                .frame(width: 40, height: 40)

            // ── Machined lathe rings on dome top ──
            // Fine concentric circles from CNC turning process, clipped to dome shape.
            Canvas { ctx, sz in
                let cx = sz.width / 2
                let cy = sz.height / 2
                var r: CGFloat = 3.0
                while r < sz.width / 2 - 0.5 {
                    var ring = Path()
                    ring.addEllipse(in: CGRect(x: cx - r, y: cy - r,
                                               width: r * 2, height: r * 2))
                    ctx.stroke(ring, with: .color(Color.white.opacity(0.11)), lineWidth: 0.4)
                    r += 2.5
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            // ── Primary specular highlight (soft, upper-left) ──
            Ellipse()
                .fill(Color.white.opacity(0.22))
                .frame(width: 17, height: 11)
                .offset(x: -9, y: -11)
                .blur(radius: 2.5)

            // ── Hot-spot specular (sharp, tight) ──
            Circle()
                .fill(Color.white.opacity(0.60))
                .frame(width: 5, height: 5)
                .offset(x: -11, y: -12)
                .blur(radius: 1.0)

            // ── Recessed indicator groove ──
            // Three layers: shadow groove → indicator fill → highlight edge
            // Combined they read as a line engraved into the dome surface.
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.75))
                    .frame(width: 5.5, height: 17)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(overrideIndicatorColor ?? theme.knobIndicatorColor)
                    .frame(width: 3.5, height: 15)
                Rectangle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 1.0, height: 13)
                    .offset(x: 1.2)
            }
            .offset(y: -21)
            .rotationEffect(.degrees(rotation))
        }
        .frame(width: 70, height: 70)
        // Scroll wheel captured via NSView background (doesn't block SwiftUI gestures)
        .background(
            ScrollWheelCapture { delta in
                let sensitivity = NSEvent.modifierFlags.contains(.shift) ? 0.15 : 1.0
                scrollAccumulator += delta * sensitivity
                let change = Int(scrollAccumulator)
                if change != 0 {
                    scrollAccumulator -= Double(change)
                    let newValue = max(0, min(127, value + change))
                    if newValue != value {
                        value = newValue
                        onChange(newValue)
                    }
                }
            }
        )
        // DragGesture handles drag (knob turning) AND click (tap with no movement)
        .gesture(
            // .local coordinate space: startLocation.x is 0…58 within the knob,
            // so > 29 reliably identifies the right half for the click action.
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { gesture in
                    if !isDragging {
                        dragStartValue = value
                        dragStartY = gesture.startLocation.y
                        lastDragY = gesture.startLocation.y
                        fractionalAccumulator = Double(value)
                        liveValue = value
                        isDragging = true
                    }

                    // Per-frame delta (positive = dragged upward = increase value)
                    let dy = lastDragY - gesture.location.y
                    lastDragY = gesture.location.y

                    // Velocity-based sensitivity:
                    //   Slow drag  (~0 pts/s)   → 0.20 units/px  (= 5px per unit, original feel)
                    //   Fast drag  (500+ pts/s) → 1.00 units/px  (= 5× faster)
                    // Shift held: fixed fine sensitivity, no acceleration.
                    let isFine = NSEvent.modifierFlags.contains(.shift)
                    let sensitivity: Double
                    if isFine {
                        sensitivity = 1.0 / 14.0
                    } else {
                        let speed = abs(gesture.velocity.height)       // pts/sec
                        let accel = min(1.0, speed / 500.0)            // 0 → 1 over 0–500 pts/s
                        sensitivity = 0.20 + accel * 0.80              // 0.20 → 1.00 units/px
                    }

                    fractionalAccumulator += Double(dy) * sensitivity
                    fractionalAccumulator = max(0, min(127, fractionalAccumulator))

                    let newValue = Int(fractionalAccumulator.rounded())
                    if newValue != liveValue {
                        liveValue = newValue
                        value = newValue
                        onChange(newValue)
                    }
                }
                .onEnded { gesture in
                    defer {
                        isDragging = false
                        liveValue = value
                    }

                    // Distinguish click (tiny movement) from drag
                    guard abs(gesture.translation.height) < 3 else { return }

                    if NSEvent.modifierFlags.contains(.option) {
                        value = parameter.defaultValue
                        onChange(parameter.defaultValue)
                    } else {
                        // Snap to the nearest 10% grid point (0%, 10%, 20%…100% of 127).
                        // Right half → next higher snap point; left half → next lower.
                        // Snap points: [0, 13, 25, 38, 51, 64, 76, 89, 102, 114, 127]
                        let snapPoints = (0...10).map { Int((Double($0) / 10.0 * 127.0).rounded()) }
                        let clickedRight = gesture.startLocation.x > 29
                        let newValue: Int
                        if clickedRight {
                            newValue = snapPoints.first(where: { $0 > value }) ?? 127
                        } else {
                            newValue = snapPoints.last(where:  { $0 < value }) ?? 0
                        }
                        if newValue != value {
                            value = newValue
                            onChange(newValue)
                        }
                    }
                }
        )
        // .help() is placed here (on the interactive ZStack) so macOS tooltip
        // detection fires on the same NSView layer that receives mouse events.
        .help(ParameterDescriptions.description(for: parameter.id, cc: parameter.cc, pedalId: pedalId))
    }
}

// MARK: - Scroll Wheel Capture

/// A transparent NSView that captures scroll wheel events and forwards delta to a closure.
/// Used as .background() so it sits below SwiftUI gestures without blocking them.
private struct ScrollWheelCapture: NSViewRepresentable {
    let onScroll: (Double) -> Void

    func makeNSView(context: Context) -> ScrollCaptureView {
        let v = ScrollCaptureView()
        v.onScroll = onScroll
        return v
    }

    func updateNSView(_ nsView: ScrollCaptureView, context: Context) {
        nsView.onScroll = onScroll
    }
}

private class ScrollCaptureView: NSView {
    var onScroll: ((Double) -> Void)?

    override var acceptsFirstResponder: Bool { false }

    // hitTest returning nil means this view is invisible to mouse clicks —
    // SwiftUI's gesture recognizers above us get all mouse events.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func scrollWheel(with event: NSEvent) {
        let delta = Double(event.deltaY)
        if abs(delta) > 0.001 {
            onScroll?(delta)
        } else {
            super.scrollWheel(with: event)
        }
    }
}

// MARK: - Diamond Knurling Ring

/// Draws a diamond crosshatch texture clipped to the ring between outerR and innerR.
/// Two sets of diagonal lines (±45°) create the classic knurling pattern.
private struct KnurlingRing: View {
    let outerR: CGFloat
    let innerR: CGFloat
    let lineSpacing: CGFloat
    let lineOpacity: Double

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width  / 2
            let cy = size.height / 2

            // Clip to the ring area using even-odd fill rule
            var clip = Path()
            clip.addEllipse(in: CGRect(x: cx - outerR, y: cy - outerR,
                                       width: outerR * 2, height: outerR * 2))
            clip.addEllipse(in: CGRect(x: cx - innerR, y: cy - innerR,
                                       width: innerR * 2, height: innerR * 2))
            ctx.clip(to: clip, style: FillStyle(eoFill: true))

            let ext    = outerR + 2
            let shading = GraphicsContext.Shading.color(Color.white.opacity(lineOpacity))

            // +45° lines
            var k: CGFloat = -(ext * 2)
            while k <= ext * 2 {
                var p = Path()
                p.move(to:    CGPoint(x: cx - ext + k, y: cy - ext))
                p.addLine(to: CGPoint(x: cx + ext + k, y: cy + ext))
                ctx.stroke(p, with: shading, lineWidth: 0.65)
                k += lineSpacing
            }

            // −45° lines
            k = -(ext * 2)
            while k <= ext * 2 {
                var p = Path()
                p.move(to:    CGPoint(x: cx + ext - k, y: cy - ext))
                p.addLine(to: CGPoint(x: cx - ext - k, y: cy + ext))
                ctx.stroke(p, with: shading, lineWidth: 0.65)
                k += lineSpacing
            }
        }
    }
}

// MARK: - Arc Shape

private struct ArcShape: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(startAngle - 90),
            endAngle:   .degrees(endAngle   - 90),
            clockwise: false
        )
        return path
    }
}
