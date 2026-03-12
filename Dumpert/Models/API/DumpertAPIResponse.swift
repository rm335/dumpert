import Foundation

struct DumpertAPIResponse: Codable {
    let gentime: Double?
    let items: [DumpertItem]?
    let success: Bool?
}
