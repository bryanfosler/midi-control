import SwiftUI
import AppKit

/// A circular rotary knob with 270-degree sweep for CC 0–127 parameters.
///
/// Interactions (all handled in AppKit for reliable macOS event routing):
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

    private let minAngle: Double = -135
    private let maxAngle: Double =  135

    @State private var scrollAccumulator: Double = 0

    private var rotation: Double {
        let fraction = Double(value) / 127.0
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
        .help(ParameterDescriptions.description(for: parameter.id, cc: parameter.cc, pedalId: pedalId))
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
                .fill(theme.knobIndicatorColor)
                .frame(width: 2.5, height: 10)
                .offset(y: -13)
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: 58, height: 58)
        // KnobInteraction is a transparent NSView overlay that handles ALL
        // mouse events directly in AppKit — reliable, real-time, no SwiftUI
        // gesture/event routing issues.
        .overlay(
            KnobInteraction(
                currentValue: value,
                defaultValue: parameter.defaultValue,
                tooltip: ParameterDescriptions.description(
                    for: parameter.id, cc: parameter.cc, pedalId: pedalId
                ),
                onChange: { newValue in
                    value = newValue
                    onChange(newValue)
                },
                onScroll: { delta in
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
        )
    }
}

// MARK: - AppKit Interaction Layer

/// Transparent NSView that sits over the knob visuals and owns all mouse/scroll events.
private struct KnobInteraction: NSViewRepresentable {
    let currentValue: Int
    let defaultValue: Int
    let tooltip: String
    let onChange: (Int) -> Void
    let onScroll: (Double) -> Void

    func makeNSView(context: Context) -> KnobInteractionView {
        KnobInteractionView()
    }

    func updateNSView(_ nsView: KnobInteractionView, context: Context) {
        nsView.currentValue  = currentValue
        nsView.defaultValue  = defaultValue
        nsView.onChange      = onChange
        nsView.onScroll      = onScroll
        nsView.toolTip       = tooltip.isEmpty ? nil : tooltip
    }
}

private class KnobInteractionView: NSView {

    // Set by updateNSView on every SwiftUI render
    var currentValue: Int = 0
    var defaultValue: Int = 0
    var onChange: ((Int) -> Void)?
    var onScroll: ((Double) -> Void)?

    private var dragStartValue: Int  = 0
    private var dragStartY: CGFloat  = 0
    private var isDragging: Bool     = false

    // Knob is 58×58 in SwiftUI points; normal drag = 5pt/unit
    private let pxPerUnit:     Double = 5.0
    private let finePxPerUnit: Double = 14.0

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        dragStartValue = currentValue
        dragStartY     = event.locationInWindow.y
        isDragging     = false
    }

    override func mouseDragged(with event: NSEvent) {
        let deltaFromStart = event.locationInWindow.y - dragStartY

        // Engage drag mode after a 2pt threshold to avoid accidental nudges
        if !isDragging {
            guard abs(deltaFromStart) >= 2 else { return }
            isDragging = true
        }

        // In AppKit, y increases upward → drag up = positive delta = increase (CW)
        let px = event.modifierFlags.contains(.shift) ? finePxPerUnit : pxPerUnit
        let newValue = max(0, min(127, Int(Double(dragStartValue) + deltaFromStart / px)))
        if newValue != currentValue {
            currentValue = newValue
            onChange?(newValue)
        }
    }

    override func mouseUp(with event: NSEvent) {
        defer { isDragging = false }
        guard !isDragging else { return }

        // Single click — no drag occurred
        if event.modifierFlags.contains(.option) {
            // Option+click: reset to default
            currentValue = defaultValue
            onChange?(defaultValue)
        } else {
            // Left half = −10%,  Right half = +10%
            let locInView = convert(event.locationInWindow, from: nil)
            let step = 13   // 127 × 0.10 ≈ 12.7 → 13 units
            let newValue: Int
            if locInView.x > bounds.midX {
                newValue = min(127, currentValue + step)
            } else {
                newValue = max(0, currentValue - step)
            }
            currentValue = newValue
            onChange?(newValue)
        }
    }

    // MARK: - Scroll Wheel

    override func scrollWheel(with event: NSEvent) {
        let delta = Double(event.deltaY)
        if abs(delta) > 0.001 {
            onScroll?(delta)
        } else {
            // Pass unhandled scroll to the next responder (e.g. ScrollView)
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
