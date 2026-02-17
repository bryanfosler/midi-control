import Foundation

/// Reads and writes preset JSON files in ~/Library/Application Support/MIDIControl/presets/
class PresetStorage {
    private let presetsDirectory: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        presetsDirectory = appSupport.appendingPathComponent("MIDIControl/presets", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: presetsDirectory, withIntermediateDirectories: true)
    }

    /// Load all presets for a given pedal ID, sorted by name
    func loadPresets(for pedalId: String) -> [Preset] {
        let pedalDir = presetsDirectory.appendingPathComponent(pedalId, isDirectory: true)

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: pedalDir, includingPropertiesForKeys: nil
        ) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> Preset? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(Preset.self, from: data)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Save a preset to disk (creates or overwrites)
    func save(_ preset: Preset) {
        let pedalDir = presetsDirectory.appendingPathComponent(preset.pedalId, isDirectory: true)
        try? FileManager.default.createDirectory(at: pedalDir, withIntermediateDirectories: true)

        let fileURL = pedalDir.appendingPathComponent("\(preset.id.uuidString).json")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(preset) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Delete a preset file from disk
    func delete(_ preset: Preset) {
        let fileURL = presetsDirectory
            .appendingPathComponent(preset.pedalId, isDirectory: true)
            .appendingPathComponent("\(preset.id.uuidString).json")
        try? FileManager.default.removeItem(at: fileURL)
    }
}
