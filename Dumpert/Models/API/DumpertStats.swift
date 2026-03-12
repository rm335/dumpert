import Foundation

struct DumpertStats: Codable {
    let kudosToday: Int?
    let kudosTotal: Int?
    let viewsToday: Int?
    let viewsTotal: Int?

    enum CodingKeys: String, CodingKey {
        case kudosToday = "kudos_today"
        case kudosTotal = "kudos_total"
        case viewsToday = "views_today"
        case viewsTotal = "views_total"
    }
}
