<p align="center">
  <img src="assets/top-shelf.png" alt=”DumpertTV” width=”100%”>
</p>

# DumpertTV

<p align="center">
  <a href="https://testflight.apple.com/join/TXTUMzEq"><img src="https://img.shields.io/badge/TestFlight-Join%20Beta-0D96F6?style=flat&logo=apple&logoColor=white" alt="TestFlight"></a>
  <img src="https://img.shields.io/badge/platform-tvOS%2018.0%2B-000000?style=flat&logo=apple&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?style=flat&logo=swift&logoColor=white" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/Xcode-26.3-147EFB?style=flat&logo=xcode&logoColor=white" alt="Xcode 26.3">
  <a href="https://github.com/rm335/dumpert/blob/main/LICENSE"><img src="https://img.shields.io/github/license/rm335/dumpert?style=flat" alt="License"></a>
  <a href="https://github.com/rm335/dumpert/stargazers"><img src="https://img.shields.io/github/stars/rm335/dumpert?style=flat" alt="Stars"></a>
  <a href="https://github.com/rm335/dumpert/commits/main"><img src="https://img.shields.io/github/last-commit/rm335/dumpert?style=flat" alt="Last Commit"></a>
  <img src="https://img.shields.io/github/repo-size/rm335/dumpert?style=flat" alt="Repo Size">
  <img src="https://img.shields.io/badge/build%20system-XcodeGen-blue?style=flat" alt="XcodeGen">
</p>

