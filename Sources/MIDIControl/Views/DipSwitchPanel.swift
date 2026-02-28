import SwiftUI

/// Collapsible panel showing the dip switches for a pedal.
/// Uses the same skeuomorphic DipSwitchBank on all platforms:
/// horizontal row of vertical slides, two banks stacked, matching the physical pedal layout.
struct DipSwitchPanel: View {
    @ObservedObject var viewModel: PedalViewModel
    let layout: PedalLayout
    let theme: PedalColorTheme

    #if os(iOS)
    @State private var isExpanded: Bool = false
    #else
    @State private var isExpanded: Bool = true
    #endif

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
        .contentShape(Rectangle())
    }

    // MARK: - Dip Switch Content (shared across all platforms)

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
            .fill(
                LinearGradient(
                    colors: [
                        theme.backgroundGradient[0].opacity(0.50),
                        theme.backgroundGradient[1].opacity(0.65),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(theme.labelColor.opacity(0.28), lineWidth: 1)
            )
    }
}
