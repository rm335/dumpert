import Testing
import Foundation
@testable import Dumpert

@Suite("Cache Service Tests")
struct CacheServiceTests {

    @Test("Watch progress round-trip")
    func watchProgressRoundTrip() async {
        let cache = CacheService()
        let progress: [String: WatchProgress] = [
            "v1": WatchProgress(videoId: "v1", watchedSeconds: 30, totalSeconds: 100),
            "v2": WatchProgress(videoId: "v2", watchedSeconds: 90, totalSeconds: 100),
        ]

        await cache.saveWatchProgress(progress)
        let loaded = await cache.loadWatchProgress()

        #expect(loaded["v1"]?.watchedSeconds == 30)
        #expect(loaded["v2"]?.watchedSeconds == 90)
        #expect(loaded["v2"]?.isCompleted == true)
    }

    @Test("Settings round-trip")
    func settingsRoundTrip() async {
        let cache = CacheService()
        let settings = UserSettingsSnapshot(
            minimumKudos: 50,
            autoplayEnabled: false,
            hideWatched: true,
            thumbnailPreviewEnabled: false
        )

        await cache.saveSettings(settings)
        let loaded = await cache.loadSettings()

        #expect(loaded.minimumKudos == 50)
        #expect(loaded.autoplayEnabled == false)
    }

    @Test("Curation entries round-trip")
    func curationRoundTrip() async {
        let cache = CacheService()
        let entries = [
            CurationEntry(videoId: "v1", category: .reeten, action: .add),
            CurationEntry(videoId: "v2", category: .dashcam, action: .remove),
        ]

        await cache.saveCurationEntries(entries)
        let loaded = await cache.loadCurationEntries()

        #expect(loaded.count == 2)
        #expect(loaded[0].videoId == "v1")
        #expect(loaded[1].action == .remove)
    }

    @Test("Search history round-trip")
    func searchHistoryRoundTrip() async {
        let cache = CacheService()
        let entries = [
            SearchHistoryEntry(query: "dashcam"),
            SearchHistoryEntry(query: "fail"),
        ]

        await cache.saveSearchHistory(entries)
        let loaded = await cache.loadSearchHistory()

        #expect(loaded.count == 2)
        #expect(loaded[0].query == "dashcam")
    }
}
