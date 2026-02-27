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

    /// The ID of the last-loaded preset, used to highlight it in the preset panel.
    /// Cleared when settings are edited or reset to defaults.
    @Published var activePresetId: UUID? = nil

    /// Ghost knob values — the parameter values from the most recently loaded preset.
    /// Shown as a dim dashed arc on each knob so you can see how far the live value
    /// has drifted from the preset. Keyed by CC number (matches state.values).
    /// Cleared when reset to defaults.
    @Published var ghostValues: [Int: Int] = [:]

    private weak var midiManager: MIDIManager?
    private let presetStorage: PresetStorage
    @Published var presets: [Preset] = []

    // Forward PedalState mutations to this viewModel's objectWillChange so that
    // all views observing the viewModel (DipSwitchPanel, HiddenSettingsPanel, etc.)
    // re-render when state.values changes — e.g., on preset load or reset.
    private var stateCancellable: AnyCancellable?

    init(definition: PedalDefinition, midiManager: MIDIManager, presetStorage: PresetStorage) {
        self.id = definition.id
        self.definition = definition
        self.midiManager = midiManager
        self.presetStorage = presetStorage
        self.midiChannel = definition.defaultChannel
        self.state = PedalState(definition: definition)
        loadPresetList()

        stateCancellable = state.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
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

    func sendNoteOn(note: Int, velocity: Int = 100) {
        midiManager?.sendNoteOn(channel: midiChannel, note: note, velocity: velocity)
    }

    func sendNoteOff(note: Int) {
        midiManager?.sendNoteOff(channel: midiChannel, note: note)
    }

    /// Change the pedal's MIDI channel by sending CC 104 on the CURRENT channel,
    /// then update the app to the new channel.
    ///
    /// CC 104, value = targetChannel − 1 is the Chase Bliss channel-change command.
    /// It MUST be sent on the pedal's existing channel (before the change), otherwise
    /// the pedal won't hear it.
    func setPedalMidiChannel(to newChannel: Int) {
        guard newChannel >= 1, newChannel <= 16, newChannel != midiChannel else { return }
        midiManager?.sendCC(channel: midiChannel, cc: 104, value: newChannel - 1)
        midiChannel = newChannel
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
        activePresetId = preset.id
        loadPresetList()
    }

    /// Load a preset: update all UI values and send all CCs to pedal
    func loadPreset(_ preset: Preset) {
        state.loadValues(preset.parameters)
        midiChannel = preset.midiChannel
        activePresetId = preset.id
        ghostValues = preset.parameters
        sendAll()
    }

    /// Reset all parameters to factory defaults and send to pedal
    func resetToDefaults() {
        state.resetToDefaults()
        activePresetId = nil
        ghostValues = [:]
        sendAll()
    }

    /// Delete a preset
    func deletePreset(_ preset: Preset) {
        if activePresetId == preset.id { activePresetId = nil }
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
