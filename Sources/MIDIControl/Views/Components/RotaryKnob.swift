import SwiftUI
import AppKit

/// A circular draggable knob with 270-degree sweep for CC 0-127 parameters.
/// Drag up to increase, down to decrease. Hold Shift for fine control.
/// Scroll wheel also adjusts value. Option-click to reset to default value.
struct RotaryKnob: View {
    let parameter: ParameterDefinition
    @Binding var value: Int
    let onChange: (Int) -> Void
    let theme: PedalColorTheme

    /// Degrees of rotation for min (0) and max (127)
    private let minAngle: Double = -135
    private let maxAngle: Double = 135

    /// How many pixels of drag per 1 CC unit
    private let pxPerUnit: Double = 2.5
    private let finePxPerUnit: Double = 8.0

    @State private var isDragging = false
    @State private var dragStartValue: Int = 0

    private var rotation: Double {
        let fraction = Double(value) / 127.0
        return minAngle + fraction * (maxAngle - minAngle)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Knob
            ZStack {
                // Scroll wheel capture (transparent, sits behind visual layers)
                ScrollWheelHandler { delta in
                    let sensitivity = NSEvent.modifierFlags.contains(.shift) ? 0.5 : 2.0
                    let newValue = max(0, min(127, Int(Double(value) + delta * sensitivity)))
                    if newValue != value {
                        value = newValue
                        onChange(newValue)
                    }
                }
                .frame(width: 52, height: 52)

                // Outer ring / track
                Circle()
                    .stroke(theme.knobColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 48, height: 48)

                // Active arc
                ArcShape(startAngle: minAngle, endAngle: rotation)
                    .stroke(theme.dipOnColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)

                // Knob body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.knobColor.opacity(0.8), theme.knobColor],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

                // Indicator line
                Rectangle()
                    .fill(theme.knobIndicatorColor)
                    .frame(width: 2, height: 12)
                    .offset(y: -11)
                    .rotationEffect(.degrees(rotation))
            }
            .frame(width: 52, height: 52)
            .contentShape(Circle().size(width: 52, height: 52))
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
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onTapGesture {
                if NSEvent.modifierFlags.contains(.option) {
                    value = parameter.defaultValue
                    onChange(parameter.defaultValue)
                }
            }

            // Label
            Text(parameter.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 64)
    }
}

// MARK: - Scroll Wheel Handler

/// Transparent NSView overlay that captures scroll wheel events and forwards them as a delta.
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
        // deltaY > 0 when scrolling up (increase value), < 0 when scrolling down
        let delta = Double(event.deltaY)
        if abs(delta) > 0.001 {
            onScroll?(delta)
        }
    }
}

/// Arc shape for the knob track indicator
private struct ArcShape: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        // Convert from "rotation degrees" (0 = up) to standard angles (0 = right)
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
