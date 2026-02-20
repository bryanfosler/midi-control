import SwiftUI

struct PedalColorTheme {
    let backgroundGradient: [Color]
    let labelColor: Color
    let knobColor: Color
    let knobIndicatorColor: Color
    let switchColor: Color
    let dipOnColor: Color
    let dipOffColor: Color
    let footswitchColor: Color
    let ledActiveColor: Color
    let ledInactiveColor: Color
    let sectionHeaderColor: Color
    let outerBorderColor: Color

    // MARK: - MOOD MKII
    // Deep purple body, white outer border, warm indicator lines
    static let moodMKII = PedalColorTheme(
        backgroundGradient: [
            Color(red: 0.34, green: 0.07, blue: 0.20),  // warm maroon/burgundy
            Color(red: 0.27, green: 0.05, blue: 0.15),  // slightly darker at bottom
        ],
        labelColor: Color(red: 0.96, green: 0.78, blue: 0.35),  // warm amber — matches iOS reference
        knobColor: Color(red: 0.18, green: 0.04, blue: 0.10),   // very dark maroon (darker than body)
        knobIndicatorColor: Color(red: 1.0, green: 0.55, blue: 0.22),  // warm amber
        switchColor: Color(white: 0.35),
        dipOnColor: Color(red: 0.95, green: 0.65, blue: 0.25),
        dipOffColor: Color(white: 0.22),
        footswitchColor: Color(white: 0.82),
        ledActiveColor: Color(red: 0.95, green: 0.60, blue: 0.15),
        ledInactiveColor: Color(white: 0.18),
        sectionHeaderColor: .white.opacity(0.65),
        outerBorderColor: Color(white: 0.92)  // white border — iconic MOOD look
    )

    // MARK: - Brothers AM
    // Deep purple/plum body (real pedal is NOT cream), dark maroon knobs, gold accents
    static let brothersAM = PedalColorTheme(
        backgroundGradient: [
            Color(red: 0.38, green: 0.10, blue: 0.36),  // deep plum
            Color(red: 0.33, green: 0.08, blue: 0.31),  // slightly darker
        ],
        labelColor: .white,
        knobColor: Color(red: 0.30, green: 0.07, blue: 0.15),  // dark maroon
        knobIndicatorColor: Color(red: 1.0, green: 0.75, blue: 0.35),  // gold
        switchColor: Color(white: 0.35),
        dipOnColor: Color(red: 1.0, green: 0.75, blue: 0.30),
        dipOffColor: Color(white: 0.22),
        footswitchColor: Color(white: 0.82),
        ledActiveColor: Color(red: 0.95, green: 0.70, blue: 0.20),
        ledInactiveColor: Color(white: 0.18),
        sectionHeaderColor: .white.opacity(0.65),
        outerBorderColor: Color(white: 0.30)  // subtle dark border
    )

    static func theme(for pedalId: String) -> PedalColorTheme {
        switch pedalId {
        case "mood-mkii":   return .moodMKII
        case "brothers-am": return .brothersAM
        default:            return .brothersAM
        }
    }
}
