import SwiftUI

/// Full column for one pedal: MIDI channel selector + pedal enclosure + hidden settings,
/// with preset sidebar
struct PedalColumn: View {
    @ObservedObject var viewModel: PedalViewModel
    let layout: PedalLayout
    let theme: PedalColorTheme

    var body: some View {
        HSplitView {
            // Left: dip switches + pedal face + hidden settings, scrollable
            ScrollView {
                VStack(spacing: 14) {
                    // Channel selector + Send All
                    channelBar

                    // Dip switches live above the pedal (they're on the physical side panel)
                    DipSwitchPanel(
                        viewModel: viewModel,
                        layout: layout,
                        theme: theme
                    )

                    // The pedal face
                    PedalEnclosure(
                        viewModel: viewModel,
                        layout: layout,
                        theme: theme
                    )

                    // Hidden / advanced settings below pedal
                    HiddenSettingsPanel(
                        viewModel: viewModel,
                        layout: layout,
                        theme: theme
                    )
                }
                .padding()
            }
            .frame(minWidth: 340)

            // Right: preset panel
            PresetPanel(viewModel: viewModel)
                .frame(minWidth: 200, maxWidth: 250)
        }
    }

    private var channelBar: some View {
        HStack {
            Picker("Ch", selection: $viewModel.midiChannel) {
                ForEach(1...16, id: \.self) { ch in
                    Text("\(ch)").tag(ch)
                }
            }
            .frame(width: 80)

            Spacer()

            Button("Send All") {
                viewModel.sendAll()
            }
            .help("Send all current values to the pedal")
        }
    }
}
