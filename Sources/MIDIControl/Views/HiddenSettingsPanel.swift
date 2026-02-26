import SwiftUI

/// Collapsible panel below each pedal for hidden/advanced parameters.
/// The whole panel collapses, and each section inside is individually collapsible.
struct HiddenSettingsPanel: View {
    @ObservedObject var viewModel: PedalViewModel
    let layout: PedalLayout
    let theme: PedalColorTheme

    @State private var isPanelExpanded: Bool = true
    @State private var collapsedSections: Set<String> = []

    private var hiddenSections: [(name: String, parameters: [ParameterDefinition])] {
        let faceIds = layout.faceParameterIds
        var order: [String] = []
        var groups: [String: [ParameterDefinition]] = [:]
        for param in viewModel.definition.parameters {
            guard !faceIds.contains(param.id) else { continue }
            if groups[param.section] == nil { order.append(param.section) }
            groups[param.section, default: []].append(param)
        }
        return order.map { (name: $0, parameters: groups[$0]!) }
    }

    var body: some View {
        if hiddenSections.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 0) {
                panelHeader

                if isPanelExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(hiddenSections, id: \.name) { section in
                            collapsibleSection(section)
                            if section.name != hiddenSections.last?.name {
                                Divider()
                                    .background(theme.labelColor.opacity(0.12))
                                    .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(12)
                }
            }
            .background(panelBackground)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Panel header

    private var panelHeader: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                isPanelExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "slider.vertical.3")
                    .font(.system(size: 10))
                Text("ADVANCED SETTINGS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                Text("— hidden options")
                    .font(.system(size: 9))
                    .foregroundStyle(theme.labelColor.opacity(0.45))
                Spacer()
                Image(systemName: isPanelExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(theme.labelColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Per-section collapsible

    @ViewBuilder
    private func collapsibleSection(_ section: (name: String, parameters: [ParameterDefinition])) -> some View {
        let isCollapsed = collapsedSections.contains(section.name)

        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    if isCollapsed { collapsedSections.remove(section.name) }
                    else           { collapsedSections.insert(section.name) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(section.name.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(theme.labelColor.opacity(0.55))
                    Spacer()
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(theme.labelColor.opacity(0.40))
                }
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                sectionContent(for: section)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Section content

    @ViewBuilder
    private func sectionContent(for section: (name: String, parameters: [ParameterDefinition])) -> some View {
        let fullWidthParams = section.parameters.filter { needsFullWidth($0) }
        let gridParams      = section.parameters.filter { !needsFullWidth($0) }

        VStack(alignment: .leading, spacing: 6) {
            ForEach(fullWidthParams) { param in
                fullWidthControl(for: param)
            }

            if !gridParams.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(gridParams) { param in
                        hiddenParamControl(param)
                            .help(ParameterDescriptions.description(
                                for: param.id, cc: param.cc,
                                pedalId: viewModel.definition.id
                            ))
                    }
                }
            }
        }
    }

    /// Full-width params need their own dispatch: waveform picker, stepped picker, or factory reset.
    @ViewBuilder
    private func fullWidthControl(for param: ParameterDefinition) -> some View {
        if param.id == "ramping_waveform" {
            WaveformPickerView(
                parameter: param,
                value: bindingForParam(param),
                onChange: { value in viewModel.setValue(value, for: param) }
            )
            .help(ParameterDescriptions.description(
                for: param.id, cc: param.cc, pedalId: viewModel.definition.id
            ))
        } else if param.id == "factory_reset" {
            FactoryResetButton(
                parameter: param,
                onConfirmed: { viewModel.triggerFootswitch(param) },
                pedalId: viewModel.definition.id
            )
        } else if case .toggle(let options) = param.type {
            SteppedPickerView(
                parameter: param,
                steps: options,
                value: bindingForParam(param),
                onChange: { value in viewModel.setValue(value, for: param) },
                pedalId: viewModel.definition.id
            )
        }
    }

    /// Returns true for controls that should span the full section width.
    private func needsFullWidth(_ param: ParameterDefinition) -> Bool {
        if param.id == "ramping_waveform" { return true }
        if param.id == "factory_reset"    { return true }
        if case .toggle(let options) = param.type { return options.count > 4 }
        return false
    }

    // MARK: - Grid param controls

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
                    if let tooltip = ParameterTooltips.label(
                        for: param.id,
                        value: viewModel.state.values[param.cc] ?? param.defaultValue
                    ) {
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
                    onChange: { value in viewModel.setValue(value, for: param) },
                    showLabel: false
                )
            }

        case .toggle(let options):
            ToggleSwitch(
                parameter: param,
                options: options,
                value: bindingForParam(param),
                onChange: { value in viewModel.setValue(value, for: param) },
                pedalId: viewModel.definition.id
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
                        set: { newValue in viewModel.setValue(newValue ? 127 : 0, for: param) }
                    ),
                    parameter: param,
                    pedalId: viewModel.definition.id
                )
            }

