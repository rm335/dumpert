import MediaPlayer
import os

@MainActor
final class NowPlayingService {
    private var commandTargets: [Any] = []
    private nonisolated static let logger = Logger(subsystem: "nl.dumpert.tvos", category: "nowplaying")

    func configure(
        title: String,
        thumbnailURL: URL?,
        duration: Double,
        onPlay: @escaping @MainActor () -> Void,
        onPause: @escaping @MainActor () -> Void,
        onSkipForward: @escaping @MainActor () -> Void,
        onSkipBackward: @escaping @MainActor () -> Void,
        onSeek: @escaping @MainActor (TimeInterval) -> Void
    ) {
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
        ]

        configureCommands(
            onPlay: onPlay,
            onPause: onPause,
            onSkipForward: onSkipForward,
            onSkipBackward: onSkipBackward,
            onSeek: onSeek
        )

        if let thumbnailURL {
            loadArtwork(from: thumbnailURL)
        }
    }

    func updateProgress(currentTime: Double, duration: Double, rate: Float) {
        let center = MPNowPlayingInfoCenter.default()
        var info = center.nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate
        center.nowPlayingInfo = info
    }

    func cleanup() {
        let commandCenter = MPRemoteCommandCenter.shared()
        for target in commandTargets {
            commandCenter.playCommand.removeTarget(target)
            commandCenter.pauseCommand.removeTarget(target)
            commandCenter.skipForwardCommand.removeTarget(target)
            commandCenter.skipBackwardCommand.removeTarget(target)
            commandCenter.changePlaybackPositionCommand.removeTarget(target)
        }
        commandTargets.removeAll()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Private

    private func configureCommands(
        onPlay: @escaping @MainActor () -> Void,
        onPause: @escaping @MainActor () -> Void,
        onSkipForward: @escaping @MainActor () -> Void,
        onSkipBackward: @escaping @MainActor () -> Void,
        onSeek: @escaping @MainActor (TimeInterval) -> Void
    ) {
        // Remove previous targets
        cleanup()

        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        let playTarget = commandCenter.playCommand.addTarget { _ in
            Task { @MainActor in onPlay() }
            return .success
        }
        commandTargets.append(playTarget)

        commandCenter.pauseCommand.isEnabled = true
        let pauseTarget = commandCenter.pauseCommand.addTarget { _ in
            Task { @MainActor in onPause() }
            return .success
        }
        commandTargets.append(pauseTarget)

        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        let skipFwdTarget = commandCenter.skipForwardCommand.addTarget { _ in
            Task { @MainActor in onSkipForward() }
            return .success
        }
        commandTargets.append(skipFwdTarget)

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        let skipBwdTarget = commandCenter.skipBackwardCommand.addTarget { _ in
            Task { @MainActor in onSkipBackward() }
            return .success
        }
        commandTargets.append(skipBwdTarget)

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        let seekTarget = commandCenter.changePlaybackPositionCommand.addTarget { event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in onSeek(positionEvent.positionTime) }
            return .success
        }
        commandTargets.append(seekTarget)

        // Disable unsupported commands
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
    }

    private func loadArtwork(from url: URL) {
        Task.detached(priority: .utility) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return }
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                await MainActor.run {
                    var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                    info[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                }
            } catch {
                Self.logger.warning("Failed to load artwork: \(error.localizedDescription)")
            }
        }
    }
}
