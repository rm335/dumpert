import Testing
import Foundation
@testable import Dumpert

@Suite("Search Filter Tests")
struct SearchFilterTests {

    @Test("Default filter returns all items")
    func defaultFilterReturnsAll() {
        let filter = SearchFilter()
        #expect(!filter.isActive)
        #expect(filter.mediaType == .all)
        #expect(filter.period == .all)
        #expect(filter.minimumKudos == .all)
        #expect(filter.duration == .all)
    }

    @Test("Filter is active when mediaType set")
    func filterActiveOnMediaType() {
        var filter = SearchFilter()
        filter.mediaType = .video
        #expect(filter.isActive)
    }

    @Test("Filter is active when period set")
    func filterActiveOnPeriod() {
        var filter = SearchFilter()
        filter.period = .thisWeek
        #expect(filter.isActive)
    }

    @Test("Filter is active when minimumKudos set")
    func filterActiveOnKudos() {
        var filter = SearchFilter()
        filter.minimumKudos = .hundred
        #expect(filter.isActive)
    }

    @Test("Filter is active when duration set")
    func filterActiveOnDuration() {
        var filter = SearchFilter()
        filter.duration = .long
        #expect(filter.isActive)
    }
}
