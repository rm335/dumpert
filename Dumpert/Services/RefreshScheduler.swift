import Foundation

@Observable
@MainActor
final class RefreshScheduler {
    private var timer: Timer?
    private let interval: TimeInterval = 15 * 60 // 15 minutes
    var onRefresh: (() async -> Void)?

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.onRefresh?()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refreshNow() {
        Task {
            await onRefresh?()
        }
    }
}
