import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Environment(LoadingSoundPlayer.self) private var soundPlayer
    let viewModel: VideoPlayerViewModel

    var body: some View {
        PlayerRepresentable(viewModel: viewModel)
            .ignoresSafeArea()
            .onAppear {
                soundPlayer.fadeOutAndStop()
            }
            .onDisappear {
                viewModel.cleanup()
            }
    }
}

// MARK: - AVPlayerViewController Wrapper

private struct PlayerRepresentable: UIViewControllerRepresentable {
    let viewModel: VideoPlayerViewModel

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        viewModel.setupPlayer()
        viewModel.playerViewController = controller
        controller.player = viewModel.player
        controller.delegate = context.coordinator

        let overlay = UpNextOverlayContainer(viewModel: viewModel)
        let hosting = UIHostingController(rootView: overlay)
        hosting.view.backgroundColor = .clear
        hosting.view.isUserInteractionEnabled = true
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        controller.addChild(hosting)
        if let contentOverlay = controller.contentOverlayView {
            contentOverlay.addSubview(hosting.view)
            NSLayoutConstraint.activate([
                hosting.view.topAnchor.constraint(equalTo: contentOverlay.topAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: contentOverlay.bottomAnchor),
                hosting.view.leadingAnchor.constraint(equalTo: contentOverlay.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: contentOverlay.trailingAnchor),
            ])
        }
        hosting.didMove(toParent: controller)

        // Play/pause is ALWAYS intercepted so AVPlayerViewController's native
        // handler can never seek to a stale transport bar position (0:00).
        // Select is only intercepted while controls are hidden to reveal them.
        let playPauseTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePlayPause))
        playPauseTap.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        controller.view.addGestureRecognizer(playPauseTap)
        context.coordinator.playPauseGesture = playPauseTap

        let selectTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSelect))
        selectTap.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        selectTap.delegate = context.coordinator
        controller.view.addGestureRecognizer(selectTap)

        viewModel.configureTransportBar()
        viewModel.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Overlay updates handled by @Observable viewModel
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        uiViewController.player?.pause()
        uiViewController.player = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    @MainActor
    class Coordinator: NSObject, @preconcurrency AVPlayerViewControllerDelegate, UIGestureRecognizerDelegate {
        private let viewModel: VideoPlayerViewModel
        var playPauseGesture: UITapGestureRecognizer?

        init(viewModel: VideoPlayerViewModel) {
            self.viewModel = viewModel
        }

        func playerViewControllerWillBeginDismissalTransition(_ playerViewController: AVPlayerViewController) {
            viewModel.cleanup()
        }

        // MARK: - Remote Control Handling

        /// Play/pause is always handled by us (no delegate check needed —
        /// that gesture has no delegate set). Select is only intercepted
        /// while controls are hidden; once visible, native handling takes over.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            viewModel.playerViewController?.showsPlaybackControls == false
        }

        @objc func handlePlayPause() {
            guard let player = viewModel.player else { return }
            if player.timeControlStatus == .playing {
                player.pause()
            } else {
                player.play()
            }
            // Show controls on any play/pause interaction
            viewModel.playerViewController?.showsPlaybackControls = true
        }

        @objc func handleSelect() {
            viewModel.playerViewController?.showsPlaybackControls = true
        }
    }
}

// MARK: - UpNext Overlay Container

/// Wrapper that observes the viewModel and shows/hides the UpNext overlay.
/// Hosted inside AVPlayerViewController's contentOverlayView so it renders
/// above the video on tvOS.
private struct UpNextOverlayContainer: View {
    let viewModel: VideoPlayerViewModel

    var body: some View {
        ZStack {
            // Resume overlay (top-left)
            ResumeOverlayView(
                formattedTime: viewModel.resumeTimeFormatted,
                isVisible: viewModel.showResumeOverlay,
                onPlayFromBeginning: { viewModel.playFromBeginning() }
            )

            // Now playing title (top-center, shown briefly on autoplay)
            NowPlayingOverlayView(
                title: viewModel.nowPlayingTitle,
                isVisible: viewModel.showNowPlaying
            )

            // Top comment overlay (bottom-left)
            TopCommentOverlayView(
                comment: viewModel.currentTopComment,
                isVisible: viewModel.showTopComment
            )

            // Up next overlay (bottom-right)
            if viewModel.showUpNext, let next = viewModel.nextVideo {
                UpNextOverlayView(
                    nextVideo: next,
                    countdown: viewModel.countdown,
                    totalCountdown: viewModel.upNextCountdownSeconds,
                    onPlayNow: { viewModel.skipToNext() },
                    onCancel: { viewModel.cancelUpNext() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(duration: 0.5, bounce: 0.2), value: viewModel.showUpNext)
            }
        }
    }
}
