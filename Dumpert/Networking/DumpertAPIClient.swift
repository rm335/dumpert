import Foundation
import os

actor DumpertAPIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private var etags: [URL: String] = [:]
    private var cachedResponses: [URL: Data] = [:]
    private let maxCachedResponses = 50

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 300
        config.httpAdditionalHeaders = [
            "Accept": "application/json"
        ]
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    private static let userAgent = "DumpertTV/1.0 (tvOS; unofficial)"

    private func fetch(endpoint: APIEndpoint) async throws -> DumpertAPIResponse {
        let url = endpoint.url
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        // Conditional request with ETag
        if let etag = etags[url] {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        // Handle 304 Not Modified
        if httpResponse.statusCode == 304, let cached = cachedResponses[url] {
            return try decoder.decode(DumpertAPIResponse.self, from: cached)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Store ETag and cache response (capped to prevent unbounded growth)
        if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
            if cachedResponses.count >= maxCachedResponses {
                // Evict oldest entry (first key)
                if let oldest = etags.keys.first(where: { $0 != url }) {
                    etags.removeValue(forKey: oldest)
                    cachedResponses.removeValue(forKey: oldest)
                }
            }
            etags[url] = etag
            cachedResponses[url] = data
        }

        do {
            return try decoder.decode(DumpertAPIResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func fetchWithRetry(endpoint: APIEndpoint, maxRetries: Int = 3) async throws -> DumpertAPIResponse {
        var lastError: Error?
        for attempt in 0..<maxRetries {
            do {
                return try await fetch(endpoint: endpoint)
            } catch let error as APIError {
                // Only retry on 5xx server errors
                if case .httpError(let statusCode) = error, (500...599).contains(statusCode) {
                    lastError = error
                    let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                    try await Task.sleep(nanoseconds: delay)
                    continue
                }
                throw error
            } catch {
                // Retry on network errors
                lastError = error
                let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                try await Task.sleep(nanoseconds: delay)
            }
        }
        throw lastError ?? APIError.noData
    }

    private func fetchMediaItems(endpoint: APIEndpoint) async throws -> [MediaItem] {
        let response = try await fetchWithRetry(endpoint: endpoint)
        return (response.items ?? []).map { MediaItem(from: $0) }
    }

    // MARK: - Public API

    func fetchHotshiz() async throws -> [MediaItem] {
        try await fetchMediaItems(endpoint: .hotshiz)
    }

    func fetchTopWeek(date: Date = Date()) async throws -> [MediaItem] {
        try await fetchMediaItems(endpoint: .topWeek(date: date))
    }

    func fetchTopMonth(date: Date = Date()) async throws -> [MediaItem] {
        try await fetchMediaItems(endpoint: .topMonth(date: date))
    }

    func fetchLatest(page: Int = 0) async throws -> [MediaItem] {
        try await fetchMediaItems(endpoint: .latest(page: page))
    }

    func fetchSearch(query: String, page: Int = 0) async throws -> [MediaItem] {
        try await fetchMediaItems(endpoint: .search(query: query, page: page))
    }

    func fetchClassics(page: Int = 0) async throws -> [MediaItem] {
        try await fetchMediaItems(endpoint: .classics(page: page))
    }

    func fetchRelated(id: String) async throws -> [MediaItem] {
        try await fetchMediaItems(endpoint: .related(id: id))
    }

    func fetchDumpertTV() async throws -> [MediaItem] {
        try await fetchMediaItems(endpoint: .dumpertTV)
    }

    // MARK: - Comments API

    private static let commentsBaseURL = "https://comments.dumpert.nl/api/v1.0"

    func fetchTopComments(for itemId: String) async throws -> [DumpertComment] {
        // Convert underscore ID (100146773_1e4d8897) to slash format (100146773/1e4d8897)
        let slashId = itemId.replacingOccurrences(of: "_", with: "/")
        guard let url = URL(string: "\(Self.commentsBaseURL)/articles/\(slashId)/comments/?includeitems=1") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        var lastError: Error?
        for attempt in 0..<3 {
            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    if (500...599).contains(statusCode) {
                        lastError = APIError.httpError(statusCode: statusCode)
                        let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                        try await Task.sleep(nanoseconds: delay)
                        continue
                    }
                    throw APIError.httpError(statusCode: statusCode)
                }

                let commentsResponse = try decoder.decode(CommentsAPIResponse.self, from: data)
                let comments = commentsResponse.data?.comments ?? []

                // Return all non-banned comments sorted by kudos descending
                return comments
                    .filter { $0.banned != true }
                    .sorted { $0.kudosCount > $1.kudosCount }
            } catch let error as APIError {
                throw error
            } catch {
                // Retry on network errors (URLError, connection failures, etc.)
                lastError = error
                let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                try await Task.sleep(nanoseconds: delay)
            }
        }
        throw lastError ?? APIError.noData
    }
}
