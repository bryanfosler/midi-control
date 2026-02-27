#if os(iOS)
import SwiftUI

/// Root iOS layout — adapts to iPhone (compact) vs iPad (regular).
///
/// iPhone: TabView with three tabs — Pedals, Presets, MIDI
/// iPad:   NavigationSplitView with pedal picker in sidebar, detail on right
struct iOSContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            ipadLayout
        } else {
            iphoneLayout
        }
    }

    // MARK: - iPad Layout

    private var ipadLayout: some View {
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

    // MARK: - iPhone Layout

    private var iphoneLayout: some View {
        TabView {
            // ── Pedals tab ──
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(appViewModel.pedalViewModels) { vm in
                        PedalColumn(
                            viewModel: vm,
                            layout: PedalLayout.layout(for: vm.definition.id),
                            theme: PedalColorTheme.theme(for: vm.definition.id)
                        )
                    }
                }
                .padding()
            }
            .tabItem {
                Label("Pedals", systemImage: "slider.horizontal.3")
            }

            // ── Presets tab ──
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(appViewModel.pedalViewModels) { vm in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(vm.definition.name)
                                .font(.headline)
                                .padding(.horizontal)
                            PresetPanel(viewModel: vm)
                        }
                    }
                }
                .padding(.vertical)
            }
            .tabItem {
                Label("Presets", systemImage: "bookmark")
            }

            // ── MIDI / Bluetooth tab ──
            MIDITabView()
                .tabItem {
                    Label("MIDI", systemImage: "antenna.radiowaves.left.and.right")
                }
        }
    }
}

// MARK: - MIDI Tab

private struct MIDITabView: View {
    @EnvironmentObject var appViewModel: AppViewModel
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
            .sheet(isPresented: $showingBTSetup) {
                BTMIDISetupView()
            }
        }
    }
}
#endif
