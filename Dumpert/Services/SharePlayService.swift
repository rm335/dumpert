import GroupActivities
import AVFoundation
import Combine
import os

@Observable
@MainActor
final class SharePlayService {
    private(set) var isSharePlayActive = false
    private(set) var participantCount = 0

    private var groupSession: GroupSession<WatchTogetherActivity>?
    private var subscriptions = Set<AnyCancellable>()
    private var sessionTask: Task<Void, Never>?
    private static let logger = Logger(subsystem: "nl.dumpert.tvos", category: "shareplay")

    func observeSessions() {
        sessionTask = Task {
            for await session in WatchTogetherActivity.sessions() {
                self.configureSession(session)
            }
        }
    }

    func coordinatePlayback(with player: AVPlayer) {
        guard let session = groupSession else { return }
        player.playbackCoordinator.coordinateWithSession(session)
        Self.logger.info("AVPlayer coordinated with GroupSession")
    }

    func startActivity(for video: Video) async throws {
        guard let streamURL = video.streamURL else { return }
        let activity = WatchTogetherActivity(
            videoId: video.id,
            title: video.title,
            streamURL: streamURL,
            thumbnailURL: video.thumbnailURL
        )

        switch await activity.prepareForActivation() {
        case .activationPreferred:
            _ = try await activity.activate()
            Self.logger.info("SharePlay activity activated for \(video.title)")
        case .activationDisabled:
            Self.logger.info("SharePlay activation disabled by user")
        case .cancelled:
            Self.logger.info("SharePlay activation cancelled")
        @unknown default:
            break
        }
    }

    func endSession() {
        groupSession?.end()
        cleanup()
    }

    func cancelObservation() {
        sessionTask?.cancel()
        sessionTask = nil
        cleanup()
    }

    // MARK: - Private

    private func configureSession(_ session: GroupSession<WatchTogetherActivity>) {
        groupSession = session
        isSharePlayActive = true

        session.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case .invalidated = state {
                    self?.cleanup()
                }
            }
            .store(in: &subscriptions)

        session.$activeParticipants
            .receive(on: DispatchQueue.main)
            .sink { [weak self] participants in
                self?.participantCount = participants.count
            }
            .store(in: &subscriptions)

        session.join()
        Self.logger.info("Joined SharePlay session with activity: \(session.activity.title)")
    }

    private func cleanup() {
        subscriptions.removeAll()
        groupSession = nil
        isSharePlayActive = false
        participantCount = 0
    }
}
