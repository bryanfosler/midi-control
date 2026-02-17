import Foundation

/// Chase Bliss Brothers AM pedal definition — CC mapping from official MIDI manual
extension PedalDefinition {
    static let brothersAM = PedalDefinition(
        id: "brothers-am",
        name: "Brothers AM",
        manufacturer: "Chase Bliss",
        defaultChannel: 2,
        parameters: [
            // MARK: - Knobs
            ParameterDefinition(
                id: "gain2", name: "Gain 2", cc: 14,
                type: .knob, section: "Knobs"
            ),
            ParameterDefinition(
                id: "volume2", name: "Volume 2", cc: 15,
                type: .knob, section: "Knobs", defaultValue: 100
            ),
            ParameterDefinition(
                id: "gain1", name: "Gain 1", cc: 16,
                type: .knob, section: "Knobs"
            ),
            ParameterDefinition(
                id: "tone2", name: "Tone 2", cc: 17,
                type: .knob, section: "Knobs", defaultValue: 64
            ),
            ParameterDefinition(
                id: "volume1", name: "Volume 1", cc: 18,
                type: .knob, section: "Knobs", defaultValue: 100
            ),
            ParameterDefinition(
                id: "tone1", name: "Tone 1", cc: 19,
                type: .knob, section: "Knobs", defaultValue: 64
            ),
            ParameterDefinition(
                id: "presence2", name: "Presence 2", cc: 27,
                type: .knob, section: "Knobs", defaultValue: 64
            ),
            ParameterDefinition(
                id: "presence1", name: "Presence 1", cc: 29,
                type: .knob, section: "Knobs", defaultValue: 64
            ),

            // MARK: - Toggles
            ParameterDefinition(
                id: "gain2type", name: "Gain 2 Type", cc: 21,
                type: .toggle(options: [
                    ToggleOption(name: "Boost", value: 0),
                    ToggleOption(name: "Drive", value: 64),
                    ToggleOption(name: "Fuzz", value: 127),
                ]),
                section: "Toggles"
            ),
            ParameterDefinition(
                id: "trebleboost", name: "Treble Boost", cc: 22,
                type: .toggle(options: [
                    ToggleOption(name: "Off", value: 0),
                    ToggleOption(name: "On", value: 127),
                ]),
                section: "Toggles"
            ),
            ParameterDefinition(
                id: "gain1type", name: "Gain 1 Type", cc: 23,
                type: .toggle(options: [
                    ToggleOption(name: "Boost", value: 0),
                    ToggleOption(name: "Drive", value: 64),
                    ToggleOption(name: "Fuzz", value: 127),
                ]),
                section: "Toggles"
            ),

            // MARK: - Footswitches
            ParameterDefinition(
                id: "ch1bypass", name: "Ch 1 Bypass", cc: 102,
                type: .footswitch, section: "Footswitches"
            ),
            ParameterDefinition(
                id: "ch2bypass", name: "Ch 2 Bypass", cc: 103,
                type: .footswitch, section: "Footswitches"
            ),

            // MARK: - Expression
            ParameterDefinition(
                id: "expression", name: "Expression", cc: 100,
                type: .knob, section: "Expression"
            ),

            // MARK: - Dip Switches Left Bank (CC 61-68)
            ParameterDefinition(
                id: "dip_l1", name: "Dip L1", cc: 61,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l2", name: "Dip L2", cc: 62,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l3", name: "Dip L3", cc: 63,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l4", name: "Dip L4", cc: 64,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l5", name: "Dip L5", cc: 65,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l6", name: "Dip L6", cc: 66,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l7", name: "Dip L7", cc: 67,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l8", name: "Dip L8", cc: 68,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),

            // MARK: - Dip Switches Right Bank (CC 71-77)
            ParameterDefinition(
                id: "dip_r1", name: "Dip R1", cc: 71,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r2", name: "Dip R2", cc: 72,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r3", name: "Dip R3", cc: 73,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r4", name: "Dip R4", cc: 74,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r5", name: "Dip R5", cc: 75,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r6", name: "Dip R6", cc: 76,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r7", name: "Dip R7", cc: 77,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),

            // MARK: - Utility
            ParameterDefinition(
                id: "presetsave", name: "Preset Save", cc: 111,
                type: .footswitch, section: "Utility"
            ),
        ]
    )
}