        case .footswitch:
            MomentaryButton(
                parameter: param,
                onPress: { viewModel.triggerFootswitch(param) },
                pedalId: viewModel.definition.id
            )
        }
    }

    private func bindingForParam(_ param: ParameterDefinition) -> Binding<Int> {
        Binding(
            get: { viewModel.state.values[param.cc] ?? param.defaultValue },
            set: { viewModel.state.values[param.cc] = $0 }
        )
    }

    // MARK: - Background

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(
                colors: [
                    theme.backgroundGradient[0].opacity(0.50),
                    theme.backgroundGradient[1].opacity(0.65),
                ],
                startPoint: .top, endPoint: .bottom
            ))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(theme.labelColor.opacity(0.28), lineWidth: 1)
            )
    }
}

// MARK: - Factory Reset Button
// Two deliberate steps required: hold 2s to arm → confirmation alert to execute.

private struct FactoryResetButton: View {
    let parameter: ParameterDefinition
    let onConfirmed: () -> Void
    var pedalId: String = ""

    @State private var holdProgress: CGFloat = 0
    @State private var holdTimer: Timer? = nil
    @State private var holdStart: Date? = nil
    @State private var showingAlert = false
    private let holdDuration: TimeInterval = 2.0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.red.opacity(0.07))
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.red.opacity(0.20))
                        .frame(width: geo.size.width * holdProgress)
                }
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text(holdProgress > 0 ? "Hold to arm…" : "Factory Reset Pedal")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 10)
                .foregroundStyle(Color.red.opacity(0.50 + 0.50 * holdProgress))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.red.opacity(0.28 + 0.42 * holdProgress), lineWidth: 0.75)
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in beginHold() }
                    .onEnded   { _ in cancelHold() }
            )
            .alert("Send Factory Reset to Pedal?", isPresented: $showingAlert) {
                Button("Factory Reset", role: .destructive) { onConfirmed() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Sends CC \(parameter.cc) to the hardware pedal. This permanently erases all presets stored on the pedal. Cannot be undone.")
            }

            Text("Hold 2s then confirm — permanently erases pedal presets")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .help(ParameterDescriptions.description(for: parameter.id, cc: parameter.cc, pedalId: pedalId))
        }
        .frame(maxWidth: .infinity)
    }

    private func beginHold() {
        guard holdTimer == nil else { return }
        holdStart = Date()
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { t in
            guard let start = holdStart else { t.invalidate(); return }
            let progress = min(1.0, Date().timeIntervalSince(start) / holdDuration)
            DispatchQueue.main.async {
                holdProgress = CGFloat(progress)
                if progress >= 1.0 {
                    t.invalidate()
                    holdTimer = nil
                    holdStart = nil
                    withAnimation(.spring(response: 0.3)) { holdProgress = 0 }
                    showingAlert = true
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        holdTimer = timer
    }

    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdStart = nil
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { holdProgress = 0 }
    }
}
