import SwiftUI

/// A segmented picker for multi-position toggle parameters
struct ToggleSwitch: View {
    let parameter: ParameterDefinition
    let options: [ToggleOption]
    @Binding var value: Int
    let onChange: (Int) -> Void
    var pedalId: String = ""

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
            Picker("", selection: Binding(
                get: { value },
                set: { newValue in
                    value = newValue
                    onChange(newValue)
                }
            )) {
                ForEach(options) { option in
                    Text(option.name).tag(option.value)
                }
            }
            .pickerStyle(.segmented)
        }
        .help(ParameterDescriptions.description(for: parameter.id, cc: parameter.cc, pedalId: pedalId))
    }
}
