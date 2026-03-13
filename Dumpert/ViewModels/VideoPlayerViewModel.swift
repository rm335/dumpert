import Foundation
import AVFoundation
import AVKit

@Observable
@MainActor
final class VideoPlayerViewModel {
    private let repository: VideoRepository
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var showControlsTask: Task<Void, Never>?

    let video: Video
    let playlist: [Video]
    private(set) var currentIndex: Int

    var player: AVPlayer?
    weak var playerViewController: AVPlayerViewController?
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0

    // MARK: - Up Next State

    private(set) var showUpNext = false
    private(set) var countdown: Int = 5
    private var upNextCancelled = false
    private var lastSaveTime: Date = .distantPast
    private var preloadedItem: AVPlayerItem?
    private(set) var relatedVideos: [Video] = []
    private var isFetchingRelated = false

    // MARK: - Resume State

    private(set) var showResumeOverlay = false
    private(set) var resumeTimeFormatted = ""
    private var resumeDismissTask: Task<Void, Never>?

    // MARK: - Top Comment State

    private(set) var topComment: DumpertComment?
    private(set) var showTopComment = false
    private var topCommentFetched = false
    private var topCommentDismissTask: Task<Void, Never>?


    var autoplayEnabled: Bool { repository.settings.autoplayEnabled }
    private var upNextOverlayEnabled: Bool { repository.settings.upNextOverlayEnabled }
    var upNextCountdownSeconds: Int { repository.settings.upNextCountdownSeconds }
    private var upNextMinimumVideoSeconds: Int { repository.settings.upNextMinimumVideoSeconds }

    var currentVideo: Video {
        playlist.isEmpty ? video : playlist[currentIndex]
    }

    var nextVideo: Video? {
        if currentIndex + 1 < playlist.count {
            return playlist[currentIndex + 1]
        }
        return relatedVideos.first
    }

    var hasNextVideo: Bool { nextVideo != nil }

    init(video: Video, playlist: [Video] = [], repository: VideoRepository) {
        self.video = video
        self.playlist = playlist
        self.repository = repository
        self.currentIndex = playlist.firstIndex(of: video) ?? 0
    }

    func setupPlayer() {
        guard let url = video.streamURL else { return }
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        resumeIfNeeded(for: currentVideo)

        addTimeObserver()
        addEndObserver()
        fetchTopCommentIfNeeded(for: video.id)
    }

    func configureTransportBar() {
        playerViewController?.speeds = [
            AVPlaybackSpeed(rate: 0.5, localizedName: "0.5×"),
            AVPlaybackSpeed(rate: 0.75, localizedName: "0.75×"),
            AVPlaybackSpeed(rate: 1.0, localizedName: String(localized: "Normaal", comment: "Playback speed label for normal (1x) speed")),
            AVPlaybackSpeed(rate: 1.25, localizedName: "1.25×"),
            AVPlaybackSpeed(rate: 1.5, localizedName: "1.5×"),
            AVPlaybackSpeed(rate: 2.0, localizedName: "2×"),
        ]
    }

    func play() {
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
        saveProgress(force: true)
    }

    func cleanup() {
        showControlsTask?.cancel()
        showControlsTask = nil
        resumeDismissTask?.cancel()
        resumeDismissTask = nil
        topCommentDismissTask?.cancel()
        topCommentDismissTask = nil
        saveProgress(force: true)
        removeTimeObserver()
        removeEndObserver()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerViewController?.player = nil
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Up Next Actions

    func skipToNext() {
        showUpNext = false
        playNext()
    }

    func cancelUpNext() {
        upNextCancelled = true
        showUpNext = false
    }

    // MARK: - Progress Tracking

    private func addTimeObserver() {
        let interval = CMTime(seconds: 1, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                self.currentTime = time.seconds
                self.duration = self.player?.currentItem?.duration.seconds ?? 0
                if self.duration.isFinite && self.duration > 0 {
                    self.saveProgress()
                    self.checkUpNext()
                    self.checkTopCommentTiming()
                }
            }
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func addEndObserver() {
        removeEndObserver()
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.onVideoFinished()
            }
        }
    }

    private func removeEndObserver() {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
    }

