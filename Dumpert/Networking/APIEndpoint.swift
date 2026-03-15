import Foundation

enum APIEndpoint {
    case topWeek(date: Date)
    case topMonth(date: Date)
    case hotshiz
    case latest(page: Int)
    case search(query: String, page: Int)
    case info(id: String)
    case classics(page: Int)
    case related(id: String)

    private static let baseURL = "https://post.dumpert.nl/api/v1.0"

    private nonisolated(unsafe) static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private static func weekString(from date: Date) -> String {
        let year = Calendar.current.component(.yearForWeekOfYear, from: date)
        let week = Calendar.current.component(.weekOfYear, from: date)
        return String(format: "%04d-%02d", year, week)
    }

    var url: URL {
        let path: String
        switch self {
        case .topWeek(let date):
            path = "/top5/week/\(Self.weekString(from: date))"
        case .topMonth(let date):
            path = "/top5/maand/\(Self.monthFormatter.string(from: date))"
        case .hotshiz:
            path = "/hotshiz"
        case .latest(let page):
            path = "/latest/\(page)"
        case .search(let query, let page):
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
            path = "/search/\(encoded)/\(page)"
        case .info(let id):
            path = "/info/\(id)"
        case .classics(let page):
            path = "/classics/\(page)"
        case .related(let id):
            path = "/related/\(id)"
        }
        guard let url = URL(string: Self.baseURL + path) else {
            preconditionFailure("Invalid API URL: \(Self.baseURL + path)")
        }
        return url
    }
}
