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
    case dumpertTV

    private static let baseURL = "https://api.dumpert.nl/mobile_api/json"

    private nonisolated(unsafe) static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var url: URL {
        let path: String
        switch self {
        case .topWeek(let date):
            path = "/top5/week/\(Self.dateFormatter.string(from: date))"
        case .topMonth(let date):
            path = "/top5/maand/\(Self.dateFormatter.string(from: date))"
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
        case .dumpertTV:
            path = "/dumperttv"
        }
        guard let url = URL(string: Self.baseURL + path) else {
            preconditionFailure("Invalid API URL: \(Self.baseURL + path)")
        }
        return url
    }
}
