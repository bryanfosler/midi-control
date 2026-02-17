import Foundation
import Combine

/// ViewModel for a single pedal instance — manages state and sends MIDI
class PedalViewModel: ObservableObject, Identifiable {
    let id: String
    let definition: PedalDefinition

    @Published var state: PedalState
    @Published var midiChannel: Int {
        didSet { state.midiChannel = midiChannel }
    }

    private weak var midiManager: MIDIManager?
    private let presetStorage: PresetStorage
    @Published var presets: [Preset] = []

    init(definition: PedalDefinition, midiManager: MIDIManager, presetStorage: PresetStorage) {
        self.id = definition.id
        self.definition = definition
        self.midiManager = midiManager
        self.presetStorage = presetStorage
        self.midiChannel = definition.defaultChannel
        self.state = PedalState(definition: definition)
        loadPresetList()
    }

    // MARK: - Parameter Control

    /// Update a parameter value and send the corresponding CC message immediately
    func setValue(_ value: Int, for param: ParameterDefinition) {
        state.setValue(value, for: param)
        midiManager?.sendCC(channel: midiChannel, cc: param.cc, value: value)
    }

    /// Get the current value for a parameter
    func value(for param: ParameterDefinition) -> Int {
        state.value(for: param)
    }

    /// Send a momentary footswitch press (value 127)
    func triggerFootswitch(_ param: ParameterDefinition) {
        midiManager?.sendCC(channel: midiChannel, cc: param.cc, value: 127)
    }

    /// Send all current parameter values to the pedal (bulk sync)
    func sendAll() {
        for param in definition.parameters {
            let value = state.value(for: param)
            midiManager?.sendCC(channel: midiChannel, cc: param.cc, value: value)
        }
    }

    // MARK: - Preset Management

    /// Reload the preset list from storage
    func loadPresetList() {
        presets = presetStorage.loadPresets(for: definition.id)
    }

    /// Save the current state as a new preset
    func savePreset(name: String, notes: String = "", tags: [String] = []) {
        let preset = Preset(
            name: name,
            pedalId: definition.id,
            midiChannel: midiChannel,
            parameters: state.values,
            notes: notes,
            tags: tags
        )
        presetStorage.save(preset)
        state.markClean()
        loadPresetList()
    }

    /// Load a preset: update all UI values and send all CCs to pedal
    func loadPreset(_ preset: Preset) {
        state.loadValues(preset.parameters)
        midiChannel = preset.midiChannel
        sendAll()
    }

    /// Delete a preset
    func deletePreset(_ preset: Preset) {
        presetStorage.delete(preset)
        loadPresetList()
    }

    /// Rename a preset
    func renamePreset(_ preset: Preset, to newName: String) {
        var updated = preset
        updated.name = newName
        updated.updatedAt = Date()
        presetStorage.save(updated)
        loadPresetList()
    }
}
