import SwiftUI
import AppKit

/// A circular draggable knob with 270-degree sweep for CC 0–127 parameters.
///
/// Interactions:
///   • Click + drag up   → increase value (clockwise)
///   • Click + drag down → decrease value (counter-clockwise)
///   • Shift + drag      → fine control (14px per unit)
///   • Click right half  → +10% (≈ 13 units)
///   • Click left half   → −10%
///   • Option + click    → reset to default
///   • Scroll up/down    → adjust value; Shift for fine scroll
struct RotaryKnob: View {
    let parameter: ParameterDefinition
    @Binding var value: Int
    let onChange: (Int) -> Void
    let theme: PedalColorTheme
    var pedalId: String = ""

    private let minAngle: Double = -135
    private let maxAngle: Double =  135

    /// Normal drag: 5px per CC unit (full range = 635px)
    private let pxPerUnit: Double = 5.0
    /// Shift-drag: 14px per unit for fine adjustments
    private let finePxPerUnit: Double = 14.0

    @State private var isDragging = false
    @State private var dragStartValue: Int = 0
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

    // MARK: - Knob Visual + Gestures

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

            // ── Main knob body (3D dome via radial gradient) ──
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
        // Scroll wheel capture is a background NSView with hitTest→nil so it never
        // blocks SwiftUI gestures or tooltip tracking. Scroll is intercepted via
        // addLocalMonitorForEvents before AppKit dispatches to any view.
        .background(
            ScrollWheelCapture(
                tooltip: ParameterDescriptions.description(
                    for: parameter.id, cc: parameter.cc, pedalId: pedalId
                ),
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
        // Combined drag + click gesture.
        // minimumDistance: 0 fires onChanged immediately, so we guard against
        // tiny movements before engaging drag mode. onEnded with tiny total
        // movement = click; uses startLocation.x to pick left vs right half.
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    let moved = abs(gesture.translation.height) > 2
                                 || abs(gesture.translation.width) > 2
                    guard moved else { return }

                    if !isDragging {
                        isDragging = true
                        dragStartValue = value
                    }
                    let sensitivity = NSEvent.modifierFlags.contains(.shift)
                        ? finePxPerUnit : pxPerUnit
                    let delta = -gesture.translation.height / sensitivity
                    let newValue = max(0, min(127, Int(Double(dragStartValue) + delta)))
                    if newValue != value {
                        value = newValue
                        onChange(newValue)
                    }
                }
                .onEnded { gesture in
                    if isDragging {
                        isDragging = false
                        return
                    }
                    // Tap (no significant drag)
                    if NSEvent.modifierFlags.contains(.option) {
                        value = parameter.defaultValue
                        onChange(parameter.defaultValue)
                    } else {
                        // Right half = +10%, Left half = −10%  (knob is 58pt wide)
                        let step = 13  // 127 × 0.10 ≈ 12.7 → 13
                        if gesture.startLocation.x > 29 {
                            let newValue = min(127, value + step)
                            value = newValue; onChange(newValue)
                        } else {
                            let newValue = max(0, value - step)
                            value = newValue; onChange(newValue)
                        }
                    }
                }
        )
    }
}

// MARK: - Scroll Wheel Capture (NSViewRepresentable)

private struct ScrollWheelCapture: NSViewRepresentable {
    let tooltip: String
    let onScroll: (Double) -> Void

    func makeNSView(context: Context) -> ScrollCaptureView {
        ScrollCaptureView()
    }

    func updateNSView(_ nsView: ScrollCaptureView, context: Context) {
        nsView.onScroll = onScroll
        nsView.toolTip = tooltip.isEmpty ? nil : tooltip
    }
}

private class ScrollCaptureView: NSView {
    var onScroll: ((Double) -> Void)?
    private var scrollMonitor: Any?

    override var acceptsFirstResponder: Bool { false }

    /// Returning nil makes this view completely transparent to AppKit hit testing.
    /// SwiftUI gesture recognizers and tooltip tracking areas work unobstructed.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            // Capture scroll events at the window level before AppKit dispatches them.
            // Only consume the event when the cursor is within our bounds.
            scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self, self.window != nil else { return event }
                let locInView = self.convert(event.locationInWindow, from: nil)
                guard self.bounds.contains(locInView) else { return event }
                let delta = Double(event.deltaY)
                if abs(delta) > 0.001 {
                    DispatchQueue.main.async { self.onScroll?(delta) }
                    return nil  // consume — prevents the ScrollView from scrolling
                }
                return event
            }
        } else {
            if let m = scrollMonitor { NSEvent.removeMonitor(m); scrollMonitor = nil }
        }
    }

    deinit {
        if let m = scrollMonitor { NSEvent.removeMonitor(m) }
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
