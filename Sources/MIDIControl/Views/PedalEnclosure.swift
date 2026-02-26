import SwiftUI

/// Fixed-size pedal enclosure matching the physical Chase Bliss layout:
/// knobs → toggles → brand section → footswitches (top to bottom)
struct PedalEnclosure: View {
    @ObservedObject var viewModel: PedalViewModel
    let layout: PedalLayout
    let theme: PedalColorTheme

    @State private var bypassStates: [Int: Bool] = [:]

    static let enclosureWidth: CGFloat  = 280
    static let enclosureHeight: CGFloat = 500

    // MOOD knob indicator colors — left col = red, center = white, right = gold
    private let moodIndicatorColors: [String: Color] = [
        "time":        Color(red: 0.95, green: 0.32, blue: 0.22),
        "modify_wet":  Color(red: 0.95, green: 0.32, blue: 0.22),
        "mix":         Color.white.opacity(0.90),
        "clock":       Color.white.opacity(0.90),
        "length":      Color(red: 1.00, green: 0.78, blue: 0.25),
        "modify_loop": Color(red: 1.00, green: 0.78, blue: 0.25),
    ]

    // Brothers AM knob indicator colors — Ch2 (gain2/vol2/tone2) = red/pink, Ch1 = gold
    private let brothersIndicatorColors: [String: Color] = [
        "gain2":   Color(red: 0.95, green: 0.30, blue: 0.42),
        "volume2": Color(red: 0.95, green: 0.30, blue: 0.42),
        "tone2":   Color(red: 0.95, green: 0.30, blue: 0.42),
        "gain1":   Color(red: 1.00, green: 0.76, blue: 0.20),
        "volume1": Color(red: 1.00, green: 0.76, blue: 0.20),
        "tone1":   Color(red: 1.00, green: 0.76, blue: 0.20),
    ]

    // Brothers AM toggle bat colors — all chrome (nil = default chrome fill in ToggleSwitch3Way)

    var body: some View {
        ZStack(alignment: .top) {
            EnclosureShell(theme: theme)

            VStack(spacing: 0) {
                Spacer().frame(height: 10)

                // ── Red input strip (matches the physical top edge) ──
                inputStrip
                    .padding(.bottom, 10)

                // ── Knob rows ──
                knobRows
                    .padding(.horizontal, 10)

                Spacer(minLength: 8)

                thinRule

                // ── Toggle row ──
                if !layout.toggleRow.isEmpty {
                    toggleRow
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                }

                thinRule

                // ── Brand section ──
                brandSection

                thinRule

                // ── Footswitch section ──
                footswitchSection
            }
        }
        .frame(width: Self.enclosureWidth, height: Self.enclosureHeight)
    }

    // MARK: - Input Strip

