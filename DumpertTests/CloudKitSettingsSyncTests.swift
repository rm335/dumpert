import Testing
import Foundation
import CloudKit
@testable import Dumpert

/// Regression tests for the CloudKit settings sync round-trip.
///
/// Originally, several settings fields (reetenMinimumMinutes, nsfwEnabled,
/// smartThumbnailsEnabled, tileSize, remoteSkipMode, showResumeOverlay) were
/// written by the UI but never serialized to CloudKit. The merge step in
/// VideoRepository.applyCloudKitChanges would then construct a snapshot with
/// hard-coded defaults for those fields and overwrite the user's local value
/// any time another device pushed a newer record. These tests pin the symmetry
/// between `populate(record:with:)` and `makeSettings(from:fallback:)`.
@Suite("CloudKit Settings Sync Tests")
struct CloudKitSettingsSyncTests {

    private func makeRecord() -> CKRecord {
        CKRecord(recordType: "UserSettings", recordID: CKRecord.ID(recordName: "test"))
    }

    private func nonDefaultSnapshot() -> UserSettingsSnapshot {
        UserSettingsSnapshot(
            minimumKudos: 100,
            autoplayEnabled: false,
            hideWatched: false,
            reetenMinimumMinutes: 20,
            showNegativeKudos: true,
            nsfwEnabled: false,
            thumbnailPreviewEnabled: false,
            smartThumbnailsEnabled: false,
            tileSize: .large,
            upNextOverlayEnabled: false,
            upNextCountdownSeconds: 10,
            upNextMinimumVideoSeconds: 120,
            topCommentMode: .single,
            readingSpeed: .veryFast,
            remoteSkipMode: .off,
            showResumeOverlay: false,
            lastModified: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    @Test("All settings fields round-trip through a CKRecord")
    func roundTripAllFields() {
        let original = nonDefaultSnapshot()
        let record = makeRecord()
        CloudKitService.populate(record: record, with: original)

        // Fallback must use distantPast lastModified so the test can prove the
        // record's lastModified is what wins, not the fallback.
        var fallback = UserSettingsSnapshot()
        fallback.lastModified = .distantPast
        let restored = CloudKitService.makeSettings(from: record, fallback: fallback)

        #expect(restored.minimumKudos == original.minimumKudos)
        #expect(restored.autoplayEnabled == original.autoplayEnabled)
        #expect(restored.hideWatched == original.hideWatched)
        #expect(restored.reetenMinimumMinutes == original.reetenMinimumMinutes)
        #expect(restored.showNegativeKudos == original.showNegativeKudos)
        #expect(restored.nsfwEnabled == original.nsfwEnabled)
        #expect(restored.thumbnailPreviewEnabled == original.thumbnailPreviewEnabled)
        #expect(restored.smartThumbnailsEnabled == original.smartThumbnailsEnabled)
        #expect(restored.tileSize == original.tileSize)
        #expect(restored.upNextOverlayEnabled == original.upNextOverlayEnabled)
        #expect(restored.upNextCountdownSeconds == original.upNextCountdownSeconds)
        #expect(restored.upNextMinimumVideoSeconds == original.upNextMinimumVideoSeconds)
        #expect(restored.topCommentMode == original.topCommentMode)
        #expect(restored.readingSpeed == original.readingSpeed)
        #expect(restored.remoteSkipMode == original.remoteSkipMode)
        #expect(restored.showResumeOverlay == original.showResumeOverlay)
        #expect(restored.lastModified == original.lastModified)
    }

    @Test("Empty record falls back to provided snapshot for every field")
    func emptyRecordPreservesFallback() {
        // Simulates a record written by an older client that didn't include
        // these fields — the merge must NOT clobber the user's local values
        // with hard-coded defaults.
        let fallback = nonDefaultSnapshot()
        let restored = CloudKitService.makeSettings(from: makeRecord(), fallback: fallback)

        #expect(restored.minimumKudos == fallback.minimumKudos)
        #expect(restored.autoplayEnabled == fallback.autoplayEnabled)
        #expect(restored.hideWatched == fallback.hideWatched)
        #expect(restored.reetenMinimumMinutes == fallback.reetenMinimumMinutes)
        #expect(restored.showNegativeKudos == fallback.showNegativeKudos)
        #expect(restored.nsfwEnabled == fallback.nsfwEnabled)
        #expect(restored.thumbnailPreviewEnabled == fallback.thumbnailPreviewEnabled)
        #expect(restored.smartThumbnailsEnabled == fallback.smartThumbnailsEnabled)
        #expect(restored.tileSize == fallback.tileSize)
        #expect(restored.upNextOverlayEnabled == fallback.upNextOverlayEnabled)
        #expect(restored.upNextCountdownSeconds == fallback.upNextCountdownSeconds)
        #expect(restored.upNextMinimumVideoSeconds == fallback.upNextMinimumVideoSeconds)
        #expect(restored.topCommentMode == fallback.topCommentMode)
        #expect(restored.readingSpeed == fallback.readingSpeed)
        #expect(restored.remoteSkipMode == fallback.remoteSkipMode)
        #expect(restored.showResumeOverlay == fallback.showResumeOverlay)
    }

    @Test("Partial record only overrides fields actually present")
    func partialRecordPreservesUnsetFields() {
        // Record carries the user's new minimumKudos and tileSize change only.
        // Every other field should keep the local fallback value.
        let fallback = nonDefaultSnapshot()
        let record = makeRecord()
        record["minimumKudos"] = 250 as CKRecordValue
        record["tileSize"] = TileSize.small.rawValue as CKRecordValue
        record["lastModified"] = Date(timeIntervalSince1970: 1_800_000_000) as CKRecordValue

        let restored = CloudKitService.makeSettings(from: record, fallback: fallback)

        #expect(restored.minimumKudos == 250)
        #expect(restored.tileSize == .small)
        #expect(restored.lastModified == Date(timeIntervalSince1970: 1_800_000_000))

        // Untouched fields preserve fallback (not hard-coded defaults).
        #expect(restored.nsfwEnabled == fallback.nsfwEnabled)
        #expect(restored.reetenMinimumMinutes == fallback.reetenMinimumMinutes)
        #expect(restored.smartThumbnailsEnabled == fallback.smartThumbnailsEnabled)
        #expect(restored.remoteSkipMode == fallback.remoteSkipMode)
        #expect(restored.showResumeOverlay == fallback.showResumeOverlay)
    }

    @Test("Legacy showTopComment Int migrates into TopCommentMode")
    func legacyTopCommentMigration() {
        let record = makeRecord()
        record["showTopComment"] = 0 as CKRecordValue

        let restored = CloudKitService.makeSettings(from: record, fallback: UserSettingsSnapshot())
        #expect(restored.topCommentMode == .off)

        let record2 = makeRecord()
        record2["showTopComment"] = 1 as CKRecordValue
        let restored2 = CloudKitService.makeSettings(from: record2, fallback: UserSettingsSnapshot())
        #expect(restored2.topCommentMode == .all)
    }

    @Test("New topCommentMode string takes precedence over legacy showTopComment")
    func newTopCommentModeWinsOverLegacy() {
        let record = makeRecord()
        record["showTopComment"] = 0 as CKRecordValue
        record["topCommentMode"] = TopCommentMode.single.rawValue as CKRecordValue

        let restored = CloudKitService.makeSettings(from: record, fallback: UserSettingsSnapshot())
        #expect(restored.topCommentMode == .single)
    }
}
