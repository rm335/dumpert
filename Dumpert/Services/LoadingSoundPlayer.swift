@preconcurrency import AVFoundation
import os.log

@Observable
@MainActor
final class LoadingSoundPlayer {
    private var audioPlayer: AVAudioPlayer?
    private var fadeTask: Task<Void, Never>?
    private var autoStopTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "nl.dumpert.tvos", category: "sound")

    func playRandom() {
        stop()
        configureAudioSession()
        let urls = soundURLs()
        guard let url = urls.randomElement() else {
            logger.warning("No sound files found in bundle")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            audioPlayer = player
            player.prepareToPlay()
            guard player.play() else {
                logger.warning("AVAudioPlayer.play() returned false for \(url.lastPathComponent)")
                return
            }
            autoStopTask = Task {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                fadeOutAndStop()
            }
        } catch {
            logger.warning("Failed to play sound: \(error.localizedDescription)")
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient)
            try session.setActive(true)
        } catch {
            logger.warning("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    func fadeOutAndStop() {
        autoStopTask?.cancel()
        guard let player = audioPlayer, player.isPlaying else {
            audioPlayer = nil
            return
        }
        fadeTask = Task {
            let originalVolume = player.volume
            let steps = 10
            for step in 1...steps {
                guard !Task.isCancelled else { break }
                player.volume = originalVolume * (1.0 - Float(step) / Float(steps))
                try? await Task.sleep(for: .milliseconds(50))
            }
            player.stop()
            self.audioPlayer = nil
        }
    }

    func stop() {
        autoStopTask?.cancel()
        fadeTask?.cancel()
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func soundURLs() -> [URL] {
        if let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil), !urls.isEmpty {
            return urls
        }
        if let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "Sounds"), !urls.isEmpty {
            return urls
        }
        return []
    }
}