    private var inputStrip: some View {
        HStack(spacing: 8) {
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.55, green: 0.10, blue: 0.10))
                .frame(width: 52, height: 6)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.55, green: 0.10, blue: 0.10))
                .frame(width: 52, height: 6)
            Spacer()
        }
    }

    // MARK: - Knob Rows

    private var knobRows: some View {
        VStack(spacing: 12) {
            ForEach(layout.knobRows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ForEach(layout.knobRows[rowIndex], id: \.self) { paramId in
                        if let param = viewModel.definition.parameter(byId: paramId) {
                            let indicatorColor: Color? = {
                                switch viewModel.definition.id {
                                case "mood-mkii":   return moodIndicatorColors[paramId]
                                case "brothers-am": return brothersIndicatorColors[paramId]
                                default:            return nil
                                }
                            }()
                            RotaryKnob(
                                parameter: param,
                                value: bindingForParam(param),
                                onChange: { val in viewModel.setValue(val, for: param) },
                                theme: theme,
                                pedalId: viewModel.definition.id,
                                overrideIndicatorColor: indicatorColor
                            )
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Toggle Row

    private var toggleRow: some View {
        HStack(spacing: 0) {
            Spacer()
            ForEach(layout.toggleRow, id: \.self) { paramId in
                if let param = viewModel.definition.parameter(byId: paramId),
                   case .toggle(let options) = param.type {
                    let batCol: Color? = nil  // all bats chrome
                    ToggleSwitch3WayRotating(
                        parameter: param,
                        options: options,
                        value: bindingForParam(param),
                        onChange: { val in viewModel.setValue(val, for: param) },
                        theme: theme,
                        pedalId: viewModel.definition.id,
                        batColor: batCol
                    )
                    Spacer()
                }
            }
        }
    }

    // MARK: - Brand Section

    @ViewBuilder
    private var brandSection: some View {
        switch viewModel.definition.id {
        case "mood-mkii":   MoodBrand()
        case "brothers-am": BrothersBrand()
        default:
            Text(viewModel.definition.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(theme.labelColor)
                .frame(height: 64)
        }
    }

    // MARK: - Footswitch Section

    @ViewBuilder
    private var footswitchSection: some View {
        switch viewModel.definition.id {
        case "brothers-am": brothersFootswitchSection
        case "mood-mkii":   moodFootswitchSection
        default:            defaultFootswitchSection
        }
    }

    // Brothers AM: LEDs above each footswitch reflect channel + hi-gain state.
    // Green = active  |  Red = active + HI GAIN dip on  |  nil (dark) = bypassed off
    // Numbered badges stay as static channel identifiers.
    private var brothersFootswitchSection: some View {
        let ch2Active = bypassStates[103] ?? false
        let ch2HiGain = (viewModel.state.values[72] ?? 0) > 0
        let ch2LED: Color? = ch2Active
            ? (ch2HiGain ? Color(red: 0.92, green: 0.18, blue: 0.18)  // red
                         : Color(red: 0.25, green: 0.80, blue: 0.38)) // green
            : nil

        let ch1Active = bypassStates[102] ?? false
        let ch1HiGain = (viewModel.state.values[71] ?? 0) > 0
        let ch1LED: Color? = ch1Active
            ? (ch1HiGain ? Color(red: 0.92, green: 0.18, blue: 0.18)  // red
                         : Color(red: 0.25, green: 0.80, blue: 0.38)) // green
            : nil

        return VStack(spacing: 6) {
            ledDotRow(left: ch2LED, center: nil, right: ch1LED)
            HStack(spacing: 0) {
                Spacer()
                // Ch2 (left footswitch) — static pink badge
                if let param = viewModel.definition.parameter(byId: "ch2bypass") {
                    BypassButton(
                        parameter: param,
                        isActive: Binding(
                            get: { bypassStates[param.cc] ?? false },
                            set: { bypassStates[param.cc] = $0 }
                        ),
                        onTap: { viewModel.triggerFootswitch(param) },
                        theme: theme,
                        pedalId: viewModel.definition.id,
                        badgeLabel: "2",
                        badgeColor: Color(red: 0.92, green: 0.42, blue: 0.55),
                        badgeLabelColor: .white
                    )
                }
                Spacer()
                cbLogo
                Spacer()
                // Ch1 (right footswitch) — static gold badge
                if let param = viewModel.definition.parameter(byId: "ch1bypass") {
                    BypassButton(
                        parameter: param,
                        isActive: Binding(
                            get: { bypassStates[param.cc] ?? false },
                            set: { bypassStates[param.cc] = $0 }
                        ),
                        onTap: { viewModel.triggerFootswitch(param) },
                        theme: theme,
                        pedalId: viewModel.definition.id,
                        badgeLabel: "1",
                        badgeColor: Color(red: 0.95, green: 0.72, blue: 0.18),
                        badgeLabelColor: Color(red: 0.22, green: 0.05, blue: 0.20)
                    )
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            Spacer().frame(height: 8)
        }
        .padding(.top, 10)
    }

    // MOOD MK2: LEDs reflect bypass state.
    // Loop LED (left): green when loop is active (recording or playing — app can't distinguish).
    // Wet LED (right): green when wet channel is active.
    // Center: always dark (decorative housing above the CB logo).
    private var moodFootswitchSection: some View {
        let loopLED: Color? = (bypassStates[102] ?? false)
            ? Color(red: 0.25, green: 0.80, blue: 0.38) : nil  // green or off
        let wetLED: Color? = (bypassStates[103] ?? false)
            ? Color(red: 0.25, green: 0.80, blue: 0.38) : nil  // green or off

        return VStack(spacing: 6) {
            ledDotRow(left: loopLED, center: nil, right: wetLED)
            HStack(spacing: 0) {
                Spacer()
                // Loop bypass (left = droplet icon)
                if let param = viewModel.definition.parameter(byId: "loop_bypass") {
                    BypassButton(
                        parameter: param,
                        isActive: Binding(
                            get: { bypassStates[param.cc] ?? false },
                            set: { bypassStates[param.cc] = $0 }
                        ),
                        onTap: { viewModel.triggerFootswitch(param) },
                        theme: theme,
                        pedalId: viewModel.definition.id,
                        badgeIcon: "drop.fill",
                        badgeIconColor: Color(red: 0.95, green: 0.32, blue: 0.22)
                    )
                }
                Spacer()
                cbLogo
                Spacer()
                // Wet bypass (right = crescent moon icon)
                if let param = viewModel.definition.parameter(byId: "wet_bypass") {
                    BypassButton(
                        parameter: param,
                        isActive: Binding(
                            get: { bypassStates[param.cc] ?? false },
                            set: { bypassStates[param.cc] = $0 }
                        ),
                        onTap: { viewModel.triggerFootswitch(param) },
                        theme: theme,
                        pedalId: viewModel.definition.id,
                        badgeIcon: "moon.fill",
                        badgeIconColor: Color(red: 0.95, green: 0.72, blue: 0.18)
                    )
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            Spacer().frame(height: 8)
        }
        .padding(.top, 10)
    }

    // Generic fallback footswitch row
    private var defaultFootswitchSection: some View {
        HStack(spacing: 0) {
            Spacer()
            ForEach(layout.footswitches, id: \.self) { paramId in
                if let param = viewModel.definition.parameter(byId: paramId) {
                    BypassButton(
                        parameter: param,
                        isActive: Binding(
                            get: { bypassStates[param.cc] ?? false },
                            set: { bypassStates[param.cc] = $0 }
                        ),
                        onTap: { viewModel.triggerFootswitch(param) },
                        theme: theme,
                        pedalId: viewModel.definition.id
                    )
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Shared Sub-views

    /// Three LED housings evenly spaced — one above each bottom element.
    /// Pass nil for a position to show it dark/off.
    private func ledDotRow(left: Color? = nil, center: Color? = nil, right: Color? = nil) -> some View {
        HStack(spacing: 0) {
            Spacer()
            ledDot(color: left)
            Spacer()
            ledDot(color: center)
            Spacer()
            ledDot(color: right)
            Spacer()
        }
    }

    /// Single LED housing. color=nil → dark/off; color → glowing active state.
    private func ledDot(color: Color?) -> some View {
        ZStack {
            // LED body
            Circle()
                .fill(color ?? Color.black.opacity(0.70))
                .frame(width: 9, height: 9)
            // Housing bezel
            Circle()
                .strokeBorder(Color(white: 0.28), lineWidth: 0.5)
                .frame(width: 9, height: 9)
            // Lens highlight (only when active)
            if color != nil {
                Circle()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 3.5, height: 3.5)
                    .offset(x: -1, y: -1.5)
            }
        }
        .frame(width: 9, height: 9)
        // Outer glow rendered in background so it doesn't affect layout size
        .background(
            Group {
                if let c = color {
                    Circle()
                        .fill(c.opacity(0.40))
                        .frame(width: 16, height: 16)
                        .blur(radius: 4)
                }
            }
        )
    }

    /// Chase Bliss Audio logo — circular badge with "CB" lettermark.
    /// The real CB logo is a circle containing stylized "CB" initials.
    private var cbLogo: some View {
        CBLogoMark()
    }

    // MARK: - Helpers

    private var thinRule: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 1)
            .padding(.horizontal, 18)
    }

    private func bindingForParam(_ param: ParameterDefinition) -> Binding<Int> {
        Binding(
            get: { viewModel.state.values[param.cc] ?? param.defaultValue },
            set: { viewModel.state.values[param.cc] = $0 }
        )
    }
}

// MARK: - Enclosure Shell

private struct EnclosureShell: View {
    let theme: PedalColorTheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(
                    colors: theme.backgroundGradient,
                    startPoint: .top,
                    endPoint: .bottom
                ))

            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(theme.outerBorderColor, lineWidth: 5)

            RoundedRectangle(cornerRadius: 17)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
                .padding(5)

            ScrewCorners(color: Color.white.opacity(0.30))
        }
        .shadow(color: .black.opacity(0.55), radius: 16, x: 0, y: 10)
        .shadow(color: .black.opacity(0.20), radius: 3, x: 0, y: 1)
    }
}

private struct ScrewCorners: View {
    let color: Color
    private let inset: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pts: [CGPoint] = [
                .init(x: inset,     y: inset),
                .init(x: w - inset, y: inset),
                .init(x: inset,     y: h - inset),
                .init(x: w - inset, y: h - inset),
            ]
            ForEach(pts.indices, id: \.self) { i in
                ScrewHead(color: color).position(pts[i])
            }
        }
    }
}

private struct ScrewHead: View {
    let color: Color
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.5)).frame(width: 9, height: 9)
            Rectangle().fill(color).frame(width: 5, height: 1)
            Rectangle().fill(color).frame(width: 1, height: 5)
        }
    }
}

// MARK: - MOOD Brand Section
// Sunset color bands (bright gold → orange → deep red) fill the section.
// "MOOD" is large, centered, bold italic — its gradient is BRIGHTER than the bands
// behind it so the text pops. White rising-sun half-circle anchors the bottom.

private struct MoodBrand: View {
    var body: some View {
        ZStack {
            // ── Sunset bands (full width background) ──
            VStack(spacing: 0) {
                Color(red: 0.98, green: 0.85, blue: 0.28).frame(height: 14) // bright gold
                Color(red: 0.96, green: 0.54, blue: 0.14).frame(height: 18) // vivid orange
                Color(red: 0.76, green: 0.18, blue: 0.12).frame(height: 16) // deep red
                Color(red: 0.40, green: 0.08, blue: 0.08).frame(height: 8)  // dark base
            }

            // ── White rising-sun half-circle at bottom center ──
            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 44, height: 44)
                .offset(y: 26)
                .clipped()

            // ── "MOOD" — large, centered, vivid gradient (brighter than the bands) ──
            Text("MOOD")
                .font(.system(size: 52, weight: .black))
                .italic()
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.98, blue: 0.68), // very bright gold (top)
                            Color(red: 1.00, green: 0.78, blue: 0.28), // vivid amber
                            Color(red: 0.98, green: 0.46, blue: 0.18), // vivid orange-red (bottom)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.60), radius: 3, y: 1)
                .frame(maxWidth: .infinity, alignment: .center)

            // ── "MKii" — small, bottom-right corner ──
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("MKii")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.92, blue: 0.52).opacity(0.88))
                        .shadow(color: .black.opacity(0.50), radius: 1)
                        .padding(.trailing, 10)
                        .padding(.bottom, 5)
                }
            }
        }
        .frame(height: 64)
        .clipped()
    }
}

