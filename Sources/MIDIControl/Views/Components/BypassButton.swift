import SwiftUI

/// A toggle button styled as a physical guitar pedal footswitch with LED indicator
struct BypassButton: View {
    let parameter: ParameterDefinition
    @Binding var isActive: Bool
    let onTap: () -> Void
    var theme: PedalColorTheme? = nil
    var pedalId: String = ""

    @State private var isPressed = false

    private var ledActive: Color   { theme?.ledActiveColor  ?? .green }
    private var ledInactive: Color { theme?.ledInactiveColor ?? Color(white: 0.18) }
    private var buttonColor: Color { theme?.footswitchColor  ?? Color(white: 0.85) }

    var body: some View {
        VStack(spacing: 5) {
            ledIndicator
            footswitchBody
            Text(parameter.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(theme?.labelColor ?? .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .help(ParameterDescriptions.description(for: parameter.id, cc: parameter.cc, pedalId: pedalId))
    }

    // MARK: - LED

    private var ledIndicator: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(isActive ? ledActive.opacity(0.35) : .clear)
                .frame(width: 16, height: 16)
                .blur(radius: 4)

            // LED body
            Circle()
                .fill(isActive ? ledActive : ledInactive)
                .frame(width: 10, height: 10)

            // Lens highlight (top-left)
            Circle()
                .fill(Color.white.opacity(isActive ? 0.50 : 0.12))
                .frame(width: 4, height: 4)
                .offset(x: -1.5, y: -1.5)
        }
    }

    // MARK: - Footswitch

    private var footswitchBody: some View {
        Button(action: {
            isActive.toggle()
            onTap()
        }) {
            ZStack {
                // Outer rubber ring
                Circle()
                    .fill(Color(white: 0.16))
                    .frame(width: 48, height: 48)

                // Main body with radial gradient (3D dome)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                buttonColor,
                                buttonColor.opacity(0.82),
                                buttonColor.opacity(0.62),
                            ],
                            center: UnitPoint(x: 0.38, y: 0.35),
                            startRadius: 0,
                            endRadius: 24
                        )
                    )
                    .frame(width: 40, height: 40)

                // Specular highlight (light reflection)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.30), Color.clear],
                            center: UnitPoint(x: 0.35, y: 0.30),
                            startRadius: 0,
                            endRadius: 16
                        )
                    )
                    .frame(width: 40, height: 40)

                // Bevel edge ring
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.32), Color.black.opacity(0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 40, height: 40)
            }
            .shadow(
                color: .black.opacity(isPressed ? 0.15 : 0.45),
                radius: isPressed ? 1 : 5,
                y: isPressed ? 0 : 3
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.05)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.08)) { isPressed = false }
                }
        )
    }
}

// MARK: - Momentary Button

/// A one-shot button for actions like Freeze, Overdub, Factory Reset
struct MomentaryButton: View {
    let parameter: ParameterDefinition
    let onPress: () -> Void
    var theme: PedalColorTheme? = nil
    var pedalId: String = ""

    @State private var isPressed = false

    var body: some View {
        Button(action: onPress) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(isPressed ? 0.35 : 0.18))
                        .frame(width: 34, height: 34)
                    Circle()
                        .strokeBorder(Color.orange.opacity(0.55), lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                    // Subtle highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.15), Color.clear],
                                center: UnitPoint(x: 0.35, y: 0.3),
                                startRadius: 0,
                                endRadius: 14
                            )
                        )
                        .frame(width: 34, height: 34)
                }
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .animation(.easeInOut(duration: 0.08), value: isPressed)

                Text(parameter.name)
                    .font(.caption2)
                    .foregroundStyle(theme?.labelColor ?? .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .help(ParameterDescriptions.description(for: parameter.id, cc: parameter.cc, pedalId: pedalId))
    }
}
