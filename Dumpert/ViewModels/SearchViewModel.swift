import Foundation

@Observable
@MainActor
final class SearchViewModel {
    var searchQuery = "" {
        didSet { debounceSearch() }
    }

    var filter = SearchFilter() {
        didSet { applyFilter() }
    }

    private(set) var results: [MediaItem] = []
    private(set) var filteredResults: [MediaItem] = []
    private(set) var isSearching = false
    private(set) var error: String?
    private(set) var currentPage = 0
    private(set) var hasMore = false
    private(set) var isLoadingMore = false
    private(set) var hasSearched = false

    private let apiClient: DumpertAPIClient
    private let repository: VideoRepository
    private var searchTask: Task<Void, Never>?

    // In-memory search cache with 5-minute TTL
    private struct CachedResult {
        let items: [MediaItem]
        let timestamp: Date
        var isExpired: Bool { Date().timeIntervalSince(timestamp) > 300 }
    }
    private var searchCache: [String: CachedResult] = [:]

    init(apiClient: DumpertAPIClient, repository: VideoRepository) {
        self.apiClient = apiClient
        self.repository = repository
    }

    private func debounceSearch() {
        searchTask?.cancel()

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            results = []
            filteredResults = []
            error = nil
            hasSearched = false
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await self?.search()
        }
    }

    func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        let cacheKey = query.lowercased()

        // Check cache first
        if let cached = searchCache[cacheKey], !cached.isExpired {
            results = repository.filteredItems(cached.items)
            filteredResults = filter.apply(to: results)
            hasMore = !cached.items.isEmpty
            hasSearched = true
            return
        }

        isSearching = true
        error = nil
        currentPage = 0

        do {
            let items = try await apiClient.fetchSearch(query: query, page: 0)
            guard !Task.isCancelled else { return }
            searchCache[cacheKey] = CachedResult(items: items, timestamp: Date())
            results = repository.filteredItems(items)
            filteredResults = filter.apply(to: results)
            hasMore = !items.isEmpty
            hasSearched = true
            repository.recordSearch(query)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            self.error = error.localizedDescription
            results = []
            filteredResults = []
            hasSearched = true
        }

        isSearching = false
    }

    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isLoadingMore = true
        let nextPage = currentPage + 1

        do {
            let newItems = try await apiClient.fetchSearch(query: query, page: nextPage)
            guard !Task.isCancelled else { return }
            if newItems.isEmpty {
                hasMore = false
            } else {
                let existingIds = Set(results.map(\.id))
                let unique = repository.filteredItems(newItems).filter { !existingIds.contains($0.id) }
                results.append(contentsOf: unique)
                filteredResults = filter.apply(to: results)
                currentPage = nextPage
            }
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            self.error = error.localizedDescription
        }

        isLoadingMore = false
    }

    private func applyFilter() {
        filteredResults = filter.apply(to: results)
    }

    func resetFilters() {
        filter = SearchFilter()
    }
}
