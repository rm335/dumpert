import UIKit
import os

/// Disk cache for upgraded video thumbnails.
/// Stores JPEG images keyed by media item ID.
actor ThumbnailUpgradeDiskCache {
    private let cacheDirectory: URL
    private let maxDiskSize: Int = 50 * 1024 * 1024 // 50MB

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = caches.appendingPathComponent("ThumbnailUpgrades", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Returns the file URL for a cached upgraded thumbnail, or nil if not cached.
    func cachedFileURL(for itemId: String) -> URL? {
        let url = cacheDirectory.appendingPathComponent("\(itemId).jpg")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Saves an upgraded thumbnail image to disk.
    func save(image: UIImage, for itemId: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        var url = cacheDirectory.appendingPathComponent("\(itemId).jpg")
        do {
            try data.write(to: url, options: .atomic)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? url.setResourceValues(resourceValues)
        } catch {
            Logger.thumbnail.warning("Failed to cache upgraded thumbnail for \(itemId): \(error.localizedDescription)")
        }
        evictIfNeeded()
    }

    /// Clears all cached upgraded thumbnails.
    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Returns total disk usage in bytes.
    func diskSize() -> Int {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total = 0
        for case let fileURL as URL in enumerator {
            total += (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        }
        return total
    }

    // MARK: - Eviction

    private func evictIfNeeded() {
        let cacheURL = cacheDirectory
        let maxSize = maxDiskSize
        Task.detached(priority: .utility) {
            let fm = FileManager.default
            let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
            guard let allFiles = try? fm.contentsOfDirectory(
                at: cacheURL,
                includingPropertiesForKeys: keys
            ) else { return }

            var currentSize = 0
            var files: [(url: URL, date: Date, size: Int)] = []
            for fileURL in allFiles {
                let values = try? fileURL.resourceValues(forKeys: Set(keys))
                let size = values?.fileSize ?? 0
                currentSize += size
                files.append((
                    url: fileURL,
                    date: values?.contentModificationDate ?? .distantPast,
                    size: size
                ))
            }
            guard currentSize > maxSize else { return }

            files.sort { $0.date < $1.date }

            let targetSize = maxSize * 3 / 4
            var freed = 0
            let bytesToFree = currentSize - targetSize

            for file in files {
                guard freed < bytesToFree else { break }
                try? fm.removeItem(at: file.url)
                freed += file.size
            }
        }
    }
}
