import Foundation

struct VoiceLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    var text: String
    var fileURL: URL
}
