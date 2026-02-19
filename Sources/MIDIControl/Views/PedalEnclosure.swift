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

    var body: some View {
        ZStack(alignment: .top) {
            EnclosureShell(theme: theme)

            VStack(spacing: 0) {
                // Small top margin
                Spacer().frame(height: 14)

                // ── Knob rows (2 rows of 3, matching physical pedal) ──
                knobRows
                    .padding(.horizontal, 10)

                Spacer(minLength: 8)

                thinRule

                // ── Toggle row (below knobs, as on the real pedal) ──
                if !layout.toggleRow.isEmpty {
                    toggleRow
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                }

                thinRule

                // ── Brand section (pedal-specific graphic) ──
                brandSection

                thinRule

                // ── Footswitches ──
                footswitchRow
                    .padding(.vertical, 12)

                Spacer(minLength: 8)
            }
        }
        .frame(width: Self.enclosureWidth, height: Self.enclosureHeight)
    }

    // MARK: - Knob Rows

    private var knobRows: some View {
        VStack(spacing: 12) {
            ForEach(layout.knobRows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ForEach(layout.knobRows[rowIndex], id: \.self) { paramId in
                        if let param = viewModel.definition.parameter(byId: paramId) {
                            RotaryKnob(
                                parameter: param,
                                value: bindingForParam(param),
                                onChange: { val in viewModel.setValue(val, for: param) },
                                theme: theme,
                                pedalId: viewModel.definition.id
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

    // MARK: - Footswitch Row

    private var footswitchRow: some View {
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
            // Body fill
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(
                    colors: theme.backgroundGradient,
                    startPoint: .top,
                    endPoint: .bottom
                ))

            // Outer colored border (white for MOOD, dark for Brothers)
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(theme.outerBorderColor, lineWidth: 5)

            // Inner light highlight along top edge
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

            // Corner screws
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
// Horizontal amber/yellow color bands with large "MOOD MKii" text — iconic Chase Bliss look

private struct MoodBrand: View {
    var body: some View {
        ZStack {
            // Color bands
            VStack(spacing: 0) {
                Color(red: 0.85, green: 0.44, blue: 0.12)  // deep amber
                    .frame(height: 22)
                Color(red: 0.96, green: 0.72, blue: 0.28)  // warm yellow
                    .frame(height: 20)
                Color(red: 0.78, green: 0.32, blue: 0.08)  // darker amber base
                    .frame(height: 10)
            }
            .clipShape(Rectangle())

            // "MOOD" + "MKii" overlay
            HStack(alignment: .center, spacing: 0) {
                Text("MOOD")
                    .font(.system(size: 40, weight: .black, design: .default))
                    .italic()
                    .foregroundStyle(Color(red: 0.30, green: 0.07, blue: 0.26))
                    .shadow(color: .black.opacity(0.15), radius: 1)
                    .padding(.leading, 16)

                Spacer()

                // White circle accent (top of the circle sits in the band)
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 38, height: 38)
                    .offset(y: 10)

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text("MKii")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.30, green: 0.07, blue: 0.26))
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 52)
        .clipped()
    }
}

// MARK: - Brothers Brand Section
// Dark purple background, large "Brothers" serif + gold "AM" sunburst badge

private struct BrothersBrand: View {
    var body: some View {
        ZStack {
            // Sunburst rays behind text
            ForEach(0..<16, id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.025))
                    .frame(width: 1, height: 70)
                    .rotationEffect(.degrees(Double(i) * 11.25))
            }

            HStack(alignment: .center, spacing: 10) {
                Text("Brothers")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 2)

                // "AM" sunburst badge
                ZStack {
                    // Spiky sunburst
                    ForEach(0..<12, id: \.self) { i in
                        Capsule()
                            .fill(Color(red: 1.0, green: 0.75, blue: 0.28))
                            .frame(width: 2.5, height: 11)
                            .offset(y: -14)
                            .rotationEffect(.degrees(Double(i) * 30))
                    }
                    Circle()
                        .fill(Color(red: 0.95, green: 0.68, blue: 0.18))
                        .frame(width: 22, height: 22)
                    Text("AM")
                        .font(.system(size: 7.5, weight: .black))
                        .foregroundStyle(Color(red: 0.30, green: 0.07, blue: 0.26))
                }
                .frame(width: 34, height: 34)
            }
        }
        .frame(height: 60)
    }
}
