import GroupActivities
import Foundation

struct WatchTogetherActivity: GroupActivity {
    let videoId: String
    let title: String
    let streamURL: URL
    let thumbnailURL: URL?

    var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        meta.type = .watchTogether
        meta.title = title
        meta.fallbackURL = URL(string: "dumpert://video/\(videoId)")
        return meta
    }
}
