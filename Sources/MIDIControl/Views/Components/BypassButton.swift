import SwiftUI

/// A toggle button for bypass/footswitch parameters with LED indicator and 3D look
struct BypassButton: View {
    let parameter: ParameterDefinition
    @Binding var isActive: Bool
    let onTap: () -> Void
    var theme: PedalColorTheme? = nil

    @State private var isPressed = false

    private var ledActive: Color { theme?.ledActiveColor ?? .green }
    private var ledInactive: Color { theme?.ledInactiveColor ?? Color.gray.opacity(0.3) }
    private var buttonColor: Color { theme?.footswitchColor ?? Color(white: 0.85) }

    var body: some View {
        VStack(spacing: 6) {
            // LED indicator
            Circle()
                .fill(isActive ? ledActive : ledInactive)
                .frame(width: 8, height: 8)
                .shadow(color: isActive ? ledActive.opacity(0.6) : .clear, radius: 4)

            // Footswitch button
            Button(action: {
                isActive.toggle()
                onTap()
            }) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [buttonColor, buttonColor.opacity(0.7)],
                            center: .init(x: 0.4, y: 0.35),
                            startRadius: 0,
                            endRadius: 22
                        )
                    )
                    .frame(width: 38, height: 38)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.black.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(color: .black.opacity(isPressed ? 0.1 : 0.25), radius: isPressed ? 1 : 3, y: isPressed ? 0 : 2)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.easeInOut(duration: 0.08)) { isPressed = true }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.08)) { isPressed = false }
                    }
            )

            // Label
            Text(parameter.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(theme?.labelColor ?? .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

/// A momentary button that sends a single CC 127 on press
struct MomentaryButton: View {
    let parameter: ParameterDefinition
    let onPress: () -> Void
    var theme: PedalColorTheme? = nil

    var body: some View {
        Button(action: onPress) {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1)
                    }
                Text(parameter.name)
                    .font(.caption2)
                    .foregroundStyle(theme?.labelColor ?? .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
