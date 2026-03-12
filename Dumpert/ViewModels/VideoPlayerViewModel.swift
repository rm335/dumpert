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


    var autoplayEnabled: Bool { repository.settings.autoplayEnabled }
    private var upNextOverlayEnabled: Bool { repository.settings.upNextOverlayEnabled }
    var upNextCountdownSeconds: Int { repository.settings.upNextCountdownSeconds }
    private var upNextMinimumVideoSeconds: Int { repository.settings.upNextMinimumVideoSeconds }

    var currentVideo: Video {
        playlist.isEmpty ? video : playlist[currentIndex]
    }

    var nextVideo: Video? {
        guard currentIndex + 1 < playlist.count else { return nil }
        return playlist[currentIndex + 1]
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

        addTimeObserver()
        addEndObserver()
    }

    func configureTransportBar() {
        playerViewController?.speeds = [
            AVPlaybackSpeed(rate: 0.5, localizedName: "0.5×"),
            AVPlaybackSpeed(rate: 0.75, localizedName: "0.75×"),
            AVPlaybackSpeed(rate: 1.0, localizedName: "Normaal"),
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
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentTime = time.seconds
                self.duration = self.player?.currentItem?.duration.seconds ?? 0
                if self.duration.isFinite && self.duration > 0 {
                    self.saveProgress()
                    self.checkUpNext()
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
            guard let self else { return }
            Task { @MainActor in
                self.onVideoFinished()
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
              hasNextVideo,
              !upNextCancelled else { return }

        let remaining = duration - currentTime

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
        guard currentIndex + 1 < playlist.count else { return }
        currentIndex += 1
        let nextVideo = playlist[currentIndex]
        guard let url = nextVideo.streamURL else { return }

        upNextCancelled = false
        showUpNext = false

        playerViewController?.showsPlaybackControls = false

        removeTimeObserver()
        removeEndObserver()
        let item = preloadedItem ?? AVPlayerItem(url: url)
        preloadedItem = nil
        player?.replaceCurrentItem(with: item)
        addTimeObserver()
        addEndObserver()
        player?.play()

        showControlsTask = Task {
            try? await Task.sleep(for: .seconds(1))
            playerViewController?.showsPlaybackControls = true
        }
    }
}
