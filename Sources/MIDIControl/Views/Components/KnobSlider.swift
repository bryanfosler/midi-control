import SwiftUI

/// A slider control for continuous CC parameters (0-127)
struct KnobSlider: View {
    let parameter: ParameterDefinition
    @Binding var value: Int
    let onChange: (Int) -> Void
    var showLabel: Bool = true

    @State private var sliderValue: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showLabel {
                HStack {
                    Text(parameter.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(value)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text("CC\(parameter.cc)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Slider(value: $sliderValue, in: 0...127, step: 1)
                .onChange(of: sliderValue) { _, newValue in
                    let intValue = Int(newValue)
                    if intValue != value {
                        value = intValue
                        onChange(intValue)
                    }
                }
        }
        .onAppear {
            sliderValue = Double(value)
        }
        .onChange(of: value) { _, newValue in
            if Int(sliderValue) != newValue {
                sliderValue = Double(newValue)
            }
        }
    }
}
