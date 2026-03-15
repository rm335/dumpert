import Foundation
import SwiftUI

enum TopCommentMode: String, Codable, Sendable, CaseIterable {
    case off, single, all

    var displayName: String {
        switch self {
        case .off: String(localized: "Uit", comment: "Top comment mode - off")
        case .single: String(localized: "Alleen het top reaguursel", comment: "Top comment mode - single top comment")
        case .all: String(localized: "Alle reaguursels", comment: "Top comment mode - all top comments carousel")
        }
    }
}

enum ReadingSpeed: Int, Codable, Sendable, CaseIterable {
    case slow = 2
    case normal = 3
    case fast = 4
    case veryFast = 5
    case ultraFast = 6

    var displayName: String {
        switch self {
        case .slow: String(localized: "Langzaam (2 woorden/sec)", comment: "Reading speed - slow")
        case .normal: String(localized: "Normaal (3 woorden/sec)", comment: "Reading speed - normal")
        case .fast: String(localized: "Snel (4 woorden/sec)", comment: "Reading speed - fast")
        case .veryFast: String(localized: "Zeer snel (5 woorden/sec)", comment: "Reading speed - very fast")
        case .ultraFast: String(localized: "Razendsnel (6 woorden/sec)", comment: "Reading speed - ultra fast")
        }
    }

    /// Calculates reading duration in seconds for the given text, with a minimum of 5 seconds.
    func readingDuration(for text: String) -> Double {
        let wordCount = text.split(whereSeparator: \.isWhitespace).count
        return max(5.0, Double(wordCount) / Double(rawValue))
    }
}

enum TileSize: String, Codable, Sendable, CaseIterable {
    case small, normal, large

    var displayName: String {
        switch self {
        case .small: String(localized: "Klein", comment: "Tile size option - small")
        case .normal: String(localized: "Normaal", comment: "Tile size option - normal")
        case .large: String(localized: "Groot", comment: "Tile size option - large")
        }
    }

    var horizontalCardWidth: CGFloat {
        switch self {
        case .small: 300
        case .normal: 375
        case .large: 450
        }
    }

    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 30), count: gridColumnCount)
    }

    var gridColumnCount: Int {
        switch self {
        case .small: 4
        case .normal: 3
        case .large: 2
        }
    }
}

@Observable
@MainActor
final class UserSettings {
    var minimumKudos: Int
    var autoplayEnabled: Bool
    var hideWatched: Bool
    var reetenMinimumMinutes: Int
    var showNegativeKudos: Bool
    var nsfwEnabled: Bool
    var thumbnailPreviewEnabled: Bool
    var smartThumbnailsEnabled: Bool
    var tileSize: TileSize
    var upNextOverlayEnabled: Bool
    var upNextCountdownSeconds: Int
    var upNextMinimumVideoSeconds: Int
    var topCommentMode: TopCommentMode
    var readingSpeed: ReadingSpeed
    var showResumeOverlay: Bool
    var lastModified: Date

    init(minimumKudos: Int = 0, autoplayEnabled: Bool = true, hideWatched: Bool = true, reetenMinimumMinutes: Int = 10, showNegativeKudos: Bool = false, nsfwEnabled: Bool = true, thumbnailPreviewEnabled: Bool = true, smartThumbnailsEnabled: Bool = true, tileSize: TileSize = .normal, upNextOverlayEnabled: Bool = true, upNextCountdownSeconds: Int = 5, upNextMinimumVideoSeconds: Int = 60, topCommentMode: TopCommentMode = .all, readingSpeed: ReadingSpeed = .normal, showResumeOverlay: Bool = true) {
        self.minimumKudos = minimumKudos
        self.autoplayEnabled = autoplayEnabled
        self.hideWatched = hideWatched
        self.reetenMinimumMinutes = reetenMinimumMinutes
        self.showNegativeKudos = showNegativeKudos
        self.nsfwEnabled = nsfwEnabled
        self.thumbnailPreviewEnabled = thumbnailPreviewEnabled
        self.smartThumbnailsEnabled = smartThumbnailsEnabled
        self.tileSize = tileSize
        self.upNextOverlayEnabled = upNextOverlayEnabled
        self.upNextCountdownSeconds = upNextCountdownSeconds
        self.upNextMinimumVideoSeconds = upNextMinimumVideoSeconds
        self.topCommentMode = topCommentMode
        self.readingSpeed = readingSpeed
        self.showResumeOverlay = showResumeOverlay
        self.lastModified = Date()
    }