// MARK: - Brothers Brand Section
// Deep purple body, large white "Brothers" serif + Analog Man sun badge (AM)

private struct BrothersBrand: View {
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Spacer(minLength: 8)

            // "Brothers" — large white condensed italic (matches real pedal lettering)
            Text("Brothers")
                .font(.system(size: 34, weight: .heavy))
                .italic()
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.55), radius: 3, y: 2)

            // Analog Man sun badge
            AMBadge()

            Spacer(minLength: 8)
        }
        .frame(height: 66)
    }
}

/// Analog Man sun badge — 12 pronounced rays, vivid gold, "AM" in the center circle.
/// Analog Man's logo is a classic sun, so we use fewer, more triangular rays than the
/// previous 20-spike version to better match the real badge shape.
private struct AMBadge: View {
    private let spikes = 12
    private let outerR: CGFloat = 22
    private let innerR: CGFloat = 14

    var body: some View {
        ZStack {
            // Star outline — gold stroke (not filled), clean outline look
            StarburstShape(spikes: spikes, outerRadius: outerR, innerRadius: innerR)
                .stroke(Color(red: 0.98, green: 0.80, blue: 0.15), lineWidth: 1.5)

            // Sun center circle — outline only, matches the stroked rays
            Circle()
                .strokeBorder(Color(red: 0.98, green: 0.80, blue: 0.15), lineWidth: 1.5)
                .frame(width: innerR * 2, height: innerR * 2)

            // "AM" text — gold to stay visible against the hollow center
            Text("AM")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(Color(red: 0.98, green: 0.80, blue: 0.15))
        }
        .frame(width: outerR * 2 + 4, height: outerR * 2 + 4)
    }
}

