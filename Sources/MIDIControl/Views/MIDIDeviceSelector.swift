import SwiftUI

/// Dropdown picker for selecting a MIDI output device
struct MIDIDeviceSelector: View {
    @ObservedObject var midiManager: MIDIManager

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(midiManager.selectedDestinationIndex != nil ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            Picker("MIDI Output", selection: Binding(
                get: { midiManager.selectedDestinationIndex ?? -1 },
                set: { newValue in
                    midiManager.selectDestination(at: newValue >= 0 ? newValue : nil)
                }
            )) {
                Text("None").tag(-1)
                ForEach(Array(midiManager.destinations.enumerated()), id: \.element.id) { index, dest in
                    Text(dest.name).tag(index)
                }
            }
            .frame(width: 200)

            Button(action: { midiManager.refreshDestinations() }) {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh MIDI devices")
        }
    }
}
