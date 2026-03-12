import SwiftUI

struct ContentView: View {
    @Environment(VideoRepository.self) private var repository
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Binding var deepLinkVideoId: String?
    @State private var deepLinkVideo: Video?

    var body: some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                    Text("Geen internetverbinding")
                }
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.red.opacity(0.85))
            }

            TabView {
            ToppersSectionView()
                .tabItem {
                    Label("Toppers", systemImage: "flame.fill")
                }

            CategorySectionView(category: .nieuwBinnen)
                .tabItem {
                    Label("Nieuw", systemImage: "sparkles")
                }

            CategorySectionView(category: .reeten)
                .tabItem {
                    Label("Reeten", systemImage: "trophy")
                }

            CategorySectionView(category: .vrijmico)
                .tabItem {
                    Label("VrijMiCo", systemImage: "party.popper.fill")
                }

            CategorySectionView(category: .dashcam)
                .tabItem {
                    Label("Dashcam", systemImage: "car.fill")
                }

            ClassicsSectionView()
                .tabItem {
                    Label("Classics", systemImage: "clock.arrow.circlepath")
                }

            SearchView()
                .tabItem {
                    Label("Zoeken", systemImage: "magnifyingglass")
                }

            SettingsView()
                .tabItem {
                    Label("Instellingen", systemImage: "gearshape.fill")
                }
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
            deepLinkVideoId = nil
            let allItems = repository.hotshiz
                + repository.topWeek + repository.topMonth
            if let item = allItems.first(where: { $0.id == videoId }),
               case .video(let video) = item {
                deepLinkVideo = video
            }
        }
    }
}
