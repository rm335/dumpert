import SwiftUI

struct ContentView: View {
    @Environment(VideoRepository.self) private var repository
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(ImmersiveBackgroundState.self) private var backgroundState
    @Binding var deepLinkVideoId: String?
    @State private var deepLinkVideo: Video?
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            ImmersiveBackgroundView(imageURL: backgroundState.activeURL)

            VStack(spacing: 0) {
                if !networkMonitor.isConnected {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                        Text("Geen internetverbinding", comment: "Offline banner message")
                    }
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .background(.red.opacity(0.6))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                TabView(selection: $selectedTab) {
                    ToppersSectionView()
                        .tabItem {
                            Label("Toppers", systemImage: "flame.fill")
                        }
                        .tag(0)

                    CategorySectionView(category: .nieuwBinnen)
                        .tabItem {
                            Label("Nieuw", systemImage: "sparkles")
                        }
                        .tag(1)

                    CategoriesSectionView()
                        .tabItem {
                            Label(String(localized: "Categorieën", comment: "Categories tab title"), systemImage: "square.grid.2x2.fill")
                        }
                        .tag(2)

                    SearchView()
                        .tabItem {
                            Label("Zoeken", systemImage: "magnifyingglass")
                        }
                        .tag(3)

                    SettingsView()
                        .tabItem {
                            Label("Instellingen", systemImage: "gearshape.fill")
                        }
                        .tag(4)
                }
            }
        }
        .animation(.smooth, value: networkMonitor.isConnected)
        .onChange(of: repository.classics) {
            Task { @MainActor in
                backgroundState.shuffleFallback(from: repository.classics)
            }
        }
        .onChange(of: selectedTab) {
            Task { @MainActor in
                backgroundState.shuffleFallback(from: repository.classics)
            }
        }
        .fullScreenCover(item: $deepLinkVideo) { video in
            VideoPlayerView(viewModel: VideoPlayerViewModel(
                video: video,
                repository: repository
            ))
        }
        .onChange(of: deepLinkVideoId) { _, videoId in
            guard let videoId else { return }
            Task { @MainActor in
                deepLinkVideoId = nil
                // Try local data first
                let allItems = repository.hotshiz
                    + repository.topWeek + repository.topMonth
                    + (repository.categoryVideos[.nieuwBinnen] ?? [])
                if let item = allItems.first(where: { $0.id == videoId }),
                   case let .video(video) = item {
                    deepLinkVideo = video
                    return
                }
                // Not found locally — fetch from API
                do {
                    if let item = try await repository.apiClient.fetchItem(id: videoId),
                       case let .video(video) = item {
                        deepLinkVideo = video
                    }
                } catch {
                    // Silently fail — video not available
                }
            }
        }
    }
}
