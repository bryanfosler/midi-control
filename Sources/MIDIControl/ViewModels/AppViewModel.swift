import Foundation
import Combine

/// App-level state: MIDI device selection, pedal list, active pedal
class AppViewModel: ObservableObject {
    @Published var midiManager: MIDIManager
    @Published var pedalViewModels: [PedalViewModel]
    @Published var selectedPedalIndex: Int = 0

    let presetStorage: PresetStorage
    let availablePedals: [PedalDefinition] = [.brothersAM, .moodMKII]

    var selectedPedal: PedalViewModel? {
        guard selectedPedalIndex < pedalViewModels.count else { return nil }
        return pedalViewModels[selectedPedalIndex]
    }

    init() {
        let midi = MIDIManager()
        let storage = PresetStorage()

        self.midiManager = midi
        self.presetStorage = storage
        self.pedalViewModels = [
            PedalViewModel(definition: .brothersAM, midiManager: midi, presetStorage: storage),
            PedalViewModel(definition: .moodMKII, midiManager: midi, presetStorage: storage),
        ]
    }
}
