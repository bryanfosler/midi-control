import SwiftUI

/// Segmented waveform selector for the Ramping Waveform parameter (CC 25).
/// Displays 5 clickable cells, each with a Canvas-drawn waveform icon + label.
/// Maps between CC value ranges and the 5 waveform shapes per the MOOD MKII manual.
struct WaveformPickerView: View {
    let parameter: ParameterDefinition
    @Binding var value: Int
    let onChange: (Int) -> Void

    struct WaveformOption: Identifiable {
        let id: Int           // index 0–4
        let label: String
        let centerValue: Int  // value sent to pedal (center of each range)
        let range: ClosedRange<Int>
    }

    private let options: [WaveformOption] = [
        WaveformOption(id: 0, label: "Sine",     centerValue: 7,   range: 0...14),
        WaveformOption(id: 1, label: "Triangle", centerValue: 34,  range: 15...54),
        WaveformOption(id: 2, label: "Ramp",     centerValue: 67,  range: 55...80),
        WaveformOption(id: 3, label: "Square",   centerValue: 103, range: 81...126),
        WaveformOption(id: 4, label: "Random",   centerValue: 127, range: 127...127),
    ]

    private var selectedId: Int {
        for opt in options {
            if opt.range.contains(value) { return opt.id }
        }
        return 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(parameter.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("CC\(parameter.cc)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            HStack(spacing: 4) {
                ForEach(options) { option in
                    WaveformCell(
                        option: option,
                        isSelected: selectedId == option.id,
                        onTap: {
                            value = option.centerValue
                            onChange(option.centerValue)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Cell

private struct WaveformCell: View {
    let option: WaveformPickerView.WaveformOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                WaveformShape(index: option.id, isSelected: isSelected)
                    .frame(height: 20)
                Text(option.label)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(
                        isSelected ? Color.accentColor.opacity(0.7) : Color.secondary.opacity(0.25),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Waveform drawings

private struct WaveformShape: View {
    let index: Int
    let isSelected: Bool

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let color: Color = isSelected ? .accentColor : .secondary
            let style = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)

            switch index {
            case 0: // Sine — smooth 2-cycle sine wave
                var path = Path()
                let steps = 60
                for i in 0...steps {
                    let t = Double(i) / Double(steps)
                    let x = CGFloat(t) * w
                    let y = h * 0.5 - CGFloat(sin(t * 4 * .pi)) * h * 0.42
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                ctx.stroke(path, with: .color(color), style: style)

            case 1: // Triangle — /\/\
                var path = Path()
                path.move(to: CGPoint(x: 0,        y: h * 0.85))
                path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.15))
                path.addLine(to: CGPoint(x: w * 0.5,  y: h * 0.85))
                path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.15))
                path.addLine(to: CGPoint(x: w,        y: h * 0.85))
                ctx.stroke(path, with: .color(color), style: style)

            case 2: // Ramp — sawtooth up /|/|
                var path = Path()
                // First cycle
                path.move(to: CGPoint(x: 0,        y: h * 0.85))
                path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.15))
                path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.85))
                // Second cycle
                path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.15))
                path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.85))
                ctx.stroke(path, with: .color(color), style: style)

            case 3: // Square — ⊓⊓ two cycles, 50% duty
                var path = Path()
                let d = w * 0.25
                path.move(to:    CGPoint(x: 0,     y: h * 0.85))
                path.addLine(to: CGPoint(x: 0,     y: h * 0.15))
                path.addLine(to: CGPoint(x: d,     y: h * 0.15))
                path.addLine(to: CGPoint(x: d,     y: h * 0.85))
                path.addLine(to: CGPoint(x: d * 2, y: h * 0.85))
                path.addLine(to: CGPoint(x: d * 2, y: h * 0.15))
                path.addLine(to: CGPoint(x: d * 3, y: h * 0.15))
                path.addLine(to: CGPoint(x: d * 3, y: h * 0.85))
                path.addLine(to: CGPoint(x: d * 4, y: h * 0.85))
                ctx.stroke(path, with: .color(color), style: style)

            case 4: // Random — irregular staircase steps
                let ys: [CGFloat] = [0.6, 0.2, 0.78, 0.38, 0.82, 0.28, 0.55, 0.15, 0.65]
                let xStep = w / CGFloat(ys.count - 1)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: h * ys[0]))
                for i in 1..<ys.count {
                    let xNext = CGFloat(i) * xStep
                    path.addLine(to: CGPoint(x: xNext, y: h * ys[i - 1])) // horizontal hold
                    path.addLine(to: CGPoint(x: xNext, y: h * ys[i]))      // vertical jump
                }
                ctx.stroke(path, with: .color(color), style: style)

            default: break
            }
        }
    }
}
