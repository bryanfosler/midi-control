import SwiftUI

/// A vertical bat-style toggle switch with 2 or 3 positions, matching physical pedal toggles.
/// Positions are arranged top-to-bottom matching the options array order.
struct ToggleSwitch3Way: View {
    let parameter: ParameterDefinition
    let options: [ToggleOption]
    @Binding var value: Int
    let onChange: (Int) -> Void
    let theme: PedalColorTheme

    private var selectedIndex: Int {
        // Find closest matching option by distance to current value
        var bestIndex = 0
        var bestDist = Int.max
        for i in 0..<options.count {
            let dist = abs(options[i].value - value)
            if dist < bestDist {
                bestDist = dist
                bestIndex = i
            }
        }
        return bestIndex
    }

    var body: some View {
        VStack(spacing: 3) {
            // Option labels on left, switch on right
            HStack(alignment: .center, spacing: 6) {
                // Left labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(0..<options.count, id: \.self) { index in
                        let option = options[index]
                        Text(option.name)
                            .font(.system(size: 9, weight: selectedIndex == index ? .bold : .regular))
                            .foregroundStyle(selectedIndex == index ? theme.labelColor : theme.labelColor.opacity(0.5))
                            .frame(height: switchHeight / CGFloat(options.count))
                    }
                }

                // Switch body
                ZStack(alignment: .top) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.switchColor)
                        .frame(width: 14, height: switchHeight)

                    // Bat / lever
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.75), Color(white: 0.55)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 12, height: batHeight)
                        .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                        .offset(y: batOffset)
                        .animation(.easeInOut(duration: 0.15), value: selectedIndex)
                }
                .frame(width: 14, height: switchHeight)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let fraction = location.y / switchHeight
                    let index = min(options.count - 1, max(0, Int(fraction * CGFloat(options.count))))
                    let newValue = options[index].value
                    if newValue != value {
                        value = newValue
                        onChange(newValue)
                    }
                }
            }

            // Parameter name
            Text(parameter.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(theme.labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var switchHeight: CGFloat {
        CGFloat(options.count) * 14
    }

    private var batHeight: CGFloat { 12 }

    private var batOffset: CGFloat {
        let totalTravel = switchHeight - batHeight
        let fraction = CGFloat(selectedIndex) / CGFloat(max(1, options.count - 1))
        return 1 + fraction * totalTravel
    }
}