    private func saveProgress(force: Bool = false) {
        guard duration.isFinite && duration > 0 else { return }
        let now = Date()
        guard force || now.timeIntervalSince(lastSaveTime) >= 5 else { return }
        lastSaveTime = now
        repository.updateWatchProgress(
            videoId: currentVideo.id,
            watchedSeconds: currentTime,
            totalSeconds: duration
        )
    }

    // MARK: - Up Next Logic

    private func checkUpNext() {
        guard autoplayEnabled,
              !upNextCancelled else { return }

        let remaining = duration - currentTime

        // Fetch related videos when near the end and playlist is exhausted
        if remaining <= 30 && currentIndex + 1 >= playlist.count
            && relatedVideos.isEmpty && !isFetchingRelated {
            isFetchingRelated = true
            Task {
                relatedVideos = await repository.fetchRelatedVideos(for: currentVideo.id)
                isFetchingRelated = false
            }
        }

        guard hasNextVideo else { return }

        // Preload next video when <30s remaining
        if remaining <= 30 && preloadedItem == nil,
           let url = nextVideo?.streamURL {
            preloadedItem = AVPlayerItem(url: url)
        }

        guard upNextOverlayEnabled,
              upNextMinimumVideoSeconds == 0 || duration >= Double(upNextMinimumVideoSeconds) else { return }

        if remaining <= Double(upNextCountdownSeconds) && remaining > 0 {
            if !showUpNext {
                showUpNext = true
            }
            countdown = max(1, Int(remaining.rounded(.up)))
        }
    }

    private func onVideoFinished() {
        saveProgress(force: true)

        if autoplayEnabled && hasNextVideo && !upNextCancelled {
            showUpNext = false
            playNext()
        } else {
            showUpNext = false
        }
    }

    func playNext() {
        let targetVideo: Video?
        if currentIndex + 1 < playlist.count {
            currentIndex += 1
            targetVideo = playlist[currentIndex]
        } else if let related = relatedVideos.first {
            targetVideo = related
            relatedVideos.removeFirst()
        } else {
            return
        }

        guard let video = targetVideo, let url = video.streamURL else { return }

        upNextCancelled = false
        showUpNext = false
        resetResume()
        resetTopComment()
        fetchTopCommentIfNeeded(for: video.id)

        playerViewController?.showsPlaybackControls = false

        removeTimeObserver()
        removeEndObserver()
        let item = preloadedItem ?? AVPlayerItem(url: url)
        preloadedItem = nil
        player?.replaceCurrentItem(with: item)

        resumeIfNeeded(for: video)

        addTimeObserver()
        addEndObserver()
        player?.play()

        showControlsTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            self?.playerViewController?.showsPlaybackControls = true
        }
    }

    // MARK: - Top Comment

    private func fetchTopCommentIfNeeded(for itemId: String) {
        guard repository.settings.showTopComment else { return }
        topCommentFetched = false
        Task {
            do {
                let comment = try await repository.fetchTopComment(for: itemId)
                self.topComment = comment
            } catch {
                self.topComment = nil
            }
            self.topCommentFetched = true
        }
    }

    private func checkTopCommentTiming() {
        guard repository.settings.showTopComment,
              topCommentFetched,
              !showTopComment,
              topCommentDismissTask == nil,
              currentTime >= 10 && currentTime < 15 else { return }

        showTopComment = true
        topCommentDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            self?.showTopComment = false
        }
    }

    private func resetTopComment() {
        topCommentDismissTask?.cancel()
        topCommentDismissTask = nil
        topComment = nil
        showTopComment = false
        topCommentFetched = false
    }

    // MARK: - Resume Playback

    private func resumeIfNeeded(for video: Video) {
        guard let progress = repository.watchProgress[video.id],
              progress.watchedSeconds >= 5 else { return }

        let seekTime = CMTime(seconds: progress.watchedSeconds, preferredTimescale: 600)
        player?.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)

        if repository.settings.showResumeOverlay {
            resumeTimeFormatted = Int(progress.watchedSeconds).formattedDuration
            showResumeOverlay = true
            resumeDismissTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(5))
                self?.showResumeOverlay = false
            }
        }
    }

    func playFromBeginning() {
        resumeDismissTask?.cancel()
        resumeDismissTask = nil
        showResumeOverlay = false
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func resetResume() {
        resumeDismissTask?.cancel()
        resumeDismissTask = nil
        showResumeOverlay = false
        resumeTimeFormatted = ""
    }
}
