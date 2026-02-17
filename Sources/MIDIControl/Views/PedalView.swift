import SwiftUI

/// Full control view for a single pedal — renders controls dynamically from PedalDefinition
struct PedalView: View {
    @ObservedObject var viewModel: PedalViewModel

    // Track bypass states locally (footswitches are momentary on the pedal,
    // but we display them as toggles for UX clarity)
    @State private var bypassStates: [Int: Bool] = [:]

    var body: some View {
        HSplitView {
            // Left: pedal controls
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    pedalHeader
                    ForEach(viewModel.definition.sections, id: \.name) { section in
                        sectionView(section.name, parameters: section.parameters)
                    }
                }
                .padding()
            }
            .frame(minWidth: 400)

            // Right: preset panel
            PresetPanel(viewModel: viewModel)
                .frame(minWidth: 250, maxWidth: 300)
        }
    }

    // MARK: - Header

    private var pedalHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.definition.name)
                    .font(.title2.bold())
                Text(viewModel.definition.manufacturer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                // MIDI Channel picker
                Picker("Ch", selection: $viewModel.midiChannel) {
                    ForEach(1...16, id: \.self) { ch in
                        Text("\(ch)").tag(ch)
                    }
                }
                .frame(width: 80)

                // Send All button
                Button("Send All") {
                    viewModel.sendAll()
                }
                .help("Send all current values to the pedal")
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }

    // MARK: - Section Rendering

    @ViewBuilder
    private func sectionView(_ name: String, parameters: [ParameterDefinition]) -> some View {
        let sectionType = determineSectionType(parameters)

        switch sectionType {
        case .knobs:
            knobsSection(name, parameters: parameters)
        case .toggles:
            togglesSection(name, parameters: parameters)
        case .dipSwitches:
            dipSwitchSection(name, parameters: parameters)
        case .footswitches:
            footswitchSection(name, parameters: parameters)
        case .mixed:
            mixedSection(name, parameters: parameters)
        }
    }

    private enum SectionType {
        case knobs, toggles, dipSwitches, footswitches, mixed
    }

    private func determineSectionType(_ parameters: [ParameterDefinition]) -> SectionType {
        let types = Set(parameters.map { paramBaseType($0.type) })
        if types.count == 1 {
            switch paramBaseType(parameters[0].type) {
            case "knob": return .knobs
            case "toggle": return .toggles
            case "dipSwitch": return .dipSwitches
            case "footswitch": return .footswitches
            default: return .mixed
            }
        }
        return .mixed
    }

    private func paramBaseType(_ type: ParameterType) -> String {
        switch type {
        case .knob: return "knob"
        case .toggle: return "toggle"
        case .dipSwitch: return "dipSwitch"
        case .footswitch: return "footswitch"
        }
    }

    // MARK: - Knobs Section

    private func knobsSection(_ name: String, parameters: [ParameterDefinition]) -> some View {
        GroupBox(name) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(parameters) { param in
                    KnobSlider(
                        parameter: param,
                        value: bindingForParam(param),
                        onChange: { value in
                            viewModel.setValue(value, for: param)
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Toggles Section

    private func togglesSection(_ name: String, parameters: [ParameterDefinition]) -> some View {
        GroupBox(name) {
            VStack(spacing: 12) {
                ForEach(parameters) { param in
                    if case .toggle(let options) = param.type {
                        ToggleSwitch(
                            parameter: param,
                            options: options,
                            value: bindingForParam(param),
                            onChange: { value in
                                viewModel.setValue(value, for: param)
                            }
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Dip Switch Section

    private func dipSwitchSection(_ name: String, parameters: [ParameterDefinition]) -> some View {
        GroupBox(name) {
            DipSwitchBank(
                parameters: parameters,
                values: $viewModel.state.values,
                onChange: { param, value in
                    viewModel.setValue(value, for: param)
                }
            )
            .padding(.vertical, 4)
        }
    }

    // MARK: - Footswitch Section

    private func footswitchSection(_ name: String, parameters: [ParameterDefinition]) -> some View {
        GroupBox(name) {
            HStack(spacing: 16) {
                ForEach(parameters) { param in
                    if param.id.contains("bypass") {
                        BypassButton(
                            parameter: param,
                            isActive: Binding(
                                get: { bypassStates[param.cc] ?? false },
                                set: { bypassStates[param.cc] = $0 }
                            ),
                            onTap: {
                                viewModel.triggerFootswitch(param)
                            }
                        )
                    } else {
                        MomentaryButton(parameter: param) {
                            viewModel.triggerFootswitch(param)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Mixed Section (contains different parameter types)

    private func mixedSection(_ name: String, parameters: [ParameterDefinition]) -> some View {
        GroupBox(name) {
            VStack(spacing: 12) {
                ForEach(parameters) { param in
                    switch param.type {
                    case .knob:
                        KnobSlider(
                            parameter: param,
                            value: bindingForParam(param),
                            onChange: { value in viewModel.setValue(value, for: param) }
                        )
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
                            Spacer()
                            DipSwitch(
                                label: "",
                                isOn: Binding(
                                    get: { (viewModel.state.values[param.cc] ?? 0) > 0 },
                                    set: { newValue in
                                        let value = newValue ? 127 : 0
                                        viewModel.setValue(value, for: param)
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
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    private func bindingForParam(_ param: ParameterDefinition) -> Binding<Int> {
        Binding(
            get: { viewModel.state.values[param.cc] ?? param.defaultValue },
            set: { viewModel.state.values[param.cc] = $0 }
        )
    }
}
