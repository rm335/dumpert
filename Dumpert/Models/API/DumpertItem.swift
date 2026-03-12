import Foundation

struct DumpertItem: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let date: String?
    let media: [DumpertMedia]?
    let stats: DumpertStats?
    let tags: String?
    let still: String?
    let stills: [String: String]?
    let thumbnail: String?
    let nsfw: Bool?
    let mediaType: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, date, media, stats, tags
        case still, stills, thumbnail, nsfw
        case mediaType = "media_type"
    }
}
