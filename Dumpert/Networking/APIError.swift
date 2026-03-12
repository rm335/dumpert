import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case httpError(statusCode: Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            String(localized: "Ongeldige URL", comment: "Error when URL is malformed")
        case .networkError(let error):
            String(localized: "Netwerkfout: \(error.localizedDescription)", comment: "Error when network request fails")
        case .decodingError(let error):
            String(localized: "Data kon niet gelezen worden: \(error.localizedDescription)", comment: "Error when JSON decoding fails")
        case .httpError(let statusCode):
            String(localized: "Server fout (HTTP \(statusCode))", comment: "Error for HTTP error status code")
        case .noData:
            String(localized: "Geen data ontvangen", comment: "Error when server returns no data")
        }
    }
}