private struct StarburstShape: Shape {
    let spikes: Int
    let outerRadius: CGFloat
    let innerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        let angleStep = (2.0 * .pi) / Double(spikes)

        for i in 0..<spikes {
            let outerAngle = Double(i) * angleStep - .pi / 2
            let innerAngle = outerAngle + angleStep / 2

            let outer = CGPoint(
                x: center.x + outerRadius * CGFloat(cos(outerAngle)),
                y: center.y + outerRadius * CGFloat(sin(outerAngle))
            )
            let inner = CGPoint(
                x: center.x + innerRadius * CGFloat(cos(innerAngle)),
                y: center.y + innerRadius * CGFloat(sin(innerAngle))
            )

            if i == 0 {
                path.move(to: outer)
            } else {
                path.addLine(to: outer)
            }
            path.addLine(to: inner)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Chase Bliss Audio Logo Mark
//
// The CB logo: a thin circle ring with "CB" text centered inside.
// Rendered at ~26pt to fit comfortably between the two footswitches.

private struct CBLogoMark: View {
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.50), Color.white.opacity(0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
                .frame(width: 26, height: 26)

            // "CB" initials — tight tracking, condensed weight
            Text("CB")
                .font(.system(size: 9, weight: .bold, design: .default))
                .tracking(0.5)
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .frame(width: 26, height: 26)
    }
}
