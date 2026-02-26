import Foundation

/// Value-to-label maps for stepped/discrete knob parameters
/// Used to display meaningful labels instead of raw CC values
enum ParameterTooltips {
    /// Look up a human-readable label for a parameter value, if one exists
    static func label(for paramId: String, value: Int) -> String? {
        guard let map = tooltips[paramId] else { return nil }
        // For mapped values, find the closest key
        if let exact = map[value] { return exact }
        // Find the nearest key
        let sorted = map.keys.sorted()
        guard !sorted.isEmpty else { return nil }
        let closest = sorted.min(by: { abs($0 - value) < abs($1 - value) })!
        return map[closest]
    }

    // MARK: - MOOD MKII tooltips

    private static let tooltips: [String: [Int: String]] = [
        // CC 25 — Ramping Waveform (ranges per manual: Sine=0-14, Triangle=15-54, Ramp=55-80, Square=81-126, Random=127)
        "ramping_waveform": [
            7:   "Sine",
            34:  "Triangle",
            67:  "Ramp",
            103: "Square",
            127: "Random",
        ],
        // CC 14 — Time (when synced, these are musical divisions)
        "clock_div_wet": [
            0: "1/32",
            18: "1/16T",
            36: "1/16",
            54: "1/8T",
            72: "1/8",
            90: "1/4T",
            108: "1/4",
            127: "1/2",
        ],
        "clock_div_loop": [
            0: "1/32",
            18: "1/16T",
            36: "1/16",
            54: "1/8T",
            72: "1/8",
            90: "1/4T",
            108: "1/4",
            127: "1/2",
        ],
        // CC 58 — Synth Output Type (Open=0, On/Off=1, ADSR=2-127)
        "synth_output": [
            0:  "Open",
            1:  "On/Off",
            64: "ADSR",
        ],
    ]
}
