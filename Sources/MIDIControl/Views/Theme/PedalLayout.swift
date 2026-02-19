import Foundation

/// Maps parameter IDs to physical positions on the pedal face, matching hardware layout
struct PedalLayout {
    /// Parameter IDs for the toggle row (top of pedal)
    let toggleRow: [String]

    /// Knob rows — each is an array of parameter IDs, laid out left-to-right
    let knobRows: [[String]]

    /// Dip switch banks — each bank is (label, [parameter IDs])
    let dipBanks: [(label: String, paramIds: [String])]

    /// Footswitch parameter IDs (left-to-right)
    let footswitches: [String]

    /// Parameter IDs that appear on the pedal face (derived from above)
    var faceParameterIds: Set<String> {
        var ids = Set<String>()
        ids.formUnion(toggleRow)
        for row in knobRows { ids.formUnion(row) }
        for bank in dipBanks { ids.formUnion(bank.paramIds) }
        ids.formUnion(footswitches)
        return ids
    }

    // MARK: - Pedal Layouts

    /// MOOD MKII: 3+3 knob layout matching physical pedal, toggles below knobs
    static let moodMKII = PedalLayout(
        toggleRow: ["wet_channel", "routing", "micro_looper"],
        knobRows: [
            ["time", "mix", "length"],           // top row: Time | Mix | Length
            ["modify_wet", "clock", "modify_loop"], // bottom row: Modify | Clock | Modify
        ],
        dipBanks: [
            (label: "Left (Wet)", paramIds: ["dip_l1", "dip_l2", "dip_l3", "dip_l4", "dip_l5", "dip_l6", "dip_l7", "dip_l8"]),
            (label: "Right (Loop)", paramIds: ["dip_r1", "dip_r2", "dip_r3", "dip_r4", "dip_r5", "dip_r6", "dip_r7", "dip_r8"]),
        ],
        footswitches: ["loop_bypass", "wet_bypass"]
    )

    /// Brothers AM: 3+3 knob layout matching physical pedal, toggles below knobs
    static let brothersAM = PedalLayout(
        toggleRow: ["gain1type", "trebleboost", "gain2type"],
        knobRows: [
            ["gain2", "volume2", "gain1"],  // top row: Gain2 | Vol2 | Gain1
            ["tone2", "volume1", "tone1"],  // bottom row: Tone2 | Vol1 | Tone1
        ],
        dipBanks: [
            (label: "Left (Channels)", paramIds: ["dip_l1", "dip_l2", "dip_l3", "dip_l4", "dip_l5", "dip_l6", "dip_l7", "dip_l8"]),
            (label: "Right (Global)", paramIds: ["dip_r1", "dip_r2", "dip_r3", "dip_r4", "dip_r5", "dip_r6", "dip_r7"]),
        ],
        footswitches: ["ch1bypass", "ch2bypass"]
    )

    /// Look up layout by pedal definition ID
    static func layout(for pedalId: String) -> PedalLayout {
        switch pedalId {
        case "mood-mkii": return .moodMKII
        case "brothers-am": return .brothersAM
        default: return .brothersAM
        }
    }
}
