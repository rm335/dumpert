import SwiftUI

@main
struct DumpertApp: App {
    @State private var videoRepository = VideoRepository()
    @State private var networkMonitor = NetworkMonitor()
    @State private var deepLinkVideoId: String?

    var body: some Scene {
        WindowGroup {
            ContentView(deepLinkVideoId: $deepLinkVideoId)
                .environment(videoRepository)
                .environment(networkMonitor)
                .tint(.dumpiGreen)
                .onAppear {
                    videoRepository.networkMonitor = networkMonitor
                }
                .onOpenURL { url in
                    guard url.scheme == "dumpert",
                          url.host == "video" else { return }
                    deepLinkVideoId = url.lastPathComponent
                }
        }
    }
}
