import SwiftUI
import AppKit

/// A circular draggable knob with 270-degree sweep for CC 0–127 parameters.
/// Drag up to increase, down to decrease. Hold Shift for fine control.
/// Scroll wheel adjusts value. Option-click to reset to default.
struct RotaryKnob: View {
    let parameter: ParameterDefinition
    @Binding var value: Int
    let onChange: (Int) -> Void
    let theme: PedalColorTheme
    var pedalId: String = ""

    private let minAngle: Double = -135
    private let maxAngle: Double = 135

    /// Higher = slower/more precise dragging. 5px per unit ≈ 635px for full sweep.
    private let pxPerUnit: Double = 5.0
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

    // MARK: - Knob Visual

    @ViewBuilder
    private var knobBody: some View {
        ZStack {
            // Scroll wheel capture (transparent overlay)
            ScrollWheelHandler { delta in
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
            .frame(width: 58, height: 58)

            // ── Ring track (full 270° arc, subtle) ──
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
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.42), Color(white: 0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.30),   // bright highlight upper-left
                            theme.knobColor,              // mid-tone body
                            theme.knobColor.opacity(0.75), // darker edge
                        ],
                        center: UnitPoint(x: 0.34, y: 0.30),
                        startRadius: 0,
                        endRadius: 19
                    )
                )
                .frame(width: 37, height: 37)

            // ── Specular highlight (lens effect top-left) ──
            Ellipse()
                .fill(Color.white.opacity(0.18))
                .frame(width: 13, height: 9)
                .offset(x: -8, y: -10)
                .blur(radius: 2.5)

            // ── Indicator ──
            RoundedRectangle(cornerRadius: 1.5)
                .fill(theme.knobIndicatorColor)
                .frame(width: 2.5, height: 10)
                .offset(y: -13)
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: 58, height: 58)
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { gesture in
                    if !isDragging {
                        isDragging = true
                        dragStartValue = value
                    }
                    let sensitivity = NSEvent.modifierFlags.contains(.shift) ? finePxPerUnit : pxPerUnit
                    let delta = -gesture.translation.height / sensitivity
                    let newValue = max(0, min(127, Int(Double(dragStartValue) + delta)))
                    if newValue != value {
                        value = newValue
                        onChange(newValue)
                    }
                }
                .onEnded { _ in isDragging = false }
        )
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.option) {
                value = parameter.defaultValue
                onChange(parameter.defaultValue)
            }
        }
    }
}

// MARK: - Scroll Wheel Handler

private struct ScrollWheelHandler: NSViewRepresentable {
    let onScroll: (Double) -> Void

    func makeNSView(context: Context) -> ScrollCaptureView {
        let view = ScrollCaptureView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: ScrollCaptureView, context: Context) {
        nsView.onScroll = onScroll
    }
}

private class ScrollCaptureView: NSView {
    var onScroll: ((Double) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        let delta = Double(event.deltaY)
        if abs(delta) > 0.001 {
            onScroll?(delta)
        }
    }
}

// MARK: - Arc Shape

private struct ArcShape: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle - 90),
            endAngle: .degrees(endAngle - 90),
            clockwise: false
        )
        return path
    }
}
