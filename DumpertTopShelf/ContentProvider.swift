@preconcurrency import TVServices
import os

class ContentProvider: TVTopShelfContentProvider {
    private let logger = Logger(subsystem: "nl.dumpert.tvos.topshelf", category: "content")

    // Use completion handler API (more compatible than async override)
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        NSLog("[TopShelf] loadTopShelfContent CALLED")
        logger.notice("=== Top Shelf loadTopShelfContent called ===")
        TopShelfDataStore.diagnose()

        // Try cached data from main app
        let hotshiz = TopShelfDataStore.loadHotshiz()
        NSLog("[TopShelf] loaded \(hotshiz.count) items from cache")

        guard !hotshiz.isEmpty else {
            NSLog("[TopShelf] No items — returning nil")
            logger.fault("No items available — Top Shelf will be empty")
            completionHandler(nil)
            return
        }

        let items = hotshiz.prefix(10).map(makeItem)
        let collection = TVTopShelfItemCollection(items: Array(items))
        collection.title = String(localized: "Trending Nu", comment: "Top Shelf section title for currently trending videos")

        NSLog("[TopShelf] Returning \(items.count) items")
        logger.notice("Returning \(items.count) items for Top Shelf")
        completionHandler(TVTopShelfSectionedContent(sections: [collection]))
    }

    private func makeItem(_ item: TopShelfItem) -> TVTopShelfSectionedItem {
        let shelfItem = TVTopShelfSectionedItem(identifier: item.id)
        shelfItem.title = item.title
        shelfItem.imageShape = .hdtv
        if let url = item.thumbnailURL {
            shelfItem.setImageURL(url, for: .screenScale1x)
            shelfItem.setImageURL(url, for: .screenScale2x)
        }
        if let deepLinkURL = URL(string: "dumpert://video/\(item.id)") {
            shelfItem.playAction = TVTopShelfAction(url: deepLinkURL)
            shelfItem.displayAction = TVTopShelfAction(url: deepLinkURL)
        }
        return shelfItem
    }
}
