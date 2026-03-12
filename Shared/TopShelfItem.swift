import Foundation

struct TopShelfItem: Codable, Sendable, Identifiable {
    let id: String
    let title: String
    let thumbnailURL: URL?
    let streamURL: URL?
}
