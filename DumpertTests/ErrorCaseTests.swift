import Testing
import Foundation
@testable import Dumpert

@Suite("Error Case Tests")
struct ErrorCaseTests {

    @Test("Malformed JSON decoding fails gracefully")
    func malformedJSON() {
        let decoder = JSONDecoder()
        let badData = Data("not json".utf8)
        #expect(throws: (any Error).self) {
            _ = try decoder.decode(DumpertAPIResponse.self, from: badData)
        }
    }

    @Test("Empty JSON object decodes with nil items")
    func emptyJSON() throws {
        let decoder = JSONDecoder()
        let data = Data("{}".utf8)
        let response = try decoder.decode(DumpertAPIResponse.self, from: data)
        #expect(response.items == nil)
    }

    @Test("Missing media field results in nil streamURL")
    func missingMediaField() throws {
        let json = """
        {
            "items": [{
                "id": "test-1",
                "title": "Test",
                "description": "",
                "mediaType": "VIDEO"
            }]
        }
        """
        let decoder = JSONDecoder()
        let response = try decoder.decode(DumpertAPIResponse.self, from: Data(json.utf8))
        let item = response.items!.first!
        let video = Video(from: item)
        #expect(video.streamURL == nil)
    }

    @Test("WatchProgress with negative values")
    func negativeWatchValues() {
        var progress = WatchProgress(videoId: "test", watchedSeconds: -5, totalSeconds: -10)
        // Negative totalSeconds triggers guard: totalSeconds > 0 → false → returns 0
        #expect(progress.progress == 0)
        #expect(!progress.isCompleted)
        progress.update(watchedSeconds: 0, totalSeconds: 0)
        #expect(progress.progress == 0)
    }

    @Test("HTML stripping handles malformed HTML")
    func malformedHTML() {
        let html = "<p>Unclosed <b>tags"
        let stripped = html.strippingHTML()
        // Should not crash, should remove tags
        #expect(!stripped.contains("<"))
    }
}
