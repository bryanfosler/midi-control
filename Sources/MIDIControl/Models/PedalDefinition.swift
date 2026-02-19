import Foundation

/// Describes a type of parameter a pedal exposes over MIDI
enum ParameterType: Codable, Equatable {
    /// Continuous knob: sends CC values 0-127
    case knob
    /// Multi-position toggle: sends one of several discrete CC values
    case toggle(options: [ToggleOption])
    /// On/off dip switch: sends 0 (off) or 127 (on)
    case dipSwitch
    /// Momentary footswitch/button: sends 127 on press
    case footswitch
}

/// A named option for a toggle parameter
struct ToggleOption: Codable, Equatable, Identifiable {
    var id: String { name }
    let name: String
    let value: Int  // CC value to send (0-127)
}

/// A single MIDI-controllable parameter on a pedal
struct ParameterDefinition: Identifiable, Codable, Equatable {
    let id: String           // unique key, e.g. "gain1"
    let name: String         // display name, e.g. "Gain 1"
    let cc: Int              // MIDI CC number
    let type: ParameterType
    let section: String      // grouping: "Knobs", "Toggles", "Dip Switches", etc.
    var defaultValue: Int    // initial value on app launch

    init(id: String, name: String, cc: Int, type: ParameterType, section: String, defaultValue: Int = 0) {
        self.id = id
        self.name = name
        self.cc = cc
        self.type = type
        self.section = section
        self.defaultValue = defaultValue
    }
}

/// Defines a pedal model — its name, manufacturer, and all controllable parameters
struct PedalDefinition: Identifiable, Equatable {
    let id: String               // e.g. "brothers-am"
    let name: String             // e.g. "Brothers AM"
    let manufacturer: String     // e.g. "Chase Bliss"
    let defaultChannel: Int      // 1-16 (user-facing), stored as-is
    let parameters: [ParameterDefinition]

    /// Parameters grouped by section, preserving definition order
    var sections: [(name: String, parameters: [ParameterDefinition])] {
        var order: [String] = []
        var groups: [String: [ParameterDefinition]] = [:]
        for param in parameters {
            if groups[param.section] == nil {
                order.append(param.section)
            }
            groups[param.section, default: []].append(param)
        }
        return order.map { (name: $0, parameters: groups[$0]!) }
    }

    /// Look up a parameter by its string ID
    func parameter(byId id: String) -> ParameterDefinition? {
        parameters.first { $0.id == id }
    }

    static func == (lhs: PedalDefinition, rhs: PedalDefinition) -> Bool {
        lhs.id == rhs.id
    }
}
