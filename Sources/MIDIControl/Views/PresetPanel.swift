import SwiftUI

/// Sidebar panel for preset management — list, save, load, delete, rename
struct PresetPanel: View {
    @ObservedObject var viewModel: PedalViewModel

    @State private var showingSaveSheet = false
    @State private var newPresetName = ""
    @State private var newPresetNotes = ""
    @State private var renamingPreset: Preset?
    @State private var renameText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Presets")
                    .font(.headline)
                Spacer()
                Button(action: { showingSaveSheet = true }) {
                    Image(systemName: "plus")
                }
                .help("Save current settings as preset")
                .keyboardShortcut("s", modifiers: .command)
            }
            .padding()

            Divider()

            // Preset list
            if viewModel.presets.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("No presets saved")
                        .foregroundStyle(.secondary)
                    Text("Click + to save current settings")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(viewModel.presets) { preset in
                        PresetRow(
                            preset: preset,
                            onLoad: { viewModel.loadPreset(preset) },
                            onDelete: { viewModel.deletePreset(preset) },
                            onRename: {
                                renamingPreset = preset
                                renameText = preset.name
                            }
                        )
                    }
                }
                .listStyle(.sidebar)
            }

            // Dirty state indicator
            if viewModel.state.isDirty {
                Divider()
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("Unsaved changes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            savePresetSheet
        }
        .sheet(item: $renamingPreset) { preset in
            renameSheet(preset)
        }
    }

    // MARK: - Save Sheet

    private var savePresetSheet: some View {
        VStack(spacing: 16) {
            Text("Save Preset")
                .font(.headline)

            TextField("Preset Name", text: $newPresetName)
                .textFieldStyle(.roundedBorder)

            TextField("Notes (optional)", text: $newPresetNotes)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showingSaveSheet = false
                    newPresetName = ""
                    newPresetNotes = ""
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    guard !newPresetName.isEmpty else { return }
                    viewModel.savePreset(name: newPresetName, notes: newPresetNotes)
                    showingSaveSheet = false
                    newPresetName = ""
                    newPresetNotes = ""
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newPresetName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }

    // MARK: - Rename Sheet

    private func renameSheet(_ preset: Preset) -> some View {
        VStack(spacing: 16) {
            Text("Rename Preset")
                .font(.headline)

            TextField("Name", text: $renameText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    renamingPreset = nil
                }
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
        .frame(width: 300)
    }
}

// MARK: - Preset Row

private struct PresetRow: View {
    let preset: Preset
    let onLoad: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.body)
                if !preset.notes.isEmpty {
                    Text(preset.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onLoad() }
        .contextMenu {
            Button("Load") { onLoad() }
            Button("Rename...") { onRename() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}
