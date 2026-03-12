import Foundation

struct Video: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let descriptionText: String
    let date: Date?
    let duration: Int
    let kudosTotal: Int
    let thumbnailURL: URL?
    let streamURL: URL?
    let tags: [String]
    let isNSFW: Bool

    init(from item: DumpertItem) {
        self.id = item.id
        self.title = item.title
        self.descriptionText = item.description?.strippingHTML() ?? ""

        if let dateString = item.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            self.date = formatter.date(from: dateString)
                ?? ISO8601DateFormatter().date(from: dateString)
        } else {
            self.date = nil
        }

        let media = item.media?.first
        self.duration = media?.duration ?? 0

        // Find best stream URL: prefer "stream" (HLS), then "1080p", then "720p"
        let variants = media?.variants ?? []
        let streamVariant = variants.first(where: { $0.version == "stream" })
            ?? variants.first(where: { $0.version == "1080p" })
            ?? variants.first(where: { $0.version == "720p" })
            ?? variants.first
        self.streamURL = streamVariant.flatMap { URL(string: $0.uri) }

        // Prefer still-large from stills dict, then still, then thumbnail
        let stillLarge = item.stills?["still-large"] ?? item.stills?["still"]
        self.thumbnailURL = stillLarge.flatMap { URL(string: $0) }
            ?? item.still.flatMap { URL(string: $0) }
            ?? item.thumbnail.flatMap { URL(string: $0) }

        self.kudosTotal = item.stats?.kudosTotal ?? 0
        self.tags = item.tags?
            .components(separatedBy: " ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty } ?? []
        self.isNSFW = item.nsfw ?? false
    }

    init(
        id: String,
        title: String,
        descriptionText: String,
        date: Date?,
        duration: Int,
        kudosTotal: Int,
        thumbnailURL: URL?,
        streamURL: URL?,
        tags: [String],
        isNSFW: Bool
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.date = date
        self.duration = duration
        self.kudosTotal = kudosTotal
        self.thumbnailURL = thumbnailURL
        self.streamURL = streamURL
        self.tags = tags
        self.isNSFW = isNSFW
    }
}
