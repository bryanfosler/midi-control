#if os(iOS)
import SwiftUI

/// Root iOS layout — adapts to iPhone (compact) vs iPad (regular).
///
/// iPhone: Custom thin top bar (pedal picker · SEND · Presets · Settings gear),
///         pedal enclosure fills all remaining screen space, no bottom bar.
///         Settings sheet contains channel change + BT MIDI device connection.
/// iPad:   NavigationSplitView with pedal picker in sidebar, detail on right
struct iOSContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    // iPad-specific sheet state (iPhone uses iPhoneRootView's own state)
    @State private var iPadSettingsVM: PedalViewModel? = nil
    @State private var iPadPresetsVM: PedalViewModel? = nil
    @State private var showingIPadSettings = false
    @State private var showingIPadPresets = false

    var body: some View {
        if sizeClass == .regular {
            ipadLayout
        } else {
            iPhoneRootView()
        }
    }

    // MARK: - iPad Layout

    private var ipadLayout: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                ipadLandscapeLayout
            } else {
                ipadPortraitLayout
            }
        }
        .sheet(isPresented: $showingIPadSettings) {
            if let vm = iPadSettingsVM {
                iOSSettingsSheet(viewModel: vm)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingIPadPresets) {
            if let vm = iPadPresetsVM {
                NavigationStack {
                    PresetPanel(viewModel: vm)
                        .navigationTitle("\(vm.definition.name) Presets")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showingIPadPresets = false }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    /// Landscape: all pedals side by side with a shared settings/presets toolbar.
    private var ipadLandscapeLayout: some View {
        NavigationStack {
            HStack(spacing: 1) {
                ForEach(appViewModel.pedalViewModels) { vm in
                    PedalColumn(
                        viewModel: vm,
                        layout: PedalLayout.layout(for: vm.definition.id),
                        theme: PedalColorTheme.theme(for: vm.definition.id)
                    )
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Settings + Presets for whichever pedal is first (landscape shows all)
                if let vm = appViewModel.pedalViewModels.first {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            iPadPresetsVM = vm
                            showingIPadPresets = true
                        } label: {
                            Image(systemName: "bookmark")
                        }
                        Button {
                            iPadSettingsVM = vm
                            showingIPadSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
        }
    }

    /// Portrait: sidebar picker + single pedal detail with per-pedal toolbar actions.
    private var ipadPortraitLayout: some View {
        NavigationSplitView {
            List(appViewModel.pedalViewModels) { vm in
                NavigationLink(vm.definition.name) {
                    PedalColumn(
                        viewModel: vm,
                        layout: PedalLayout.layout(for: vm.definition.id),
                        theme: PedalColorTheme.theme(for: vm.definition.id)
                    )
                    .navigationTitle(vm.definition.name)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button {
                                iPadPresetsVM = vm
                                showingIPadPresets = true
                            } label: {
                                Image(systemName: "bookmark")
                            }
                            Button {
                                iPadSettingsVM = vm
                                showingIPadSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pedals")
        } detail: {
            Text("Select a pedal")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - iPhone Root

private struct iPhoneRootView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedIndex: Int = 0
    @State private var showingPresets = false
    @State private var showingSettings = false

    private var pedals: [PedalViewModel] { appViewModel.pedalViewModels }
    private var selectedVM: PedalViewModel? {
        pedals.indices.contains(selectedIndex) ? pedals[selectedIndex] : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if let vm = selectedVM {
                PedalColumn(
                    viewModel: vm,
                    layout: PedalLayout.layout(for: vm.definition.id),
                    theme: PedalColorTheme.theme(for: vm.definition.id)
                )
            }
        }
        .sheet(isPresented: $showingPresets) {
            presetsSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
        .sheet(isPresented: $showingSettings) {
            if let vm = selectedVM {
                iOSSettingsSheet(viewModel: vm)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 14) {
            pedalPickerMenu

            Spacer()

            if let vm = selectedVM {
                Button("SEND") { vm.sendAll() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color(.separator), lineWidth: 0.5)
                            )
                    )
            }

            Button { showingPresets = true } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 14))
            }
            .foregroundStyle(.primary)

            Button { showingSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
            }
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Pedal Picker
    // Single pedal: plain label. Multiple pedals: Menu dropdown.

    @ViewBuilder
    private var pedalPickerMenu: some View {
        if pedals.count <= 1 {
            Text(pedals.first?.definition.name ?? "")
                .font(.subheadline.weight(.medium))
        } else {
            Menu {
                ForEach(pedals.indices, id: \.self) { i in
                    Button {
                        selectedIndex = i
                    } label: {
                        if i == selectedIndex {
                            Label(pedals[i].definition.name, systemImage: "checkmark")
                        } else {
                            Text(pedals[i].definition.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(pedals[selectedIndex].definition.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Presets Sheet

    @ViewBuilder
    private var presetsSheet: some View {
        NavigationStack {
            if let vm = selectedVM {
                PresetPanel(viewModel: vm)
                    .navigationTitle("\(vm.definition.name) Presets")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingPresets = false }
                        }
                    }
            }
        }
    }
}

// MARK: - Settings Sheet

private struct iOSSettingsSheet: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @ObservedObject var viewModel: PedalViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingBTSetup = false
    @State private var showingChannelSheet = false
    @State private var targetChannel: Int = 1

    var body: some View {
        NavigationStack {
            List {
                // MIDI Channel
                Section("MIDI Channel") {
                    HStack {
                        Label("Channel", systemImage: "antenna.radiowaves.left.and.right")
                        Spacer()
                        Text("Ch \(viewModel.midiChannel)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Button("Change") {
                            targetChannel = viewModel.midiChannel
                            showingChannelSheet = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                // Bluetooth MIDI
                Section("Bluetooth MIDI") {
                    Button {
                        showingBTSetup = true
                    } label: {
                        Label("Connect BT MIDI Device", systemImage: "dot.radiowaves.left.and.right")
                    }

                    if appViewModel.midiManager.destinations.isEmpty {
                        Text("No MIDI destinations found")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(appViewModel.midiManager.destinations) { dest in
                            Label(dest.name, systemImage: "music.note")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingBTSetup) {
                BTMIDISetupView()
            }
            .sheet(isPresented: $showingChannelSheet) {
                channelPickerSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Channel Picker Sheet (mirrors PedalColumn.channelChangeSheet logic for iOS)

    private var channelPickerSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Change MIDI Channel")
                        .font(.headline)
                    Text(viewModel.definition.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label("How this works", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("This sends **CC 104** on the pedal's current channel (ch \(viewModel.midiChannel)). The physical pedal responds by switching to the new channel — no manual button-pressing required.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current channel")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Ch \(viewModel.midiChannel)")
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text("New channel")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $targetChannel) {
                        ForEach(1...16, id: \.self) { ch in
                            Text("Ch \(ch)").tag(ch)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                }
            }

            if targetChannel == viewModel.midiChannel {
                Label("Select a different channel to change", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Label("Tip: if you have two pedals, give each a unique channel so CC messages don't cross-talk.", systemImage: "lightbulb")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            HStack {
                Button("Cancel") { showingChannelSheet = false }

                Spacer()

                Button("Apply to Pedal") {
                    viewModel.setPedalMidiChannel(to: targetChannel)
                    showingChannelSheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(targetChannel == viewModel.midiChannel)
            }
        }
        .padding(20)
    }
}
#endif
