import Foundation

@Observable
@MainActor
final class RefreshScheduler {
    private var timer: Timer?
    private let interval: TimeInterval = 15 * 60 // 15 minutes
    var onRefresh: (() async -> Void)?

    func start() {
        stop()
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.onRefresh?()
            }
        }
        t.tolerance = interval * 0.10
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refreshNow() {
        Task { [weak self] in
            await self?.onRefresh?()
        }
    }
}
