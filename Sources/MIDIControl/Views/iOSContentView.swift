#if os(iOS)
import SwiftUI

/// Root iOS layout — adapts to iPhone (compact) vs iPad (regular).
///
/// iPhone: NavigationStack with top pedal picker, toolbar buttons for Presets and MIDI
/// iPad:   NavigationSplitView with pedal picker in sidebar, detail on right
struct iOSContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

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
    }

    /// Landscape: all pedals side by side, matching the macOS layout.
    private var ipadLandscapeLayout: some View {
        HStack(spacing: 1) {
            ForEach(appViewModel.pedalViewModels) { vm in
                PedalColumn(
                    viewModel: vm,
                    layout: PedalLayout.layout(for: vm.definition.id),
                    theme: PedalColorTheme.theme(for: vm.definition.id)
                )
            }
        }
    }

    /// Portrait: sidebar picker + single pedal detail.
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
    @State private var showingMIDI = false

    private var pedals: [PedalViewModel] { appViewModel.pedalViewModels }
    private var selectedVM: PedalViewModel? {
        pedals.indices.contains(selectedIndex) ? pedals[selectedIndex] : nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = selectedVM {
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
                ToolbarItem(placement: .principal) {
                    pedalPicker
                        .frame(maxWidth: 220)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingMIDI = true } label: {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingPresets = true } label: {
                        Image(systemName: "bookmark")
                    }
                }
            }
            .sheet(isPresented: $showingPresets) {
                presetsSheet
            }
            .sheet(isPresented: $showingMIDI) {
                MIDISheet()
            }
        }
    }

    // MARK: - Pedal Picker
    // ≤2 pedals: segmented control. >2 pedals: menu dropdown.

    @ViewBuilder
    private var pedalPicker: some View {
        if pedals.count <= 2 {
            Picker("Pedal", selection: $selectedIndex) {
                ForEach(pedals.indices, id: \.self) { i in
                    Text(pedals[i].definition.name).tag(i)
                }
            }
            .pickerStyle(.segmented)
        } else {
            Menu {
                ForEach(pedals.indices, id: \.self) { i in
                    Button(pedals[i].definition.name) { selectedIndex = i }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(pedals[selectedIndex].definition.name)
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
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

// MARK: - MIDI Sheet

private struct MIDISheet: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingBTSetup = false

    var body: some View {
        NavigationStack {
            List {
                Section("Bluetooth MIDI") {
                    Button {
                        showingBTSetup = true
                    } label: {
                        Label("Connect Bluetooth MIDI Device", systemImage: "dot.radiowaves.left.and.right")
                    }
                }

                Section("Connected Destinations") {
                    if appViewModel.midiManager.destinations.isEmpty {
                        Text("No MIDI destinations found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(appViewModel.midiManager.destinations) { dest in
                            Label(dest.name, systemImage: "music.note")
                        }
                    }
                }
            }
            .navigationTitle("MIDI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingBTSetup) {
                BTMIDISetupView()
            }
        }
    }
}
#endif
