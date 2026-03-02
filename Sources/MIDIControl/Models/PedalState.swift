import Foundation

/// Live runtime state of a pedal instance — tracks current CC values
class PedalState: ObservableObject {
    let definition: PedalDefinition
    var midiChannel: Int  // 1-16 user-facing

    /// Current value for each parameter, keyed by CC number
    @Published var values: [Int: Int]

    /// Whether any values have changed since last save/load
    @Published var isDirty: Bool = false

    init(definition: PedalDefinition, midiChannel: Int? = nil) {
        self.definition = definition
        self.midiChannel = midiChannel ?? definition.defaultChannel

        // Initialize all parameters to their defaults
        var initial: [Int: Int] = [:]
        for param in definition.parameters {
            initial[param.cc] = param.defaultValue
        }
        self.values = initial
    }

    /// Get the current value for a parameter
    func value(for param: ParameterDefinition) -> Int {
        values[param.cc] ?? param.defaultValue
    }

    /// Set a parameter value and mark state as dirty
    func setValue(_ value: Int, for param: ParameterDefinition) {
        let clamped = max(0, min(127, value))
        values[param.cc] = clamped
        isDirty = true
    }

    /// Load all values from a preset's parameter dictionary.
    /// Resets all params to their factory defaults first, then overlays the preset values.
    /// This prevents leftover state from a previous preset bleeding through for CCs not
    /// included in the new preset.
    func loadValues(_ presetValues: [Int: Int]) {
        var newValues: [Int: Int] = [:]
        for param in definition.parameters {
            newValues[param.cc] = param.defaultValue
        }
        for (cc, value) in presetValues {
            newValues[cc] = max(0, min(127, value))
        }
        values = newValues
        isDirty = false
    }

    /// Reset all parameters to their factory default values
    func resetToDefaults() {
        var defaults: [Int: Int] = [:]
        for param in definition.parameters {
            defaults[param.cc] = param.defaultValue
        }
        values = defaults
        isDirty = false
    }

    /// Reset dirty flag (after saving)
    func markClean() {
        isDirty = false
    }
}
