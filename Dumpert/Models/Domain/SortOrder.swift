import Foundation

enum SortOrder: String, Codable, Sendable, CaseIterable, Identifiable {
    case dateNewest = "date+"
    case dateOldest = "date-"
    case mostKudos = "kudos+"
    case mostViews = "views+"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dateNewest: String(localized: "Nieuwste", comment: "Sort order: newest first")
        case .dateOldest: String(localized: "Oudste", comment: "Sort order: oldest first")
        case .mostKudos: String(localized: "Meeste kudos", comment: "Sort order: most kudos")
        case .mostViews: String(localized: "Meeste views", comment: "Sort order: most views")
        }
    }

    var systemImage: String {
        switch self {
        case .dateNewest: "arrow.down.circle"
        case .dateOldest: "arrow.up.circle"
        case .mostKudos: "hand.thumbsup"
        case .mostViews: "eye"
        }
    }
}
