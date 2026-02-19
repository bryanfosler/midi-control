import SwiftUI

/// A row of on/off dip switches with semantic labels and theme colors
struct DipSwitchBank: View {
    let parameters: [ParameterDefinition]
    let values: Binding<[Int: Int]>
    let onChange: (ParameterDefinition, Int) -> Void
    var theme: PedalColorTheme? = nil

    var body: some View {
        HStack(spacing: 6) {
            ForEach(parameters) { param in
                DipSwitch(
                    label: param.name,
                    isOn: Binding(
                        get: { (values.wrappedValue[param.cc] ?? 0) > 0 },
                        set: { newValue in
                            let ccValue = newValue ? 127 : 0
                            values.wrappedValue[param.cc] = ccValue
                            onChange(param, ccValue)
                        }
                    ),
                    theme: theme
                )
            }
        }
    }
}

/// A single visual dip switch with optional theme colors
struct DipSwitch: View {
    let label: String
    @Binding var isOn: Bool
    var theme: PedalColorTheme? = nil

    private var onColor: Color {
        theme?.dipOnColor ?? Color.accentColor
    }

    private var offColor: Color {
        theme?.dipOffColor ?? Color.gray.opacity(0.3)
    }

    private var labelColor: Color {
        theme?.labelColor ?? Color.secondary
    }

    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 3)
                .fill(isOn ? onColor : offColor)
                .frame(width: 22, height: 32)
                .overlay(alignment: isOn ? .top : .bottom) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 16, height: 14)
                        .padding(2)
                }
                .onTapGesture {
                    isOn.toggle()
                }
                .animation(.easeInOut(duration: 0.1), value: isOn)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 32)
        }
    }
}
