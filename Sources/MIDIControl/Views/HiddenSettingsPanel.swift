import SwiftUI

/// Always-visible panel below each pedal for hidden/advanced parameters
/// Shows parameters NOT on the pedal face, grouped by section
struct HiddenSettingsPanel: View {
    @ObservedObject var viewModel: PedalViewModel
    let layout: PedalLayout
    let theme: PedalColorTheme

    /// All parameters that are NOT on the pedal face
    private var hiddenSections: [(name: String, parameters: [ParameterDefinition])] {
        let faceIds = layout.faceParameterIds
        var order: [String] = []
        var groups: [String: [ParameterDefinition]] = [:]
        for param in viewModel.definition.parameters {
            guard !faceIds.contains(param.id) else { continue }
            if groups[param.section] == nil {
                order.append(param.section)
            }
            groups[param.section, default: []].append(param)
        }
        return order.map { (name: $0, parameters: groups[$0]!) }
    }

    var body: some View {
        if hiddenSections.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(hiddenSections, id: \.name) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(section.parameters) { param in
                                hiddenParamControl(param)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            )
        }
    }

    @ViewBuilder
    private func hiddenParamControl(_ param: ParameterDefinition) -> some View {
        switch param.type {
        case .knob:
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(param.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let tooltip = ParameterTooltips.label(for: param.id, value: viewModel.state.values[param.cc] ?? param.defaultValue) {
                        Text(tooltip)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text("\(viewModel.state.values[param.cc] ?? param.defaultValue)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
                KnobSlider(
                    parameter: param,
                    value: bindingForParam(param),
                    onChange: { value in viewModel.setValue(value, for: param) }
                )
            }
        case .toggle(let options):
            ToggleSwitch(
                parameter: param,
                options: options,
                value: bindingForParam(param),
                onChange: { value in viewModel.setValue(value, for: param) }
            )
        case .dipSwitch:
            HStack {
                Text(param.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                DipSwitch(
                    label: "",
                    isOn: Binding(
                        get: { (viewModel.state.values[param.cc] ?? 0) > 0 },
                        set: { newValue in
                            viewModel.setValue(newValue ? 127 : 0, for: param)
                        }
                    )
                )
            }
        case .footswitch:
            MomentaryButton(parameter: param) {
                viewModel.triggerFootswitch(param)
            }
        }
    }

    private func bindingForParam(_ param: ParameterDefinition) -> Binding<Int> {
        Binding(
            get: { viewModel.state.values[param.cc] ?? param.defaultValue },
            set: { viewModel.state.values[param.cc] = $0 }
        )
    }
}
