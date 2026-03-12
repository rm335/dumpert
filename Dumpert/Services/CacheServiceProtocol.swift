import Foundation

/// Protocol for the cache service, enabling test mocking.
protocol CacheServiceProtocol: Sendable {
    func loadSettings() -> UserSettingsSnapshot
    func saveSettings(_ settings: UserSettingsSnapshot)
    func loadWatchProgress() -> [String: WatchProgress]
    func saveWatchProgress(_ progress: [String: WatchProgress])
    func loadCurationEntries() -> [CurationEntry]
    func saveCurationEntries(_ entries: [CurationEntry])
    func loadSearchHistory() -> [SearchHistoryEntry]
    func saveSearchHistory(_ entries: [SearchHistoryEntry])
    func loadCachedMediaItems(for key: String) -> [MediaItem]?
    func cacheMediaItems(_ items: [MediaItem], for key: String)
    func clearCache()
    func cacheSize() -> Int
}

extension CacheService: @preconcurrency CacheServiceProtocol {}
