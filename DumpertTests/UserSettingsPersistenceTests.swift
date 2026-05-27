import Testing
import Foundation
@testable import Dumpert

/// Regression tests for the user-settings persistence pipeline.
///
/// Bug: `UserSettings` is an `@Observable` class held by `VideoRepository` as
/// `var settings: UserSettings { didSet { save } }`. Because Swift's `didSet`
/// on a class-typed property only fires when the reference itself is
/// reassigned, every UI-driven change (toggling NSFW, changing tile size,
/// resetting defaults, etc.) silently bypassed persistence — settings were
/// reverted to defaults on the next launch.
///
/// The fix wires a per-property `didSet` on every user-facing field through
/// to a single `onChange` closure that the repository hooks for saving.
/// `apply(_:)` continues to mass-restore a snapshot without triggering save,
/// to keep CloudKit/cache loads from echoing back into the save handler.
@Suite("User Settings Persistence Tests")
@MainActor
struct UserSettingsPersistenceTests {

    @Test("Mutating any user-facing property invokes onChange")
    func mutationInvokesOnChangeForEveryProperty() {
        let settings = UserSettings()
        var callCount = 0
        settings.onChange = { callCount += 1 }

        settings.minimumKudos = 25
        settings.autoplayEnabled.toggle()
        settings.hideWatched.toggle()
        settings.reetenMinimumMinutes = 15
        settings.showNegativeKudos.toggle()
        settings.nsfwEnabled.toggle()
        settings.thumbnailPreviewEnabled.toggle()
        settings.smartThumbnailsEnabled.toggle()
        settings.tileSize = .small
        settings.upNextOverlayEnabled.toggle()
        settings.upNextCountdownSeconds = 10
        settings.upNextMinimumVideoSeconds = 120
        settings.topCommentMode = .single
        settings.readingSpeed = .fast
        settings.remoteSkipMode = .off
        settings.showResumeOverlay.toggle()

        // Sixteen user-facing properties were mutated; lastModified is
        // intentionally excluded from the change notification because it is
        // updated by the save pipeline itself.
        #expect(callCount == 16)
    }

    @Test("apply(_:) restores a snapshot without invoking onChange")
    func applyDoesNotInvokeOnChange() {
        let settings = UserSettings()
        var callCount = 0
        settings.onChange = { callCount += 1 }

        let snapshot = UserSettingsSnapshot(
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

        settings.apply(snapshot)
        #expect(callCount == 0)
        #expect(settings.minimumKudos == 100)
        #expect(settings.tileSize == .large)
        #expect(settings.lastModified == Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test("onChange resumes firing after apply(_:) completes")
    func onChangeResumesAfterApply() {
        let settings = UserSettings()
        var callCount = 0
        settings.onChange = { callCount += 1 }

        settings.apply(UserSettingsSnapshot())
        #expect(callCount == 0)

        settings.minimumKudos = 42
        #expect(callCount == 1)
    }

    @Test("snapshot reflects the latest mutations made through the binding path")
    func snapshotReflectsLatestMutations() {
        let settings = UserSettings()
        settings.minimumKudos = 250
        settings.tileSize = .small
        settings.remoteSkipMode = .off

        let snapshot = settings.snapshot
        #expect(snapshot.minimumKudos == 250)
        #expect(snapshot.tileSize == .small)
        #expect(snapshot.remoteSkipMode == .off)
    }
}
