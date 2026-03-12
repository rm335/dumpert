import Foundation

enum VideoCategory: String, CaseIterable, Identifiable, Codable {
    case nieuwBinnen
    case reeten
    case vrijmico
    case dashcam

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nieuwBinnen: String(localized: "Nieuw", comment: "Category name for new videos")
        case .reeten: String(localized: "Dumpert Reeten", comment: "Category name for hall of fame videos")
        case .vrijmico: String(localized: "VrijMiCo", comment: "Category name for Friday/Saturday/Sunday content")
        case .dashcam: String(localized: "Dashcam", comment: "Category name for dashcam videos")
        }
    }

    var searchQuery: String {
        switch self {
        case .nieuwBinnen: ""
        case .reeten: "dumpertreeten"
        case .vrijmico: "vrijmico"
        case .dashcam: "dashcam"
        }
    }

    var systemImage: String {
        switch self {
        case .nieuwBinnen: "sparkles"
        case .reeten: "fork.knife"
        case .vrijmico: "party.popper.fill"
        case .dashcam: "car.fill"
        }
    }

    var usesLatestEndpoint: Bool {
        self == .nieuwBinnen
    }
}
