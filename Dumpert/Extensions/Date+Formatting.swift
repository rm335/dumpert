import Foundation

extension Date {
    private nonisolated(unsafe) static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.unitsStyle = .short
        return f
    }()

    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var relativeString: String {
        Date.relativeFormatter.localizedString(for: self, relativeTo: Date())
    }

    var shortString: String {
        Date.shortFormatter.string(from: self)
    }
}
