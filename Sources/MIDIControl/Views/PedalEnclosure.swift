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
                            let indicatorColor: Color? = viewModel.definition.id == "mood-mkii"
                                ? moodIndicatorColors[paramId]
                                : nil
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
                    ToggleSwitch3Way(
                        parameter: param,
                        options: options,
                        value: bindingForParam(param),
                        onChange: { val in viewModel.setValue(val, for: param) },
                        theme: theme,
                        pedalId: viewModel.definition.id
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

    // Brothers AM: channel badges "2" (pink, left) and "1" (gold, right)
    private var brothersFootswitchSection: some View {
        VStack(spacing: 6) {
            ledDotRow
            HStack(spacing: 0) {
                Spacer()
                // Ch2 (left footswitch)
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
                // Center K logo
                cbLogo
                Spacer()
                // Ch1 (right footswitch)
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

    // MOOD MK2: droplet icon (left = loop) and moon icon (right = wet)
    private var moodFootswitchSection: some View {
        VStack(spacing: 6) {
            ledDotRow
            HStack(spacing: 0) {
                Spacer()
                // Loop bypass (left = droplet)
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
                // Center K logo
                cbLogo
                Spacer()
                // Wet bypass (right = crescent moon)
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

    /// Three mini LED housings matching the physical pedal row
    private var ledDotRow: some View {
        HStack(spacing: 18) {
            ForEach(0..<3, id: \.self) { _ in
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.70))
                        .frame(width: 9, height: 9)
                    Circle()
                        .strokeBorder(Color(white: 0.28), lineWidth: 0.5)
                        .frame(width: 9, height: 9)
                }
            }
        }
    }

    /// Chase Bliss logo — stylized "K" with descending arrow
    private var cbLogo: some View {
        VStack(spacing: 3) {
            // Small center button (rubber stomp)
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.75))
                    .frame(width: 14, height: 14)
                Circle()
                    .strokeBorder(Color(white: 0.30), lineWidth: 0.5)
                    .frame(width: 14, height: 14)
            }
            // K logo text approximation
            Text("K")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.28))
        }
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
// Horizontal warm color bands (gold → orange → deep red) with large "MOOD MKii" text
// and a white rising-sun half-circle — matches the CB Presets app render

private struct MoodBrand: View {
    var body: some View {
        ZStack {
            // ── Color bands (full width) ──
            VStack(spacing: 0) {
                // Gold top band
                Color(red: 0.97, green: 0.82, blue: 0.30)
                    .frame(height: 10)
                // Orange mid band
                Color(red: 0.92, green: 0.50, blue: 0.14)
                    .frame(height: 14)
                // Deep red lower band
                Color(red: 0.72, green: 0.16, blue: 0.12)
                    .frame(height: 12)
                // Fades into body — very dark red
                Color(red: 0.40, green: 0.08, blue: 0.08)
                    .frame(height: 8)
            }

            // ── White half-circle (rising sun, sits at bottom center) ──
            Circle()
                .fill(Color.white.opacity(0.88))
                .frame(width: 38, height: 38)
                .offset(y: 20)   // push bottom half below the brand section
                .clipped()

            // ── "MOOD" text ──
            HStack(alignment: .center) {
                Text("MOOD")
                    .font(.system(size: 44, weight: .black))
                    .italic()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.80, blue: 0.25),
                                Color(red: 0.88, green: 0.42, blue: 0.10),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                    .padding(.leading, 14)

                Spacer()

                // "MKii" in upper-right
                VStack {
                    Text("MKii")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.28))
                        .shadow(color: .black.opacity(0.40), radius: 1)
                    Spacer()
                }
                .padding(.trailing, 14)
                .padding(.top, 4)
            }
        }
        .frame(height: 54)
        .clipped()
    }
}

// MARK: - Brothers Brand Section
// Deep purple body, large white "Brothers" serif + prominent gold AM starburst badge

private struct BrothersBrand: View {
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Spacer(minLength: 12)

            // "Brothers" — large white bold/italic
            Text("Brothers")
                .font(.system(size: 30, weight: .black, design: .serif))
                .italic()
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.50), radius: 3, y: 2)

            // "AM" starburst badge
            AMBadge()

            Spacer(minLength: 12)
        }
        .frame(height: 60)
    }
}

/// Gold spiky starburst badge with "AM" text — matches the Chase Bliss Brothers AM branding
private struct AMBadge: View {
    private let spikes = 20
    private let outerR: CGFloat = 18
    private let innerR: CGFloat = 13

    var body: some View {
        ZStack {
            // Spiky starburst shape
            StarburstShape(spikes: spikes, outerRadius: outerR, innerRadius: innerR)
                .fill(Color(red: 0.96, green: 0.74, blue: 0.18))
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)

            // Inner circle
            Circle()
                .fill(Color(red: 0.92, green: 0.66, blue: 0.12))
                .frame(width: innerR * 2 - 2, height: innerR * 2 - 2)

            // "AM" text
            Text("AM")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(Color(red: 0.22, green: 0.05, blue: 0.20))
        }
        .frame(width: outerR * 2 + 2, height: outerR * 2 + 2)
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
