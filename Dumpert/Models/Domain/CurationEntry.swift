import Foundation

struct CurationEntry: Identifiable, Codable, Sendable {
    let id: UUID
    let videoId: String
    let category: VideoCategory
    let action: CurationAction
    let timestamp: Date

    init(videoId: String, category: VideoCategory, action: CurationAction) {
        self.id = UUID()
        self.videoId = videoId
        self.category = category
        self.action = action
        self.timestamp = Date()
    }
}

enum CurationAction: String, Codable, Sendable {
    case add
    case remove
}
