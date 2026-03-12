import Foundation

struct WatchProgress: Identifiable, Codable, Sendable {
    var id: String { videoId }
    let videoId: String
    var watchedSeconds: Double
    var totalSeconds: Double
    var isCompleted: Bool
    var lastWatchedDate: Date

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return watchedSeconds / totalSeconds
    }

    init(videoId: String, watchedSeconds: Double = 0, totalSeconds: Double = 0) {
        self.videoId = videoId
        self.watchedSeconds = watchedSeconds
        self.totalSeconds = totalSeconds
        self.isCompleted = totalSeconds > 0 && (watchedSeconds / totalSeconds) >= 0.9
        self.lastWatchedDate = Date()
    }

    mutating func update(watchedSeconds: Double, totalSeconds: Double) {
        self.watchedSeconds = watchedSeconds
        self.totalSeconds = totalSeconds
        self.isCompleted = totalSeconds > 0 && (watchedSeconds / totalSeconds) >= 0.9
        self.lastWatchedDate = Date()
    }
}
