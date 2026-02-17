import SwiftUI

/// A toggle button for bypass/footswitch parameters
struct BypassButton: View {
    let parameter: ParameterDefinition
    @Binding var isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            isActive.toggle()
            onTap()
        }) {
            VStack(spacing: 4) {
                Circle()
                    .fill(isActive ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                    }
                Text(parameter.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A momentary button that sends a single CC 127 on press
struct MomentaryButton: View {
    let parameter: ParameterDefinition
    let onPress: () -> Void

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
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
