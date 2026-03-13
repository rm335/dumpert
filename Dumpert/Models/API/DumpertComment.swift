import Foundation

struct CommentsAPIResponse: Codable, Sendable {
    let data: CommentsData?
    let status: String?
    let summary: CommentsSummary?
}

struct CommentsData: Codable, Sendable {
    let comments: [DumpertComment]?
}

struct CommentsSummary: Codable, Sendable {
    let commentCount: Int?

    private enum CodingKeys: String, CodingKey {
        case commentCount = "comment_count"
    }
}

struct DumpertComment: Codable, Sendable, Identifiable {
    let id: Int
    let authorUsername: String
    let displayContent: String
    let kudosCount: Int
    let creationDatetime: String?
    let banned: Bool?

    private enum CodingKeys: String, CodingKey {
        case id
        case authorUsername = "author_username"
        case displayContent = "display_content"
        case kudosCount = "kudos_count"
        case creationDatetime = "creation_datetime"
        case banned
    }
}
