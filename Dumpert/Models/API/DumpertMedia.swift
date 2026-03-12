import Foundation

struct DumpertMedia: Codable {
    let description: String?
    let duration: Int?
    let mediatype: String?
    let variants: [MediaVariant]?
}

struct MediaVariant: Codable {
    let uri: String
    let version: String
}
