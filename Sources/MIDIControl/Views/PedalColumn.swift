import SwiftUI

/// Full column for one pedal: MIDI channel selector + pedal enclosure + hidden settings,
/// with preset sidebar
struct PedalColumn: View {
    @ObservedObject var viewModel: PedalViewModel
    let layout: PedalLayout
    let theme: PedalColorTheme

    @State private var showingChannelSheet = false
    @State private var targetChannel: Int  = 2   // selection inside the sheet
    @State private var resetHoldProgress: CGFloat = 0
    @State private var resetHoldTimer: Timer? = nil
    @State private var resetHoldStart: Date? = nil
    @State private var showingResetAlert = false
    private let resetHoldDuration: TimeInterval = 2.0

    var body: some View {
        HSplitView {
            // Left: dip switches + pedal face + hidden settings, scrollable
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

            // Right: preset panel (compact)
            PresetPanel(viewModel: viewModel)
                .frame(minWidth: 140, maxWidth: 165)
        }
        .sheet(isPresented: $showingChannelSheet) {
            channelChangeSheet
        }
    }

    // MARK: - Channel Bar

    private var channelBar: some View {
        HStack(spacing: 8) {
            // Read-only channel indicator — shows what the app is currently sending on
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
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
                    )
            )
            .help("MIDI channel this pedal is currently set to")

            // Button to reconfigure the pedal's channel
            Button {
                targetChannel = viewModel.midiChannel
                showingChannelSheet = true
            } label: {
                Label("Set Channel", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption)
            }
            .help("Change the pedal's MIDI channel (sends CC 104 to the hardware)")

            Spacer()

            resetHoldButton

            Button("Send All") {
                viewModel.sendAll()
            }
            .help("Re-send all current parameter values to the pedal")
        }
    }

    // MARK: - Hold-to-Reset Button

    /// Requires holding the mouse button for 2 seconds — impossible to trigger accidentally.
    /// A red progress bar fills from left to right while held; releasing early cancels.
    private var resetHoldButton: some View {
        ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.red.opacity(0.08))
            // Progress fill
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red.opacity(0.22))
                    .frame(width: geo.size.width * resetHoldProgress)
                    .animation(.linear(duration: 0), value: resetHoldProgress)
            }
            // Label
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 9))
                Text(resetHoldProgress > 0 ? "Hold…" : "Reset to Stock")
                    .font(.caption)
            }
            .padding(.horizontal, 7)
            .foregroundStyle(Color.red.opacity(0.55 + 0.45 * resetHoldProgress))
        }
        .frame(height: 22)
        .fixedSize(horizontal: true, vertical: false)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4)
            .strokeBorder(Color.red.opacity(0.30 + 0.40 * resetHoldProgress), lineWidth: 0.5))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in beginResetHold() }
                .onEnded   { _ in cancelResetHold() }
        )
        .help("Hold for 2 seconds, then confirm to reset all parameters to factory defaults")
        .alert("Reset to Stock?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) { viewModel.resetToDefaults() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All knobs and settings will return to factory defaults and be sent to the pedal immediately.")
        }
    }

    private func beginResetHold() {
        guard resetHoldTimer == nil else { return }
        resetHoldStart = Date()
        let timer = Timer(timeInterval: 1.0/30.0, repeats: true) { t in
            guard let start = resetHoldStart else { t.invalidate(); return }
            let progress = min(1.0, Date().timeIntervalSince(start) / resetHoldDuration)
            DispatchQueue.main.async {
                resetHoldProgress = CGFloat(progress)
                if progress >= 1.0 {
                    t.invalidate()
                    resetHoldTimer = nil
                    resetHoldStart = nil
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        resetHoldProgress = 0
                    }
                    showingResetAlert = true
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        resetHoldTimer = timer
    }

    private func cancelResetHold() {
        resetHoldTimer?.invalidate()
        resetHoldTimer = nil
        resetHoldStart = nil
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            resetHoldProgress = 0
        }
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
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))

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
