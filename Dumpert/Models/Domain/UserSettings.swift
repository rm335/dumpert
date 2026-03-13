import Foundation
import SwiftUI

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
    var thumbnailPreviewEnabled: Bool
    var smartThumbnailsEnabled: Bool
    var tileSize: TileSize
    var upNextOverlayEnabled: Bool
    var upNextCountdownSeconds: Int
    var upNextMinimumVideoSeconds: Int
    var showTopComment: Bool
    var showResumeOverlay: Bool
    var lastModified: Date

    init(minimumKudos: Int = 0, autoplayEnabled: Bool = true, hideWatched: Bool = true, reetenMinimumMinutes: Int = 10, showNegativeKudos: Bool = false, thumbnailPreviewEnabled: Bool = true, smartThumbnailsEnabled: Bool = true, tileSize: TileSize = .normal, upNextOverlayEnabled: Bool = true, upNextCountdownSeconds: Int = 5, upNextMinimumVideoSeconds: Int = 60, showTopComment: Bool = true, showResumeOverlay: Bool = true) {
        self.minimumKudos = minimumKudos
        self.autoplayEnabled = autoplayEnabled
        self.hideWatched = hideWatched
        self.reetenMinimumMinutes = reetenMinimumMinutes
        self.showNegativeKudos = showNegativeKudos
        self.thumbnailPreviewEnabled = thumbnailPreviewEnabled
        self.smartThumbnailsEnabled = smartThumbnailsEnabled
        self.tileSize = tileSize
        self.upNextOverlayEnabled = upNextOverlayEnabled
        self.upNextCountdownSeconds = upNextCountdownSeconds
        self.upNextMinimumVideoSeconds = upNextMinimumVideoSeconds
        self.showTopComment = showTopComment
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
            thumbnailPreviewEnabled: thumbnailPreviewEnabled,
            smartThumbnailsEnabled: smartThumbnailsEnabled,
            tileSize: tileSize,
            upNextOverlayEnabled: upNextOverlayEnabled,
            upNextCountdownSeconds: upNextCountdownSeconds,
            upNextMinimumVideoSeconds: upNextMinimumVideoSeconds,
            showTopComment: showTopComment,
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
        thumbnailPreviewEnabled = snapshot.thumbnailPreviewEnabled
        smartThumbnailsEnabled = snapshot.smartThumbnailsEnabled
        tileSize = snapshot.tileSize
        upNextOverlayEnabled = snapshot.upNextOverlayEnabled
        upNextCountdownSeconds = snapshot.upNextCountdownSeconds
        upNextMinimumVideoSeconds = snapshot.upNextMinimumVideoSeconds
        showTopComment = snapshot.showTopComment
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
    var thumbnailPreviewEnabled: Bool
    var smartThumbnailsEnabled: Bool
    var tileSize: TileSize
    var upNextOverlayEnabled: Bool
    var upNextCountdownSeconds: Int
    var upNextMinimumVideoSeconds: Int
    var showTopComment: Bool
    var showResumeOverlay: Bool
    var lastModified: Date

    init(minimumKudos: Int = 0, autoplayEnabled: Bool = true, hideWatched: Bool = true, reetenMinimumMinutes: Int = 10, showNegativeKudos: Bool = false, thumbnailPreviewEnabled: Bool = true, smartThumbnailsEnabled: Bool = true, tileSize: TileSize = .normal, upNextOverlayEnabled: Bool = true, upNextCountdownSeconds: Int = 5, upNextMinimumVideoSeconds: Int = 60, showTopComment: Bool = true, showResumeOverlay: Bool = true, lastModified: Date = Date()) {
        self.minimumKudos = minimumKudos
        self.autoplayEnabled = autoplayEnabled
        self.hideWatched = hideWatched
        self.reetenMinimumMinutes = reetenMinimumMinutes
        self.showNegativeKudos = showNegativeKudos
        self.thumbnailPreviewEnabled = thumbnailPreviewEnabled
        self.smartThumbnailsEnabled = smartThumbnailsEnabled
        self.tileSize = tileSize
        self.upNextOverlayEnabled = upNextOverlayEnabled
        self.upNextCountdownSeconds = upNextCountdownSeconds
        self.upNextMinimumVideoSeconds = upNextMinimumVideoSeconds
        self.showTopComment = showTopComment
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
        thumbnailPreviewEnabled = try container.decode(Bool.self, forKey: .thumbnailPreviewEnabled)
        smartThumbnailsEnabled = try container.decodeIfPresent(Bool.self, forKey: .smartThumbnailsEnabled) ?? true
        tileSize = try container.decodeIfPresent(TileSize.self, forKey: .tileSize) ?? .normal
        upNextOverlayEnabled = try container.decodeIfPresent(Bool.self, forKey: .upNextOverlayEnabled) ?? true
        upNextCountdownSeconds = try container.decodeIfPresent(Int.self, forKey: .upNextCountdownSeconds) ?? 5
        upNextMinimumVideoSeconds = try container.decodeIfPresent(Int.self, forKey: .upNextMinimumVideoSeconds) ?? 60
        showTopComment = try container.decodeIfPresent(Bool.self, forKey: .showTopComment) ?? true
        showResumeOverlay = try container.decodeIfPresent(Bool.self, forKey: .showResumeOverlay) ?? true
        lastModified = try container.decode(Date.self, forKey: .lastModified)
    }

    private enum CodingKeys: String, CodingKey {
        case minimumKudos, autoplayEnabled, hideWatched
        case reetenMinimumMinutes = "reetenMinimumDuration"
        case showNegativeKudos, thumbnailPreviewEnabled, smartThumbnailsEnabled, tileSize
        case upNextOverlayEnabled, upNextCountdownSeconds, upNextMinimumVideoSeconds
        case showTopComment, showResumeOverlay
        case lastModified
    }
}
