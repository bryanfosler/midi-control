import SwiftUI

/// Collapsible panel that lives ABOVE the pedal enclosure showing the dip switches.
/// On real Chase Bliss pedals, dip switches are on the side and not visible from above,
/// so this panel represents that "hidden side panel" concept.
///
/// iOS: Shows a compact bank summary with a sheet for native Toggle controls (44pt targets).
/// macOS: Shows the full skeuomorphic DIP switch bank inline.
struct DipSwitchPanel: View {
    @ObservedObject var viewModel: PedalViewModel
    let layout: PedalLayout
    let theme: PedalColorTheme

    @State private var isExpanded: Bool = true

    #if os(iOS)
    @State private var showingDipSheet = false
    @State private var dipSheetBankIndex = 0
    #endif

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            if isExpanded {
                Divider()
                    .background(theme.labelColor.opacity(0.15))
                    .padding(.horizontal, 10)
                #if os(iOS)
                iosDipContent
                #else
                dipContent
                #endif
            }
        }
        .background(panelBackground)
        .frame(width: PedalEnclosure.enclosureWidth)
        #if os(iOS)
        .sheet(isPresented: $showingDipSheet) {
            dipSheet
        }
        #endif
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

    // MARK: - iOS Touch-Friendly Content

    #if os(iOS)
    /// Each bank becomes a tappable row showing a mini dot preview + active count.
    /// Tapping opens a full sheet with native Toggle rows (44pt targets).
    private var iosDipContent: some View {
        VStack(spacing: 8) {
            ForEach(Array(layout.dipBanks.enumerated()), id: \.offset) { i, bank in
                let params = bank.paramIds.compactMap { viewModel.definition.parameter(byId: $0) }
                let onCount = params.filter { (viewModel.state.values[$0.cc] ?? 0) > 0 }.count

                Button {
                    dipSheetBankIndex = i
                    showingDipSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "switch.2")
                            .font(.system(size: 14))
                            .foregroundStyle(theme.labelColor.opacity(0.55))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bank.label.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.0)
                                .foregroundStyle(theme.labelColor)
                            Text(onCount == 0 ? "All off" : "\(onCount) of \(params.count) active")
                                .font(.system(size: 10))
                                .foregroundStyle(theme.labelColor.opacity(0.55))
                        }

                        Spacer()

                        // Mini preview dots — one per switch
                        HStack(spacing: 4) {
                            ForEach(params) { param in
                                let isOn = (viewModel.state.values[param.cc] ?? 0) > 0
                                Circle()
                                    .fill(isOn ? theme.dipOnColor : Color(white: 0.25))
                                    .frame(width: 7, height: 7)
                            }
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(theme.labelColor.opacity(0.35))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.labelColor.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(theme.labelColor.opacity(0.15), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// Full-screen sheet with native Toggle rows — proper 44pt touch targets.
    private var dipSheet: some View {
        NavigationStack {
            let bank = layout.dipBanks[dipSheetBankIndex]
            let params = bank.paramIds.compactMap { viewModel.definition.parameter(byId: $0) }

            List {
                Section {
                    ForEach(params) { param in
                        Toggle(isOn: Binding(
                            get: { (viewModel.state.values[param.cc] ?? 0) > 0 },
                            set: { newValue in
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.setValue(newValue ? 127 : 0, for: param)
                            }
                        )) {
                            let desc = ParameterDescriptions.description(
                                for: param.id, cc: param.cc,
                                pedalId: viewModel.definition.id
                            )
                            if desc.isEmpty {
                                Text(param.name)
                            } else {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(param.name)
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .tint(theme.dipOnColor)
                    }
                } header: {
                    Text(bank.label)
                }
            }
            .navigationTitle("DIP Switches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingDipSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    #endif

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
