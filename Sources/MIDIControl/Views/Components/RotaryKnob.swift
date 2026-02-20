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
        .frame(width: 68)
    }

    // MARK: - Knob Visual

    @ViewBuilder
    private var knobBody: some View {
        ZStack {
            // ── Ring track (full 270° arc) ──
            ArcShape(startAngle: minAngle, endAngle: maxAngle)
                .stroke(Color.white.opacity(0.07), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .frame(width: 54, height: 54)

            // ── Active arc (min → current value) ──
            ArcShape(startAngle: minAngle, endAngle: rotation)
                .stroke(theme.dipOnColor, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .frame(width: 54, height: 54)

            // ── Knob cast shadow ──
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 42, height: 42)
                .blur(radius: 3)
                .offset(y: 2.5)

            // ── Outer bevel ring ──
            Circle()
                .fill(LinearGradient(
                    colors: [Color(white: 0.42), Color(white: 0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 42, height: 42)

            // ── Grip tick marks (10 marks, 270° span) ──
            ForEach(0..<10, id: \.self) { i in
                let angle = -135.0 + Double(i) * (270.0 / 9.0)
                Capsule()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 1.5, height: 5)
                    .offset(y: -17)
                    .rotationEffect(.degrees(angle))
            }

            // ── Main knob body (3D dome) ──
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color.white.opacity(0.30),
                        theme.knobColor,
                        theme.knobColor.opacity(0.75),
                    ],
                    center: UnitPoint(x: 0.34, y: 0.30),
                    startRadius: 0, endRadius: 19
                ))
                .frame(width: 37, height: 37)

            // ── Specular highlight ──
            Ellipse()
                .fill(Color.white.opacity(0.18))
                .frame(width: 13, height: 9)
                .offset(x: -8, y: -10)
                .blur(radius: 2.5)

            // ── Indicator line ──
            RoundedRectangle(cornerRadius: 1.5)
                .fill(overrideIndicatorColor ?? theme.knobIndicatorColor)
                .frame(width: 2.5, height: 10)
                .offset(y: -13)
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: 58, height: 58)
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
