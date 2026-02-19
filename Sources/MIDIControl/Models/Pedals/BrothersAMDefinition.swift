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
                    ToggleOption(name: "OD", value: 2),
                    ToggleOption(name: "Dist", value: 3),
                ]),
                section: "Toggles"
            ),
            ParameterDefinition(
                id: "trebleboost", name: "Treble Boost", cc: 22,
                type: .toggle(options: [
                    ToggleOption(name: "Full Sun", value: 0),
                    ToggleOption(name: "Off", value: 2),
                    ToggleOption(name: "Half Sun", value: 3),
                ]),
                section: "Toggles"
            ),
            ParameterDefinition(
                id: "gain1type", name: "Gain 1 Type", cc: 23,
                type: .toggle(options: [
                    ToggleOption(name: "Dist", value: 0),
                    ToggleOption(name: "OD", value: 2),
                    ToggleOption(name: "Boost", value: 3),
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

            // MARK: - Dip Switches Left Bank (CC 61-68) — Channel 1 settings
            ParameterDefinition(
                id: "dip_l1", name: "Hi Gain 1", cc: 61,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l2", name: "Tone Scoop 1", cc: 62,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l3", name: "Bright 1", cc: 63,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l4", name: "Comp 1", cc: 64,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l5", name: "Hi Gain 2", cc: 65,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l6", name: "Tone Scoop 2", cc: 66,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l7", name: "Bright 2", cc: 67,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l8", name: "Comp 2", cc: 68,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),

            // MARK: - Dip Switches Right Bank (CC 71-77) — Global settings
            ParameterDefinition(
                id: "dip_r1", name: "Order", cc: 71,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r2", name: "Parallel", cc: 72,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r3", name: "Master", cc: 73,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r4", name: "Bypass", cc: 74,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r5", name: "Last MIDI", cc: 75,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r6", name: "Exp Assign", cc: 76,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r7", name: "Preset", cc: 77,
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
