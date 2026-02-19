import SwiftUI

/// Compact sidebar panel for preset management.
/// - Single click to load a preset and highlight it.
/// - Preset notes hidden from the list; shown on hover as a tooltip.
/// - Reset button (↺) in header returns all params to factory defaults.
struct PresetPanel: View {
    @ObservedObject var viewModel: PedalViewModel

    @State private var showingSaveSheet = false
    @State private var newPresetName    = ""
    @State private var newPresetNotes   = ""
    @State private var renamingPreset: Preset?
    @State private var renameText       = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────────────
            HStack(spacing: 4) {
                Text("Presets")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()

                // Reset to factory defaults
                Button {
                    viewModel.resetToDefaults()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Reset all parameters to factory defaults")

                // Save current settings as new preset
                Button {
                    showingSaveSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Save current settings as a preset")
                .keyboardShortcut("s", modifiers: .command)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()

            // ── Preset List ─────────────────────────────────────────
            if viewModel.presets.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                    Text("No presets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.presets) { preset in
                            PresetRow(
                                preset: preset,
                                isActive: viewModel.activePresetId == preset.id,
                                onLoad:   { viewModel.loadPreset(preset) },
                                onDelete: { viewModel.deletePreset(preset) },
                                onRename: {
                                    renamingPreset = preset
                                    renameText = preset.name
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                }
            }

            // ── Unsaved-changes indicator ────────────────────────────
            if viewModel.state.isDirty {
                Divider()
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 5, height: 5)
                    Text("Unsaved changes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
        }
        .sheet(isPresented: $showingSaveSheet) { savePresetSheet }
        .sheet(item: $renamingPreset)          { renameSheet($0)  }
    }

    // MARK: - Save Sheet

    private var savePresetSheet: some View {
        VStack(spacing: 14) {
            Text("Save Preset")
                .font(.headline)
            TextField("Preset Name", text: $newPresetName)
                .textFieldStyle(.roundedBorder)
            TextField("Notes (optional)", text: $newPresetNotes)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") {
                    showingSaveSheet = false
                    newPresetName  = ""
                    newPresetNotes = ""
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    guard !newPresetName.isEmpty else { return }
                    viewModel.savePreset(name: newPresetName, notes: newPresetNotes)
                    showingSaveSheet = false
                    newPresetName  = ""
                    newPresetNotes = ""
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newPresetName.isEmpty)
            }
        }
        .padding()
        .frame(width: 280)
    }

    // MARK: - Rename Sheet

    private func renameSheet(_ preset: Preset) -> some View {
        VStack(spacing: 14) {
            Text("Rename Preset")
                .font(.headline)
            TextField("Name", text: $renameText)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { renamingPreset = nil }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Rename") {
                    guard !renameText.isEmpty else { return }
                    viewModel.renamePreset(preset, to: renameText)
                    renamingPreset = nil
                }
                .keyboardShortcut(.defaultAction)
                .disabled(renameText.isEmpty)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

// MARK: - Preset Row

private struct PresetRow: View {
    let preset:   Preset
    let isActive: Bool
    let onLoad:   () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void

    var body: some View {
        Text(preset.name)
            .font(.system(size: 11))
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
            .padding(.horizontal, 7)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isActive ? Color.accentColor.opacity(0.18) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(
                        isActive ? Color.accentColor.opacity(0.45) : Color.clear,
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
            // Single click to load and highlight
            .onTapGesture { onLoad() }
            // Notes shown on hover only — keeps list compact
            .help(preset.notes.isEmpty ? preset.name : "\(preset.name)\n\n\(preset.notes)")
            .contextMenu {
                Button("Load")        { onLoad()   }
                Button("Rename…")     { onRename() }
                Divider()
                Button("Delete", role: .destructive) { onDelete() }
            }
    }
}
