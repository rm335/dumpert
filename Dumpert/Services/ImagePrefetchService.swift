import Foundation

/// Prefetches thumbnail images for media items that are about to appear on screen.
/// Uses a simple set-based approach to avoid duplicate downloads.
actor ImagePrefetchService {
    static let shared = ImagePrefetchService()

    private var prefetchingURLs: Set<URL> = []
    private var prefetchTasks: [URL: Task<Void, Never>] = [:]

    /// Prefetch thumbnails for the given items.
    func prefetch(_ items: [MediaItem]) {
        for item in items {
            guard let url = item.thumbnailURL,
                  !prefetchingURLs.contains(url) else { continue }

            prefetchingURLs.insert(url)
            prefetchTasks[url] = Task {
                _ = try? await ImageCacheService.shared.image(for: url)
                prefetchingURLs.remove(url)
                prefetchTasks.removeValue(forKey: url)
            }
        }
    }

    /// Cancel prefetch for items that are no longer needed.
    func cancelPrefetch(_ items: [MediaItem]) {
        for item in items {
            guard let url = item.thumbnailURL else { continue }
            prefetchTasks[url]?.cancel()
            prefetchTasks.removeValue(forKey: url)
            prefetchingURLs.remove(url)
        }
    }
}
