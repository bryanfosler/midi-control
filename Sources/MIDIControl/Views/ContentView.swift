import SwiftUI

/// Main window layout — side-by-side pedal columns with shared MIDI toolbar
struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        HStack(spacing: 1) {
            ForEach(appViewModel.pedalViewModels) { vm in
                let layout = PedalLayout.layout(for: vm.definition.id)
                let theme = PedalColorTheme.theme(for: vm.definition.id)
                PedalColumn(viewModel: vm, layout: layout, theme: theme)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                MIDIDeviceSelector(midiManager: appViewModel.midiManager)
            }

            ToolbarItem(placement: .primaryAction) {
                Text(appViewModel.midiManager.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
