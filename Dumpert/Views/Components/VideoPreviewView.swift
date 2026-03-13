import SwiftUI
import AVFoundation

/// Plays a muted, looping video preview using AVPlayerLayer.
/// Background is transparent until video frames arrive, letting the thumbnail show through.
/// When `maxDuration` is set, playback loops back to the start after that many seconds.
struct VideoPreviewView: UIViewRepresentable {
    let url: URL
    /// Maximum seconds of video to show. `nil` means play to end.
    var maxDuration: TimeInterval?

    func makeUIView(context: Context) -> VideoPreviewUIView {
        VideoPreviewUIView(url: url, maxDuration: maxDuration)
    }

    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {}

    static func dismantleUIView(_ uiView: VideoPreviewUIView, coordinator: ()) {
        uiView.cleanup()
    }
}

@MainActor
final class VideoPreviewUIView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var endObserver: NSObjectProtocol?
    private var timeObserver: Any?

    init(url: URL, maxDuration: TimeInterval?) {
        super.init(frame: .zero)
        backgroundColor = .clear

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 10

        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.backgroundColor = UIColor.clear.cgColor
        self.layer.addSublayer(layer)

        self.player = player
        self.playerLayer = layer

        if let maxDuration {
            // Loop back to start after maxDuration seconds
            let boundary = CMTime(seconds: maxDuration, preferredTimescale: 600)
            timeObserver = player.addBoundaryTimeObserver(
                forTimes: [NSValue(time: boundary)],
                queue: .main
            ) { [weak player] in
                player?.seek(to: .zero)
                player?.play()
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }

        player.play()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func cleanup() {
        player?.pause()
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        player?.replaceCurrentItem(with: nil)
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        endObserver = nil
        timeObserver = nil
    }
}
