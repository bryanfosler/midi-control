import Foundation
import Combine

/// App-level state: MIDI device selection and pedal list
class AppViewModel: ObservableObject {
    @Published var midiManager: MIDIManager
    @Published var pedalViewModels: [PedalViewModel]

    let presetStorage: PresetStorage
    let availablePedals: [PedalDefinition] = [.moodMKII, .brothersAM]

    init() {
        let midi = MIDIManager()
        let storage = PresetStorage()

        self.midiManager = midi
        self.presetStorage = storage

        // Seed factory presets before ViewModels load their lists
        FactoryPresets.seedIfNeeded(storage: storage)

        self.pedalViewModels = [
            PedalViewModel(definition: .moodMKII, midiManager: midi, presetStorage: storage),
            PedalViewModel(definition: .brothersAM, midiManager: midi, presetStorage: storage),
        ]
    }
}
