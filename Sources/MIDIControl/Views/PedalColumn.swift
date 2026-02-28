import SwiftUI

/// Full column for one pedal: MIDI channel selector + pedal enclosure + hidden settings,
/// with preset sidebar
struct PedalColumn: View {
    @ObservedObject var viewModel: PedalViewModel
    let layout: PedalLayout
    let theme: PedalColorTheme

    @State private var showingChannelSheet = false
    @State private var targetChannel: Int  = 2   // selection inside the sheet

    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var landscapeSection: Int = 0
    #endif

    var body: some View {
        #if os(macOS)
        HSplitView {
            scrollableContent
            PresetPanel(viewModel: viewModel)
                .frame(minWidth: 140, maxWidth: 165)
        }
        .sheet(isPresented: $showingChannelSheet) {
            channelChangeSheet
        }
        #else
        iOSLayout
            .sheet(isPresented: $showingChannelSheet) {
                channelChangeSheet
            }
        #endif
    }

    // MARK: - iOS Layouts

    #if os(iOS)
    private var iOSLayout: some View {
        GeometryReader { geo in
            Group {
                if verticalSizeClass == .compact {
                    landscapeLayout(geo: geo)
                } else {
                    portraitLayout(geo: geo)
                }
            }
        }
    }

    /// Portrait: scale the enclosure to fill available height, capped by screen width.
    /// ~110pt overhead accounts for collapsed panel headers + spacing.
    /// Minimum scale enforces 44pt touch targets on the knobs (natural knob frame = 76pt).
    private func portraitLayout(geo: GeometryProxy) -> some View {
        let minScale: CGFloat = 44.0 / 76.0  // keeps knob touch targets ≥ 44pt
        let overhead: CGFloat = 110          // collapsed panel headers + VStack spacing
        let scaleByHeight = (geo.size.height - overhead) / PedalEnclosure.enclosureHeight
        let scaleByWidth  = (geo.size.width - 32) / PedalEnclosure.enclosureWidth  // 16pt padding each side
        let scale = max(minScale, min(scaleByHeight, scaleByWidth))
        return ScrollView {
            VStack(spacing: 14) {
                // iPad: show channelBar inline (screen space allows it).
                // iPhone: channelBar lives in the Settings sheet to maximise pedal canvas.
                if horizontalSizeClass == .regular {
                    channelBar
                }
                DipSwitchPanel(viewModel: viewModel, layout: layout, theme: theme)
                PedalEnclosure(viewModel: viewModel, layout: layout, theme: theme, scale: scale)
                HiddenSettingsPanel(viewModel: viewModel, layout: layout, theme: theme)
                if viewModel.definition.id == "mood-mkii" {
                    MiniKeyboardView(viewModel: viewModel)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
    }

    /// Landscape (compact height): enclosure on left scaled to fit height,
    /// segmented section picker + scrollable panels on the right.
    private func landscapeLayout(geo: GeometryProxy) -> some View {
        let scale = min(1.0, geo.size.height * 0.88 / PedalEnclosure.enclosureHeight)
        return HStack(alignment: .center, spacing: 0) {
            VStack {
                Spacer(minLength: 0)
                PedalEnclosure(viewModel: viewModel, layout: layout, theme: theme, scale: scale)
                Spacer(minLength: 0)
            }
            .frame(width: PedalEnclosure.enclosureWidth * scale + 12)

            Divider()

            VStack(spacing: 0) {
                // Section picker — compact and keyboard-safe in landscape
                Picker("", selection: $landscapeSection) {
                    Text("Controls").tag(0)
                    Text("Advanced").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

                ScrollView {
                    if landscapeSection == 0 {
                        VStack(spacing: 14) {
                            channelBar
                            DipSwitchPanel(viewModel: viewModel, layout: layout, theme: theme)
                            if viewModel.definition.id == "mood-mkii" {
                                MiniKeyboardView(viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    } else {
                        HiddenSettingsPanel(viewModel: viewModel, layout: layout, theme: theme)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
    }
    #endif

    // MARK: - macOS Scrollable Content

    private var scrollableContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                channelBar
                DipSwitchPanel(viewModel: viewModel, layout: layout, theme: theme)
                PedalEnclosure(viewModel: viewModel, layout: layout, theme: theme)
                HiddenSettingsPanel(viewModel: viewModel, layout: layout, theme: theme)
                if viewModel.definition.id == "mood-mkii" {
                    MiniKeyboardView(viewModel: viewModel)
                }
            }
            .padding()
        }
        .frame(minWidth: 340)
    }

    // MARK: - Channel Bar

    private var channelBar: some View {
        HStack(spacing: 8) {
            // Tappable channel pill — tap to open the channel-change sheet
            Button {
                targetChannel = viewModel.midiChannel
                showingChannelSheet = true
            } label: {
                HStack(spacing: 4) {
                    Text("Ch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.midiChannel)")
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(platformControlBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(platformSeparatorColor, lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)
            .help("Tap to change the pedal's MIDI channel (sends CC 104 to the hardware)")

            Spacer()

            Button("Send All") {
                viewModel.sendAll()
            }
            .help("Re-send all current parameter values to the pedal")
        }
    }

    // MARK: - Platform Colors

    private var platformControlBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    private var platformSeparatorColor: Color {
        #if os(macOS)
        Color(nsColor: .separatorColor)
        #else
        Color(.separator)
        #endif
    }

    // MARK: - Channel Change Sheet

    private var channelChangeSheet: some View {
        VStack(alignment: .leading, spacing: 18) {

            // Title
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Change MIDI Channel")
                        .font(.headline)
                    Text(viewModel.definition.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // How it works
            VStack(alignment: .leading, spacing: 6) {
                Label("How this works", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("This sends **CC 104** on the pedal's current channel (ch \(viewModel.midiChannel)). The physical pedal responds by switching to the new channel — no manual button-pressing required.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(platformControlBackground))

            // Channel picker
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current channel")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Ch \(viewModel.midiChannel)")
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text("New channel")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $targetChannel) {
                        ForEach(1...16, id: \.self) { ch in
                            Text("Ch \(ch)").tag(ch)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                }
            }

            // Warning if same channel selected
            if targetChannel == viewModel.midiChannel {
                Label("Select a different channel to change", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            // Reminder about the other pedal
            Label("Tip: if you have two pedals, give each a unique channel so CC messages don't cross-talk.", systemImage: "lightbulb")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            // Action buttons
            HStack {
                Button("Cancel") {
                    showingChannelSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Apply to Pedal") {
                    viewModel.setPedalMidiChannel(to: targetChannel)
                    showingChannelSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(targetChannel == viewModel.midiChannel)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
