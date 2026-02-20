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
                type: .knob, section: "Knobs", defaultValue: 0
            ),
            ParameterDefinition(
                id: "presence1", name: "Presence 1", cc: 29,
                type: .knob, section: "Knobs", defaultValue: 0
            ),

            // MARK: - Toggles
            ParameterDefinition(
                id: "gain2type", name: "Gain 2 Type", cc: 21,
                type: .toggle(options: [
                    ToggleOption(name: "Boost", value: 0),
                    ToggleOption(name: "OD",    value: 2),
                    ToggleOption(name: "Dist",  value: 3),
                ]),
                section: "Toggles"
            ),
            ParameterDefinition(
                id: "trebleboost", name: "Treble Boost", cc: 22,
                type: .toggle(options: [
                    ToggleOption(name: "☀",  value: 0),
                    ToggleOption(name: "Off", value: 2),
                    ToggleOption(name: "○",  value: 3),
                ]),
                section: "Toggles"
            ),
            ParameterDefinition(
                id: "gain1type", name: "Gain 1 Type", cc: 23,
                type: .toggle(options: [
                    ToggleOption(name: "Dist",  value: 0),
                    ToggleOption(name: "OD",    value: 2),
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

            // MARK: - Dip Switches Left Bank (CC 61–68) — CONTROL
            // These select which knobs respond to expression / CV / MIDI ramping
            ParameterDefinition(
                id: "dip_vol1", name: "Vol 1", cc: 61,
                type: .dipSwitch, section: "Dip Switches - Control"
            ),
            ParameterDefinition(
                id: "dip_vol2", name: "Vol 2", cc: 62,
                type: .dipSwitch, section: "Dip Switches - Control"
            ),
            ParameterDefinition(
                id: "dip_gain1", name: "Gain 1", cc: 63,
                type: .dipSwitch, section: "Dip Switches - Control"
            ),
            ParameterDefinition(
                id: "dip_gain2", name: "Gain 2", cc: 64,
                type: .dipSwitch, section: "Dip Switches - Control"
            ),
            ParameterDefinition(
                id: "dip_tone1", name: "Tone 1", cc: 65,
                type: .dipSwitch, section: "Dip Switches - Control"
            ),
            ParameterDefinition(
                id: "dip_tone2", name: "Tone 2", cc: 66,
                type: .dipSwitch, section: "Dip Switches - Control"
            ),
            ParameterDefinition(
                id: "dip_sweep", name: "Sweep", cc: 67,
                type: .dipSwitch, section: "Dip Switches - Control"
            ),
            ParameterDefinition(
                id: "dip_polarity", name: "Polarity", cc: 68,
                type: .dipSwitch, section: "Dip Switches - Control"
            ),

            // MARK: - Dip Switches Right Bank (CC 71–78) — CUSTOMIZE
            // These engage alternate behaviors and features
            ParameterDefinition(
                id: "dip_hi_gain_1", name: "Hi Gain 1", cc: 71,
                type: .dipSwitch, section: "Dip Switches - Customize"
            ),
            ParameterDefinition(
                id: "dip_hi_gain_2", name: "Hi Gain 2", cc: 72,
                type: .dipSwitch, section: "Dip Switches - Customize"
            ),
            ParameterDefinition(
                id: "dip_motobyp_1", name: "Motobyp 1", cc: 73,
                type: .dipSwitch, section: "Dip Switches - Customize"
            ),
            ParameterDefinition(
                id: "dip_motobyp_2", name: "Motobyp 2", cc: 74,
                type: .dipSwitch, section: "Dip Switches - Customize"
            ),
            ParameterDefinition(
                id: "dip_pres_link_1", name: "Pres Link 1", cc: 75,
                type: .dipSwitch, section: "Dip Switches - Customize"
            ),
            ParameterDefinition(
                id: "dip_pres_link_2", name: "Pres Link 2", cc: 76,
                type: .dipSwitch, section: "Dip Switches - Customize"
            ),
            ParameterDefinition(
                id: "dip_master", name: "Master", cc: 77,
                type: .dipSwitch, section: "Dip Switches - Customize"
            ),
            ParameterDefinition(
                id: "dip_bank", name: "Bank", cc: 78,
                type: .dipSwitch, section: "Dip Switches - Customize"
            ),

            // MARK: - Utility
            ParameterDefinition(
                id: "presetsave", name: "Preset Save", cc: 111,
                type: .footswitch, section: "Utility"
            ),
        ]
    )
}
