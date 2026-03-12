import Testing
import Foundation
@testable import Dumpert

@Suite("Domain Model Tests")
struct ModelTests {

    @Test("WatchProgress marks completed at 90%")
    func watchProgressCompletion() {
        var progress = WatchProgress(videoId: "test", watchedSeconds: 0, totalSeconds: 100)
        #expect(!progress.isCompleted)

        progress.update(watchedSeconds: 89, totalSeconds: 100)
        #expect(!progress.isCompleted)

        progress.update(watchedSeconds: 90, totalSeconds: 100)
        #expect(progress.isCompleted)

        progress.update(watchedSeconds: 100, totalSeconds: 100)
        #expect(progress.isCompleted)
    }

    @Test("WatchProgress calculates progress fraction")
    func watchProgressFraction() {
        let progress = WatchProgress(videoId: "test", watchedSeconds: 50, totalSeconds: 100)
        #expect(progress.progress == 0.5)
    }

    @Test("WatchProgress handles zero total")
    func watchProgressZeroTotal() {
        let progress = WatchProgress(videoId: "test", watchedSeconds: 0, totalSeconds: 0)
        #expect(progress.progress == 0)
        #expect(!progress.isCompleted)
    }

    @Test("CurationEntry creates with current timestamp")
    func curationEntryTimestamp() {
        let before = Date()
        let entry = CurationEntry(videoId: "v1", category: .reeten, action: .add)
        let after = Date()

        #expect(entry.videoId == "v1")
        #expect(entry.category == .reeten)
        #expect(entry.action == .add)
        #expect(entry.timestamp >= before)
        #expect(entry.timestamp <= after)
    }

    @Test("UserSettingsSnapshot default values")
    func settingsDefaults() {
        let settings = UserSettingsSnapshot()
        #expect(settings.minimumKudos == 0)
        #expect(settings.autoplayEnabled == true)
        #expect(settings.hideWatched == true)
        #expect(settings.thumbnailPreviewEnabled == true)
    }

    @Test("UserSettingsSnapshot codable round-trip")
    func settingsCodable() throws {
        let settings = UserSettingsSnapshot(minimumKudos: 50, autoplayEnabled: true, hideWatched: true, thumbnailPreviewEnabled: false)
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(UserSettingsSnapshot.self, from: data)

        #expect(decoded.minimumKudos == 50)
        #expect(decoded.autoplayEnabled == true)
        #expect(decoded.hideWatched == true)
        #expect(decoded.thumbnailPreviewEnabled == false)
    }

    @Test("VideoCategory search queries")
    func categorySearchQueries() {
        #expect(VideoCategory.reeten.searchQuery == "dumpertreeten")
        #expect(VideoCategory.vrijmico.searchQuery == "vrijmico")
        #expect(VideoCategory.dashcam.searchQuery == "dashcam")
    }

    @Test("HTML stripping")
    func htmlStripping() {
        let html = "<p>Dit is een <b>test</b> &amp; meer</p>"
        let stripped = html.strippingHTML()
        #expect(stripped == "Dit is een test & meer")
    }

    @Test("HTML stripping empty string")
    func htmlStrippingEmpty() {
        #expect("".strippingHTML() == "")
    }
}
