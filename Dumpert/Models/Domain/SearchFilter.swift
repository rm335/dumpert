import Foundation

struct SearchFilter: Equatable {
    var mediaType: MediaTypeFilter = .all
    var period: PeriodFilter = .all
    var minimumKudos: KudosFilter = .all
    var duration: DurationFilter = .all

    var isActive: Bool {
        mediaType != .all || period != .all || minimumKudos != .all || duration != .all
    }

    func apply(to items: [MediaItem]) -> [MediaItem] {
        items.filter { item in
            matchesMediaType(item) && matchesPeriod(item) && matchesKudos(item) && matchesDuration(item)
        }
    }

    private func matchesMediaType(_ item: MediaItem) -> Bool {
        switch mediaType {
        case .all: true
        case .video: item.isVideo
        case .photo: item.isPhoto
        }
    }

    private func matchesPeriod(_ item: MediaItem) -> Bool {
        guard let date = item.date else { return period == .all }
        switch period {
        case .all: return true
        case .today: return Calendar.current.isDateInToday(date)
        case .thisWeek: return date >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        case .thisMonth: return date >= Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        }
    }

    private func matchesKudos(_ item: MediaItem) -> Bool {
        switch minimumKudos {
        case .all: true
        case .hundred: item.kudosTotal >= 100
        case .fiveHundred: item.kudosTotal >= 500
        case .thousand: item.kudosTotal >= 1000
        }
    }

    private func matchesDuration(_ item: MediaItem) -> Bool {
        switch duration {
        case .all: true
        case .short: item.duration < 60
        case .medium: item.duration >= 60 && item.duration <= 300
        case .long: item.duration > 300
        }
    }
}

enum MediaTypeFilter: String, CaseIterable {
    case all, video, photo

    var displayName: String {
        switch self {
        case .all: String(localized: "Alles")
        case .video: String(localized: "Video")
        case .photo: String(localized: "Foto")
        }
    }

    var icon: String {
        switch self {
        case .all: "square.stack"
        case .video: "play.rectangle"
        case .photo: "photo"
        }
    }
}

enum PeriodFilter: String, CaseIterable {
    case all, today, thisWeek, thisMonth

    var displayName: String {
        switch self {
        case .all: String(localized: "Altijd")
        case .today: String(localized: "Vandaag")
        case .thisWeek: String(localized: "Deze week")
        case .thisMonth: String(localized: "Deze maand")
        }
    }

    var icon: String {
        switch self {
        case .all: "calendar"
        case .today: "sun.max"
        case .thisWeek: "calendar.badge.clock"
        case .thisMonth: "calendar.circle"
        }
    }
}

enum KudosFilter: String, CaseIterable {
    case all, hundred, fiveHundred, thousand

    var displayName: String {
        switch self {
        case .all: String(localized: "Alle kudos")
        case .hundred: "100+"
        case .fiveHundred: "500+"
        case .thousand: "1000+"
        }
    }

    var icon: String { "hand.thumbsup" }
}

enum DurationFilter: String, CaseIterable {
    case all, short, medium, long

    var displayName: String {
        switch self {
        case .all: String(localized: "Alle duur")
        case .short: String(localized: "Kort (<1 min)")
        case .medium: String(localized: "Medium (1-5 min)")
        case .long: String(localized: "Lang (>5 min)")
        }
    }

    var icon: String {
        switch self {
        case .all: "timer"
        case .short: "hare"
        case .medium: "gauge.with.dots.needle.50percent"
        case .long: "tortoise"
        }
    }
}
