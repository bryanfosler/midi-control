import Foundation

/// Chase Bliss MOOD MKII pedal definition — CC mapping from official MIDI manual
extension PedalDefinition {
    static let moodMKII = PedalDefinition(
        id: "mood-mkii",
        name: "MOOD MKII",
        manufacturer: "Chase Bliss",
        defaultChannel: 2,
        parameters: [
            // MARK: - Knobs
            ParameterDefinition(
                id: "time", name: "Time", cc: 14,
                type: .knob, section: "Knobs"
            ),
            ParameterDefinition(
                id: "mix", name: "Mix", cc: 15,
                type: .knob, section: "Knobs", defaultValue: 64
            ),
            ParameterDefinition(
                id: "length", name: "Length", cc: 16,
                type: .knob, section: "Knobs", defaultValue: 64
            ),
            ParameterDefinition(
                id: "modify_wet", name: "Modify (Wet)", cc: 17,
                type: .knob, section: "Knobs", defaultValue: 64
            ),
            ParameterDefinition(
                id: "clock", name: "Clock", cc: 18,
                type: .knob, section: "Knobs", defaultValue: 64
            ),
            ParameterDefinition(
                id: "modify_loop", name: "Modify (Loop)", cc: 19,
                type: .knob, section: "Knobs", defaultValue: 64
            ),
            ParameterDefinition(
                id: "ramp_speed", name: "Ramp Speed", cc: 20,
                type: .knob, section: "Knobs", defaultValue: 64
            ),

            // MARK: - Hidden Options
            ParameterDefinition(
                id: "stereo_width", name: "Stereo Width", cc: 24,
                type: .knob, section: "Hidden Options", defaultValue: 64
            ),
            ParameterDefinition(
                id: "ramping_waveform", name: "Ramping Waveform", cc: 25,
                type: .knob, section: "Hidden Options"
            ),
            ParameterDefinition(
                id: "fade", name: "Fade", cc: 26,
                type: .knob, section: "Hidden Options"
            ),
            ParameterDefinition(
                id: "tone", name: "Tone", cc: 27,
                type: .knob, section: "Hidden Options", defaultValue: 64
            ),
            ParameterDefinition(
                id: "level_balance", name: "Level Balance", cc: 28,
                type: .knob, section: "Hidden Options", defaultValue: 64
            ),
            ParameterDefinition(
                id: "direct_micro_loop", name: "Direct Micro-Loop", cc: 29,
                type: .knob, section: "Hidden Options"
            ),

            // MARK: - Hidden Options (toggle type)
            ParameterDefinition(
                id: "sync", name: "Sync", cc: 31,
                type: .toggle(options: [
                    ToggleOption(name: "Loop→Wet", value: 0),
                    ToggleOption(name: "Off",       value: 2),
                    ToggleOption(name: "Wet→Loop", value: 127),
                ]),
                section: "Hidden Options"
            ),
            ParameterDefinition(
                id: "spread", name: "Spread", cc: 32,
                type: .toggle(options: [
                    ToggleOption(name: "💧 Wet",  value: 0),
                    ToggleOption(name: "Both",    value: 2),
                    ToggleOption(name: "🌙 Loop", value: 127),
                ]),
                section: "Hidden Options"
            ),
            ParameterDefinition(
                id: "buffer_length", name: "Buffer Length", cc: 33,
                type: .toggle(options: [
                    ToggleOption(name: "MKI",  value: 0),
                    ToggleOption(name: "Full", value: 127),
                ]),
                section: "Hidden Options"
            ),

            // MARK: - Toggles
            ParameterDefinition(
                id: "wet_channel", name: "Wet Channel", cc: 21,
                type: .toggle(options: [
                    ToggleOption(name: "Reverb", value: 0),
                    ToggleOption(name: "Delay",  value: 2),
                    ToggleOption(name: "Slip",   value: 127),
                ]),
                section: "Toggles"
            ),
            ParameterDefinition(
                id: "routing", name: "Routing", cc: 22,
                type: .toggle(options: [
                    ToggleOption(name: "In",       value: 0),
                    ToggleOption(name: "In+Loop",  value: 2),
                    ToggleOption(name: "Loop",     value: 127),
                ]),
                section: "Toggles"
            ),
            ParameterDefinition(
                id: "micro_looper", name: "Micro-Looper", cc: 23,
                type: .toggle(options: [
                    ToggleOption(name: "ENV",     value: 0),
                    ToggleOption(name: "Tape",    value: 2),
                    ToggleOption(name: "Stretch", value: 127),
                ]),
                section: "Toggles"
            ),

            // MARK: - Footswitches
            ParameterDefinition(
                id: "loop_bypass", name: "Loop Bypass", cc: 102,
                type: .footswitch, section: "Footswitches"
            ),
            ParameterDefinition(
                id: "wet_bypass", name: "Wet Bypass", cc: 103,
                type: .footswitch, section: "Footswitches"
            ),
            ParameterDefinition(
                id: "hidden_menu", name: "Hidden Menu", cc: 104,
                type: .footswitch, section: "Footswitches"
            ),
            ParameterDefinition(
                id: "freeze", name: "Freeze", cc: 105,
                type: .footswitch, section: "Footswitches"
            ),
            ParameterDefinition(
                id: "overdub", name: "Overdub", cc: 106,
                type: .footswitch, section: "Footswitches"
            ),
            ParameterDefinition(
                id: "tap_tempo", name: "Tap Tempo", cc: 93,
                type: .footswitch, section: "Footswitches"
            ),

            // MARK: - Misc Controls
            ParameterDefinition(
                id: "midi_clock_ignore", name: "MIDI Clock Ignore", cc: 51,
                type: .toggle(options: [
                    ToggleOption(name: "Listen", value: 0),
                    ToggleOption(name: "Ignore", value: 127),
                ]),
                section: "Misc"
            ),
            ParameterDefinition(
                id: "stop_ramping", name: "Stop Ramping", cc: 52,
                type: .footswitch, section: "Misc"
            ),
            ParameterDefinition(
                id: "clock_div_wet", name: "Clock Div (Wet)", cc: 53,
                type: .toggle(options: [
                    ToggleOption(name: "1/32",  value: 0),
                    ToggleOption(name: "1/16T", value: 18),
                    ToggleOption(name: "1/16",  value: 36),
                    ToggleOption(name: "1/8T",  value: 54),
                    ToggleOption(name: "1/8",   value: 72),
                    ToggleOption(name: "1/4T",  value: 90),
                    ToggleOption(name: "1/4",   value: 108),
                    ToggleOption(name: "1/2",   value: 127),
                ]),
                section: "Misc"
            ),
            ParameterDefinition(
                id: "clock_div_loop", name: "Clock Div (Loop)", cc: 54,
                type: .toggle(options: [
                    ToggleOption(name: "1/32",  value: 0),
                    ToggleOption(name: "1/16T", value: 18),
                    ToggleOption(name: "1/16",  value: 36),
                    ToggleOption(name: "1/8T",  value: 54),
                    ToggleOption(name: "1/8",   value: 72),
                    ToggleOption(name: "1/4T",  value: 90),
                    ToggleOption(name: "1/4",   value: 108),
                    ToggleOption(name: "1/2",   value: 127),
                ]),
                section: "Misc"
            ),
            ParameterDefinition(
                id: "true_bypass", name: "True Bypass", cc: 55,
                type: .toggle(options: [
                    ToggleOption(name: "Buffered", value: 0),
                    ToggleOption(name: "True",     value: 127),
                ]),
                section: "Misc"
            ),

            // MARK: - Synth Mode
            ParameterDefinition(
                id: "synth_exit", name: "Exit Synth Mode", cc: 59,
                type: .footswitch, section: "Synth Mode"
            ),
            ParameterDefinition(
                id: "synth_output", name: "Output Type", cc: 58,
                type: .toggle(options: [
                    ToggleOption(name: "Open",   value: 0),
                    ToggleOption(name: "On/Off", value: 1),
                    ToggleOption(name: "ADSR",   value: 64),
                ]),
                section: "Synth Mode"
            ),
            ParameterDefinition(
                id: "synth_attack", name: "Attack", cc: 80,
                type: .knob, section: "Synth Mode"
            ),
            ParameterDefinition(
                id: "synth_decay", name: "Decay", cc: 81,
                type: .knob, section: "Synth Mode"
            ),
            ParameterDefinition(
                id: "synth_sustain", name: "Sustain", cc: 82,
                type: .knob, section: "Synth Mode", defaultValue: 100
            ),
            ParameterDefinition(
                id: "synth_release", name: "Release", cc: 83,
                type: .knob, section: "Synth Mode"
            ),
            ParameterDefinition(
                id: "synth_octave", name: "Octave Transpose", cc: 57,
                type: .toggle(options: [
                    ToggleOption(name: "-4", value: 0),
                    ToggleOption(name: "-3", value: 16),
                    ToggleOption(name: "-2", value: 32),
                    ToggleOption(name: "-1", value: 48),
                    ToggleOption(name: " 0", value: 64),
                    ToggleOption(name: "+1", value: 79),
                    ToggleOption(name: "+2", value: 95),
                    ToggleOption(name: "+3", value: 111),
                    ToggleOption(name: "+4", value: 127),
                ]),
                section: "Synth Mode", defaultValue: 64
            ),
            ParameterDefinition(
                id: "synth_portamento", name: "Portamento", cc: 84,
                type: .knob, section: "Synth Mode"
            ),

            // MARK: - Expression
            ParameterDefinition(
                id: "mod_wheel", name: "Mod Wheel", cc: 1,
                type: .knob, section: "Expression"
            ),
            ParameterDefinition(
                id: "expression", name: "Expression", cc: 100,
                type: .knob, section: "Expression"
            ),

            // MARK: - Dip Switches Left Bank (CC 61-68) — Ramping/Expression assignment
            ParameterDefinition(
                id: "dip_l1", name: "Time", cc: 61,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l2", name: "♦ Modify", cc: 62,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l3", name: "Clock", cc: 63,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l4", name: "○ Modify", cc: 64,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l5", name: "Length", cc: 65,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l6", name: "Bounce", cc: 66,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l7", name: "Sweep", cc: 67,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),
            ParameterDefinition(
                id: "dip_l8", name: "Polarity", cc: 68,
                type: .dipSwitch, section: "Dip Switches - Left"
            ),

            // MARK: - Dip Switches Right Bank (CC 71-78) — Loop channel
            ParameterDefinition(
                id: "dip_r1", name: "Time", cc: 71,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r2", name: "Mix", cc: 72,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r3", name: "Length", cc: 73,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r4", name: "Mod Wet", cc: 74,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r5", name: "Clock", cc: 75,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r6", name: "Mod Loop", cc: 76,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r7", name: "Bounce", cc: 77,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),
            ParameterDefinition(
                id: "dip_r8", name: "Ramp", cc: 78,
                type: .dipSwitch, section: "Dip Switches - Right"
            ),

            // MARK: - Utility
            ParameterDefinition(
                id: "midi_reset", name: "MIDI Reset", cc: 110,
                type: .footswitch, section: "Utility"
            ),
            ParameterDefinition(
                id: "presetsave", name: "Preset Save", cc: 111,
                type: .footswitch, section: "Utility"
            ),

            // MARK: - Factory Reset (isolated at the bottom)
            ParameterDefinition(
                id: "factory_reset", name: "Factory Reset", cc: 56,
                type: .footswitch, section: "⚠ Factory Reset"
            ),
        ]
    )
}
