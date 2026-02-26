import SwiftUI

/// Full-width stepped picker for discrete multi-position parameters (5–9 positions).
/// Each position is a tappable cell showing a label; the selected cell is highlighted.
/// Used for Clock Division (8 positions) and Octave Transpose (9 positions).
struct SteppedPickerView: View {
    let parameter: ParameterDefinition
    let steps: [ToggleOption]
    @Binding var value: Int
    let onChange: (Int) -> Void
    var pedalId: String = ""

    private var selectedIndex: Int {
        steps.indices.min(by: { abs(steps[$0].value - value) < abs(steps[$1].value - value) }) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(parameter.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(steps[selectedIndex].name)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text("CC\(parameter.cc)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 2) {
                ForEach(steps.indices, id: \.self) { i in
                    let isSelected = selectedIndex == i
                    Button {
                        value = steps[i].value
                        onChange(steps[i].value)
                    } label: {
                        Text(steps[i].name)
                            .font(.system(size: 8, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(isSelected
                                          ? Color.accentColor.opacity(0.14)
                                          : Color.secondary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(
                                        isSelected ? Color.accentColor.opacity(0.50) : Color.secondary.opacity(0.14),
                                        lineWidth: 0.5
                                    )
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .help(ParameterDescriptions.description(for: parameter.id, cc: parameter.cc, pedalId: pedalId))
    }
}