    var snapshot: UserSettingsSnapshot {
        UserSettingsSnapshot(
            minimumKudos: minimumKudos,
            autoplayEnabled: autoplayEnabled,
            hideWatched: hideWatched,
            reetenMinimumMinutes: reetenMinimumMinutes,
            showNegativeKudos: showNegativeKudos,
            nsfwEnabled: nsfwEnabled,
            thumbnailPreviewEnabled: thumbnailPreviewEnabled,
            smartThumbnailsEnabled: smartThumbnailsEnabled,
            tileSize: tileSize,
            upNextOverlayEnabled: upNextOverlayEnabled,
            upNextCountdownSeconds: upNextCountdownSeconds,
            upNextMinimumVideoSeconds: upNextMinimumVideoSeconds,
            topCommentMode: topCommentMode,
            readingSpeed: readingSpeed,
            showResumeOverlay: showResumeOverlay,
            lastModified: lastModified
        )
    }

    func apply(_ snapshot: UserSettingsSnapshot) {
        minimumKudos = snapshot.minimumKudos
        autoplayEnabled = snapshot.autoplayEnabled
        hideWatched = snapshot.hideWatched
        reetenMinimumMinutes = snapshot.reetenMinimumMinutes
        showNegativeKudos = snapshot.showNegativeKudos
        nsfwEnabled = snapshot.nsfwEnabled
        thumbnailPreviewEnabled = snapshot.thumbnailPreviewEnabled
        smartThumbnailsEnabled = snapshot.smartThumbnailsEnabled
        tileSize = snapshot.tileSize
        upNextOverlayEnabled = snapshot.upNextOverlayEnabled
        upNextCountdownSeconds = snapshot.upNextCountdownSeconds
        upNextMinimumVideoSeconds = snapshot.upNextMinimumVideoSeconds
        topCommentMode = snapshot.topCommentMode
        readingSpeed = snapshot.readingSpeed
        showResumeOverlay = snapshot.showResumeOverlay
        lastModified = snapshot.lastModified
    }
}

struct UserSettingsSnapshot: Codable, Sendable {
    var minimumKudos: Int
    var autoplayEnabled: Bool
    var hideWatched: Bool
    var reetenMinimumMinutes: Int
    var showNegativeKudos: Bool
    var nsfwEnabled: Bool
    var thumbnailPreviewEnabled: Bool
    var smartThumbnailsEnabled: Bool
    var tileSize: TileSize
    var upNextOverlayEnabled: Bool
    var upNextCountdownSeconds: Int
    var upNextMinimumVideoSeconds: Int
    var topCommentMode: TopCommentMode
    var readingSpeed: ReadingSpeed
    var showResumeOverlay: Bool
    var lastModified: Date

