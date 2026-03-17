@preconcurrency import AVFoundation

@Observable
@MainActor
final class LoadingSoundPlayer {
    private var audioPlayer: AVAudioPlayer?
    private var fadeTask: Task<Void, Never>?
    private var autoStopTask: Task<Void, Never>?

    func playRandom() {
        stop()
        let urls = soundURLs()
        guard let url = urls.randomElement() else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            autoStopTask = Task {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                fadeOutAndStop()
            }
        } catch {
            // Sound playback is non-critical
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
