import SwiftUI

/// A row of on/off dip switches with semantic labels, theme colors, and tooltips
struct DipSwitchBank: View {
    let parameters: [ParameterDefinition]
    let values: Binding<[Int: Int]>
    let onChange: (ParameterDefinition, Int) -> Void
    var theme: PedalColorTheme? = nil
    var pedalId: String = ""

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
                    theme: theme,
                    parameter: param,
                    pedalId: pedalId
                )
            }
        }
    }
}

/// A single visual dip switch with 3D housing, sliding tab, and tooltip
struct DipSwitch: View {
    let label: String
    @Binding var isOn: Bool
    var theme: PedalColorTheme? = nil
    var parameter: ParameterDefinition? = nil
    var pedalId: String = ""

    private var onColor: Color  { theme?.dipOnColor  ?? Color.accentColor }
    private var labelColor: Color { theme?.labelColor ?? Color.secondary }

    var body: some View {
        VStack(spacing: 2) {
            switchBody
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: 34)
                    .shadow(color: .black.opacity(0.55), radius: 1, x: 0, y: 0.5)
            }
        }
    }

    // Pedal-tinted housing color: blend the theme background toward dark for contrast
    private var housingTop:    Color { (theme?.backgroundGradient[0] ?? Color(white: 0.22)).opacity(0.90) }
    private var housingBottom: Color { (theme?.backgroundGradient[1] ?? Color(white: 0.16)).opacity(0.95) }

    private var switchBody: some View {
        ZStack {
            // Housing shadow
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.55))
                .frame(width: 22, height: 34)
                .blur(radius: 2)
                .offset(y: 2)

            // Housing body — tinted with the pedal's theme color
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [housingTop, housingBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 34)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color(white: 0.52), Color(white: 0.20)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                )

            // Inner track channel
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.60))
                .frame(width: 15, height: 27)

            // Slide tab
            ZStack {
                // Tab shadow
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.black.opacity(0.35))
                    .frame(width: 13, height: 12)
                    .blur(radius: 1)
                    .offset(y: 0.5)

                // Tab body
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.94), Color(white: 0.74)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 13, height: 12)

                // Tab top highlight
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 7, height: 2)
                    .offset(y: -3.5)
            }
            .offset(y: isOn ? -7.5 : 7.5)
            .animation(.easeInOut(duration: 0.12), value: isOn)

            // ON indicator LED at top of housing
            Circle()
                .fill(isOn ? onColor : Color(white: 0.22))
                .frame(width: 4, height: 4)
                .offset(y: -13.5)
                .shadow(color: isOn ? onColor.opacity(0.7) : .clear, radius: 2)
                .animation(.easeInOut(duration: 0.12), value: isOn)
        }
        .frame(width: 22, height: 34)
        .contentShape(Rectangle())
        .onTapGesture {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            #endif
            isOn.toggle()
        }
        // .help() on the interactive view so macOS tooltip fires on the right NSView layer
        .help(
            parameter.map {
                ParameterDescriptions.description(for: $0.id, cc: $0.cc, pedalId: pedalId)
            } ?? ""
        )
    }
}