An unofficial [Dumpert](https://www.dumpert.nl) client for Apple TV, built with Swift 6.0 and SwiftUI.

> **Disclaimer**
>
> **This project is not affiliated with, endorsed by, or associated with Dumpert or DPG Media B.V.**
> Dumpert is a registered trademark of DPG Media B.V. All trademarks belong to their respective owners.
> This app consumes the public Dumpert API. Use at your own risk.

---

## Installation via TestFlight

<p align="center">
  <img src="assets/testflight-icon.png" alt="TestFlight" width="80">
</p>

<p align="center">
  <a href="https://testflight.apple.com/join/TXTUMzEq">
    <img src="https://img.shields.io/badge/TestFlight-Join%20Beta-0D96F6?style=for-the-badge&logo=apple&logoColor=white" alt="Join TestFlight Beta">
  </a>
</p>

The easiest way to install DumpertTV on your Apple TV:

1. Install **TestFlight** from the App Store on your Apple TV and iPhone
2. Open the [TestFlight invite link](https://testflight.apple.com/join/TXTUMzEq) on your iPhone and accept the invite
3. Open **TestFlight** on your Apple TV and install the app

---

## Features

### Content Browsing
- **8 tabs**: Toppers, Nieuw, Reeten, VrijMiCo, Dashcam, Classics, Zoeken, Instellingen
- **Hero banner** with horizontally scrolling carousel and face-centered thumbnails
- **Infinite scroll pagination** on category and classics views
- **Skeleton loading** with shimmer animation while content loads
- **Top Shelf extension** showing trending content directly on the Apple TV home screen

### Video Player
- Full-screen video playback via `AVPlayerViewController`
- **Autoplay** with configurable up-next overlay and countdown timer
- **Next video preloading** for seamless playback
- **Playback speed** control (0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x)
- **Watch progress tracking** with throttled saves (5-second intervals)
- Watched badge indicator on already-viewed content

### Photo Viewer
- Full-screen photo display with zoom controls
- Overlay with metadata (title, date, kudos)

### Search
- Full-text search with the Dumpert API
- **Filters**: media type, time period, minimum kudos, duration
- **Popular tags** and recent search suggestions
- **In-memory result caching** (5-minute TTL)
- Search history persistence

### Sync & Offline
- **CloudKit sync** for watch progress, settings, curation entries, and search history across Apple TV devices
- **Delta sync** with change tokens for efficient updates
- **Offline support** with network monitoring banner
- **ETag-based HTTP caching** (304 Not Modified) for API responses
- **Retry logic** with exponential backoff (3 attempts, 2^n second delays) on 5xx and network errors

### Accessibility
- **VoiceOver** labels throughout all views
- Adjustable action on hero carousel for screen reader users

### Deep Linking
- URL scheme: `dumpert://video/{id}`
- Used by the Top Shelf extension to open videos directly

---

## Screenshots

| Toppers | Search |
|:---:|:---:|
| ![Toppers](assets/screenshot-toppers.png) | ![Search](assets/screenshot-search.png) |
| **Reeten** | **VrijMiCo** |
| ![Reeten](assets/screenshot-reeten.png) | ![VrijMiCo](assets/screenshot-vrijmico.png) |
| **Classics** | **Settings** |
| ![Classics](assets/screenshot-classics.png) | ![Settings](assets/screenshot-settings.png) |

### Demo

<p align="center">
  <img src="assets/demo.gif" alt="DumpertTV demo" width="100%">
</p>

---

## Requirements

| Requirement | Version |
|---|---|
| Xcode | 26.3+ |
| tvOS deployment target | 18.0+ |
| Swift | 6.0 (strict concurrency) |
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | Latest |
| Apple Developer account | Required for CloudKit and code signing |

---

## Getting Started

### 1. Install XcodeGen

```bash
brew install xcodegen
```

### 2. Clone the repository

```bash
git clone https://github.com/rm335/dumpert.git
cd DumpertTV
```

### 3. Generate the Xcode project

```bash
xcodegen generate
```

> The `.xcodeproj` is generated from `project.yml` — never edit it directly.

### 4. Open in Xcode

```bash
open Dumpert.xcodeproj
```

### 5. Configure signing

- Select your development team for both the **Dumpert** and **DumpertTopShelf** targets.
- Change the bundle identifiers if needed (default: `nl.dumpert.tvos`).

### 6. Configure CloudKit (optional)

CloudKit sync is optional. If you want cross-device sync:

1. Update `Dumpert/Dumpert.entitlements` with your own iCloud container identifier.
2. Update `DumpertTopShelf/DumpertTopShelf.entitlements` with your own app group.
3. Create the corresponding CloudKit container in the [Apple Developer portal](https://developer.apple.com/account/).

> Without CloudKit, the app works fully with local-only persistence.

### 7. Build and run

Build and run on an Apple TV or the tvOS Simulator.

---

## Architecture

### Overview

```
┌─────────────────────────────────────────────────────┐
│                    DumpertApp                       │
│               (SwiftUI @main entry)                 │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │              ContentView                      │   │
│  │        TabView with 8 tabs                    │   │
│  │                                               │   │
│  │  Toppers │ Nieuw │ Reeten │ VrijMiCo │ ...    │   │
│  └────────────────────┬─────────────────────────┘   │
│                       │                             │
│               @Environment                          │
│                       │                             │
│  ┌────────────────────▼─────────────────────────┐   │
│  │          VideoRepository                      │   │
│  │    @Observable @MainActor                     │   │
│  │    Single source of truth                     │   │
│  └──────┬──────────┬──────────┬────────────────┘   │
│         │          │          │                     │
│  ┌──────▼───┐ ┌────▼────┐ ┌──▼──────────┐          │
│  │ API      │ │ Cache   │ │ CloudKit    │          │
│  │ Client   │ │ Service │ │ Service     │          │
│  │ (actor)  │ │ (actor) │ │ (actor)     │          │
│  └──────────┘ └─────────┘ └─────────────┘          │
└─────────────────────────────────────────────────────┘
```

### Key Patterns

| Pattern | Usage |
|---|---|
| `@Observable` + `@MainActor` | `VideoRepository`, `NetworkMonitor`, `UserSettings` — reactive state on main thread |
| Actor isolation | `DumpertAPIClient`, `CacheService`, `CloudKitService`, `ImageCacheService` — thread-safe services |
| Environment injection | `VideoRepository` and `NetworkMonitor` injected via `.environment()` |
| Protocol-based DI | `APIClientProtocol`, `CacheServiceProtocol` for testability |
| Swift 6 strict concurrency | `SWIFT_STRICT_CONCURRENCY: complete` across all targets |

### Data Flow

```
Dumpert API → DumpertItem (API model) → MediaItem (domain enum) → Video / Photo
                                              │
                                         VideoRepository
                                              │
                                    SwiftUI views via @Environment
```

---

## Project Structure

```
dumpert/
├── project.yml                     # XcodeGen project configuration
├── Dumpert/                        # Main app target
│   ├── App/
│   │   ├── DumpertApp.swift        # @main entry, environment setup, deep linking
│   │   └── ContentView.swift       # Root TabView with 8 tabs + offline banner
│   ├── Models/
│   │   ├── API/                    # Codable API response models
│   │   │   ├── DumpertAPIResponse.swift
│   │   │   ├── DumpertItem.swift
│   │   │   ├── DumpertMedia.swift
│   │   │   └── DumpertStats.swift
│   │   └── Domain/                 # App domain models
│   │       ├── Video.swift
│   │       ├── Photo.swift
│   │       ├── MediaItem.swift     # enum: .video(Video) | .photo(Photo)
│   │       ├── VideoCategory.swift
│   │       ├── UserSettings.swift
│   │       ├── WatchProgress.swift
│   │       ├── SearchFilter.swift
│   │       ├── CurationEntry.swift
│   │       └── SearchHistoryEntry.swift
│   ├── Networking/
│   │   ├── DumpertAPIClient.swift  # Actor with ETag + retry
│   │   ├── APIClientProtocol.swift # Protocol for mocking
│   │   ├── APIEndpoint.swift       # URL routing
│   │   └── APIError.swift          # Error types
│   ├── Services/
│   │   ├── VideoRepository.swift   # @Observable source of truth
│   │   ├── CacheService.swift      # Disk cache (50MB LRU)
│   │   ├── CacheServiceProtocol.swift
│   │   ├── CloudKitService.swift   # iCloud delta sync
│   │   ├── CategoryService.swift   # Category filtering
│   │   ├── ImageCacheService.swift # Two-layer image cache (80MB mem + 200MB disk)
│   │   ├── ImagePrefetchService.swift
│   │   ├── NetworkMonitor.swift    # NWPathMonitor connectivity
│   │   ├── FaceDetectionService.swift
│   │   └── RefreshScheduler.swift
│   ├── ViewModels/
│   │   ├── VideoPlayerViewModel.swift
│   │   └── SearchViewModel.swift
│   ├── Views/
│   │   ├── Components/             # Reusable UI components
│   │   │   ├── VideoCardView.swift
│   │   │   ├── VideoPreviewView.swift
│   │   │   ├── FaceCenteredThumbnailView.swift
│   │   │   ├── KudosBadgeView.swift
│   │   │   ├── WatchedBadgeView.swift
│   │   │   ├── EmptyStateView.swift
│   │   │   ├── SkeletonView.swift
│   │   │   └── ToastView.swift
│   │   ├── Player/
│   │   │   ├── VideoPlayerView.swift
│   │   │   ├── UpNextOverlayView.swift
│   │   │   ├── FullScreenImageView.swift
│   │   │   ├── FullScreenImageOverlay.swift
│   │   │   └── ZoomControlsView.swift
│   │   ├── Search/
│   │   │   ├── SearchView.swift
│   │   │   ├── SearchSuggestionsView.swift
│   │   │   └── SearchFilterBar.swift
│   │   ├── Sections/
│   │   │   ├── ToppersSectionView.swift
│   │   │   ├── CategorySectionView.swift
│   │   │   └── ClassicsSectionView.swift
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       ├── SettingsComponents.swift
│   │       ├── SettingsPickerDestination.swift
│   │       └── UpNextSettingsView.swift
│   ├── Extensions/
│   │   ├── String+HTML.swift       # HTML tag/entity stripping
│   │   ├── Color+Dumpert.swift     # Brand colors (#65B32E)
│   │   └── Date+Formatting.swift
│   ├── Utilities/
│   │   ├── AppLogger.swift         # os.Logger categories
│   │   ├── DurationFormatter.swift # MM:SS formatting
│   │   └── MediaItem+Present.swift
│   ├── Assets.xcassets/
│   ├── Dumpert.entitlements
│   └── Info.plist
├── DumpertTopShelf/                # Top Shelf extension
│   ├── ContentProvider.swift       # TVTopShelfContentProvider
│   ├── DumpertTopShelf.entitlements
│   └── Info.plist
├── Shared/                         # Shared between app + extension
│   ├── TopShelfItem.swift
│   ├── TopShelfDataStore.swift     # App Group UserDefaults
│   └── TopShelfFetcher.swift
├── DumpertTests/                   # Unit tests (41 tests, 6 suites)
│   ├── ModelTests.swift
│   ├── APIDecodingTests.swift
│   ├── DurationFormatterTests.swift
│   ├── SearchFilterTests.swift
│   ├── CacheServiceTests.swift
│   ├── ErrorCaseTests.swift
│   └── Fixtures/                   # JSON test fixtures
│       ├── hotshiz.json
│       ├── latest.json
│       ├── search_reeten.json
│       └── foto_item.json
└── LICENSE
```

---

## API

The app uses the public Dumpert mobile API.

| Endpoint | Description |
|---|---|
| `GET /hotshiz` | Currently trending items |
| `GET /top5/week/{date}` | Top items of the week |
| `GET /top5/maand/{date}` | Top items of the month |
| `GET /latest/{page}` | Latest items (paginated) |
| `GET /search/{query}/{page}` | Search results (paginated) |
| `GET /info/{id}` | Single item details |
| `GET /classics/{page}` | Classic items (paginated) |

Base URL: `https://api.dumpert.nl/mobile_api/json`

---

## Targets

The project has 3 targets, defined in `project.yml`:

| Target | Type | Bundle ID | Description |
|---|---|---|---|
| **Dumpert** | tvOS Application | `nl.dumpert.tvos` | Main app |
| **DumpertTopShelf** | App Extension | `nl.dumpert.tvos.topshelf` | Top Shelf content provider |
| **DumpertTests** | Unit Test Bundle | `nl.dumpert.tvos.tests` | 41 tests across 6 suites |

---

## Tests

41 tests across 6 suites, using Swift Testing framework:

| Suite | Tests | What it covers |
|---|---|---|
| **ModelTests** | 8 | WatchProgress, CurationEntry, UserSettings, VideoCategory, HTML stripping |
| **APIDecodingTests** | 7 | API response decoding, Video conversion, HLS preference, tags parsing |
| **DurationFormatterTests** | 3 | Time formatting (MM:SS, edge cases) |
| **SearchFilterTests** | 5 | Filter activation for media type, period, kudos, duration |
| **CacheServiceTests** | 5 | Persistence of watch progress, settings, curation, search history, disk limits |
| **ErrorCaseTests** | 5 | API error descriptions, network/decoding/HTTP error handling, 5xx retry |

### Running Tests

```bash
# Generate project and run tests
xcodegen generate && xcodebuild test \
  -scheme Dumpert \
  -destination 'platform=tvOS Simulator,name=Apple TV' \
  -resultBundlePath TestResults
```

---

## Tech Stack

| Technology | Usage |
|---|---|
| **Swift 6.0** | Strict concurrency (`complete` mode) |
| **SwiftUI** | All UI, tvOS-native |
| **AVKit** | Video playback via `AVPlayerViewController` |
| **CloudKit** | Cross-device sync (private database, custom zone) |
| **Network.framework** | `NWPathMonitor` for connectivity |
| **Vision.framework** | Face detection for thumbnail centering |
| **os.log** | Structured logging (`.cloudKit`, `.cache`, `.network`) |
| **XcodeGen** | Project generation from `project.yml` |
| **Swift Testing** | Unit test framework |

---

## Configuration

### Settings (in-app)

The Settings tab allows users to configure:

- Tile size (small, medium, large)
- Autoplay on/off
- Hide watched content
- Up-next overlay behavior
- Playback speed default

Settings are persisted locally and synced via CloudKit.

### Entitlements

| Entitlement | Target | Purpose |
|---|---|---|
| iCloud containers | Dumpert | CloudKit sync |
| CloudKit | Dumpert | iCloud database access |
| KV store | Dumpert | Key-value sync |
| App Groups | Both | Share data between app and Top Shelf extension |

---

## Contributing

Contributions are welcome! Here's how:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Install XcodeGen: `brew install xcodegen`
4. Generate the project: `xcodegen generate`
5. Make your changes
6. Run the tests to make sure everything passes
7. Commit your changes with a clear message
8. Push to your fork and open a Pull Request

### Guidelines

- Run `xcodegen generate` after changing `project.yml`
- Never commit `Dumpert.xcodeproj` changes directly — edit `project.yml` instead
- Maintain Swift 6 strict concurrency compliance
- Add tests for new functionality
- Use actors for new services, `@Observable @MainActor` for new state holders
- Follow existing patterns for file organization

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Acknowledgements

- [Dumpert](https://www.dumpert.nl) for the public API
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for declarative Xcode project management
