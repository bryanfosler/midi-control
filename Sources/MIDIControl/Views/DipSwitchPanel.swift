import SwiftUI

/// Collapsible panel that lives ABOVE the pedal enclosure showing the dip switches.
/// On real Chase Bliss pedals, dip switches are on the side and not visible from above,
/// so this panel represents that "hidden side panel" concept.
struct DipSwitchPanel: View {
    @ObservedObject var viewModel: PedalViewModel
    let layout: PedalLayout
    let theme: PedalColorTheme

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            if isExpanded {
                Divider()
                    .background(theme.labelColor.opacity(0.15))
                    .padding(.horizontal, 10)
                dipContent
            }
        }
        .background(panelBackground)
        .frame(width: PedalEnclosure.enclosureWidth)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 10))
                Text("DIP SWITCHES")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                Text("— side panel")
                    .font(.system(size: 9))
                    .foregroundStyle(theme.labelColor.opacity(0.45))
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(theme.labelColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dip Switch Content

    private var dipContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<layout.dipBanks.count, id: \.self) { i in
                let bank = layout.dipBanks[i]
                VStack(alignment: .leading, spacing: 4) {
                    Text(bank.label.uppercased())
                        .font(.system(size: 7.5, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(theme.labelColor.opacity(0.55))

                    let params = bank.paramIds.compactMap {
                        viewModel.definition.parameter(byId: $0)
                    }
                    DipSwitchBank(
                        parameters: params,
                        values: $viewModel.state.values,
                        onChange: { param, value in viewModel.setValue(value, for: param) },
                        theme: theme,
                        pedalId: viewModel.definition.id
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Background

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(theme.backgroundGradient[0].opacity(0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(theme.labelColor.opacity(0.18), lineWidth: 1)
            )
    }
}
