import Testing
@testable import Dumpert

@Suite("Duration Formatter Tests")
struct DurationFormatterTests {

    @Test("Formats seconds under a minute")
    func formatsSecondsUnderMinute() {
        #expect(45.formattedDuration == "0:45")
    }

    @Test("Formats exactly one minute")
    func formatsOneMinute() {
        #expect(60.formattedDuration == "1:00")
    }

    @Test("Formats minutes and seconds")
    func formatsMinutesAndSeconds() {
        #expect(125.formattedDuration == "2:05")
    }

    @Test("Formats zero seconds")
    func formatsZero() {
        #expect(0.formattedDuration == "0:00")
    }

    @Test("Formats long durations")
    func formatsLongDuration() {
        #expect(3661.formattedDuration == "61:01")
    }

    @Test("Pads seconds with leading zero")
    func padsSeconds() {
        #expect(63.formattedDuration == "1:03")
    }
}
