import SwiftUI

/// Main window layout — toolbar with MIDI selector + tab bar for pedals
struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Pedal tabs
            if let selectedPedal = appViewModel.selectedPedal {
                PedalView(viewModel: selectedPedal)
            } else {
                Text("No pedal selected")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                MIDIDeviceSelector(midiManager: appViewModel.midiManager)
            }

            ToolbarItem(placement: .principal) {
                Picker("Pedal", selection: $appViewModel.selectedPedalIndex) {
                    ForEach(Array(appViewModel.pedalViewModels.enumerated()), id: \.element.id) { index, vm in
                        Text(vm.definition.name).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }

            ToolbarItem(placement: .primaryAction) {
                Text(appViewModel.midiManager.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