    init(minimumKudos: Int = 0, autoplayEnabled: Bool = true, hideWatched: Bool = true, reetenMinimumMinutes: Int = 10, showNegativeKudos: Bool = false, nsfwEnabled: Bool = true, thumbnailPreviewEnabled: Bool = true, smartThumbnailsEnabled: Bool = true, tileSize: TileSize = .normal, upNextOverlayEnabled: Bool = true, upNextCountdownSeconds: Int = 5, upNextMinimumVideoSeconds: Int = 60, topCommentMode: TopCommentMode = .all, readingSpeed: ReadingSpeed = .normal, showResumeOverlay: Bool = true, lastModified: Date = Date()) {
        self.minimumKudos = minimumKudos
        self.autoplayEnabled = autoplayEnabled
        self.hideWatched = hideWatched
        self.reetenMinimumMinutes = reetenMinimumMinutes
        self.showNegativeKudos = showNegativeKudos
        self.nsfwEnabled = nsfwEnabled
        self.thumbnailPreviewEnabled = thumbnailPreviewEnabled
        self.smartThumbnailsEnabled = smartThumbnailsEnabled
        self.tileSize = tileSize
        self.upNextOverlayEnabled = upNextOverlayEnabled
        self.upNextCountdownSeconds = upNextCountdownSeconds
        self.upNextMinimumVideoSeconds = upNextMinimumVideoSeconds
        self.topCommentMode = topCommentMode
        self.readingSpeed = readingSpeed
        self.showResumeOverlay = showResumeOverlay
        self.lastModified = lastModified
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        minimumKudos = try container.decode(Int.self, forKey: .minimumKudos)
        autoplayEnabled = try container.decode(Bool.self, forKey: .autoplayEnabled)
        hideWatched = try container.decode(Bool.self, forKey: .hideWatched)
        // Migration: old format stored Bool, new format stores Int (minutes)
        if let minutes = try? container.decode(Int.self, forKey: .reetenMinimumMinutes) {
            reetenMinimumMinutes = minutes
        } else if let oldBool = try? container.decode(Bool.self, forKey: .reetenMinimumMinutes) {
            reetenMinimumMinutes = oldBool ? 10 : 0
        } else {
            reetenMinimumMinutes = 10
        }
        showNegativeKudos = try container.decode(Bool.self, forKey: .showNegativeKudos)
        nsfwEnabled = try container.decodeIfPresent(Bool.self, forKey: .nsfwEnabled) ?? true
        thumbnailPreviewEnabled = try container.decode(Bool.self, forKey: .thumbnailPreviewEnabled)
        smartThumbnailsEnabled = try container.decodeIfPresent(Bool.self, forKey: .smartThumbnailsEnabled) ?? true
        tileSize = try container.decodeIfPresent(TileSize.self, forKey: .tileSize) ?? .normal
        upNextOverlayEnabled = try container.decodeIfPresent(Bool.self, forKey: .upNextOverlayEnabled) ?? true
        upNextCountdownSeconds = try container.decodeIfPresent(Int.self, forKey: .upNextCountdownSeconds) ?? 5
        upNextMinimumVideoSeconds = try container.decodeIfPresent(Int.self, forKey: .upNextMinimumVideoSeconds) ?? 60
        // Migration: old format stored Bool (showTopComment), new format stores TopCommentMode
        if let mode = try? container.decode(TopCommentMode.self, forKey: .topCommentMode) {
            topCommentMode = mode
        } else if let oldBool = try? container.decode(Bool.self, forKey: .topCommentMode) {
            topCommentMode = oldBool ? .all : .off
        } else {
            topCommentMode = .all
        }
        readingSpeed = try container.decodeIfPresent(ReadingSpeed.self, forKey: .readingSpeed) ?? .normal
        showResumeOverlay = try container.decodeIfPresent(Bool.self, forKey: .showResumeOverlay) ?? true
        lastModified = try container.decode(Date.self, forKey: .lastModified)
    }

    private enum CodingKeys: String, CodingKey {
        case minimumKudos, autoplayEnabled, hideWatched
        case reetenMinimumMinutes = "reetenMinimumDuration"
        case showNegativeKudos, nsfwEnabled, thumbnailPreviewEnabled, smartThumbnailsEnabled, tileSize
        case upNextOverlayEnabled, upNextCountdownSeconds, upNextMinimumVideoSeconds
        case topCommentMode = "showTopComment"
        case readingSpeed
        case showResumeOverlay
        case lastModified
    }
}
