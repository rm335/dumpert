import Foundation
import os

enum TopShelfDataStore: Sendable {
    static let appGroupIdentifier = "group.nl.dumpert.tvos"
    private static let logger = Logger(subsystem: "nl.dumpert.tvos.topshelf", category: "datastore")
    private static let hotshizKey = "topshelf_hotshiz"

    // MARK: - Diagnostics

    static func diagnose() {
        let process = ProcessInfo.processInfo.processName
        logger.notice("=== TopShelf diagnose from process: \(process) ===")

        // Check container URL
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let exists = FileManager.default.fileExists(atPath: url.path)
            logger.notice("Container URL: \(url.path) exists=\(exists)")
        } else {
            logger.fault("Container URL is nil — App Group NOT provisioned")
        }

        // Check UserDefaults read/write
        if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
            let testKey = "topshelf_diag"
            defaults.set(42, forKey: testKey)
            defaults.synchronize()
            let val = defaults.integer(forKey: testKey)
            logger.notice("UserDefaults test: wrote 42, read \(val) — \(val == 42 ? "OK" : "BROKEN")")
            defaults.removeObject(forKey: testKey)

            // Check if hotshiz data exists
            let hasData = defaults.data(forKey: hotshizKey) != nil
            logger.notice("UserDefaults has hotshiz data: \(hasData)")
        } else {
            logger.fault("UserDefaults(suiteName:) returned nil")
        }
    }

    // MARK: - Save (UserDefaults only)

    static func save(hotshiz: [TopShelfItem]) {
        guard !hotshiz.isEmpty else {
            logger.info("save() called with empty array, skipping")
            return
        }

        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            logger.fault("save: UserDefaults(suiteName:) is nil — App Group not provisioned")
            return
        }

        do {
            let data = try JSONEncoder().encode(hotshiz)
            defaults.set(data, forKey: hotshizKey)
            defaults.synchronize()

            // Verify write succeeded
            let readBack = defaults.data(forKey: hotshizKey)
            if readBack != nil {
                logger.notice("Saved \(hotshiz.count) items (\(data.count) bytes) — verified OK")
            } else {
                logger.fault("Save FAILED — wrote data but readback is nil")
            }
        } catch {
            logger.fault("Encode failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Load

    static func loadHotshiz() -> [TopShelfItem] {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            logger.fault("load: UserDefaults(suiteName:) is nil — App Group not provisioned")
            return []
        }

        guard let data = defaults.data(forKey: hotshizKey) else {
            logger.notice("No hotshiz data in UserDefaults")
            return []
        }

        do {
            let items = try JSONDecoder().decode([TopShelfItem].self, from: data)
            logger.notice("Loaded \(items.count) items from UserDefaults (\(data.count) bytes)")
            return items
        } catch {
            logger.fault("Decode failed: \(error.localizedDescription)")
            return []
        }
    }
}
