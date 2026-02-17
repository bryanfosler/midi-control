import Foundation

/// A saved preset — captures all parameter values for a specific pedal
struct Preset: Identifiable, Codable {
    let id: UUID
    var name: String
    let pedalId: String          // matches PedalDefinition.id
    var midiChannel: Int         // 1-16
    var parameters: [Int: Int]   // CC number -> value
    var notes: String
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        pedalId: String,
        midiChannel: Int,
        parameters: [Int: Int],
        notes: String = "",
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.pedalId = pedalId
        self.midiChannel = midiChannel
        self.parameters = parameters
        self.notes = notes
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
