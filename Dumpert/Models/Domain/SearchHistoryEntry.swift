import Foundation

struct SearchHistoryEntry: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let query: String
    let timestamp: Date

    init(query: String) {
        self.id = UUID()
        self.query = query
        self.timestamp = Date()
    }

    init(id: UUID, query: String, timestamp: Date) {
        self.id = id
        self.query = query
        self.timestamp = timestamp
    }
}
