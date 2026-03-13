import SwiftUI

struct DumpertTVSectionView: View {
    @Environment(VideoRepository.self) private var repository
    @State private var selectedVideo: Video?
    @State private var selectedPhoto: Photo?
    @State private var toastMessage: String?
    @FocusState private var focusedItem: String?

    private var items: [MediaItem] {
        repository.filteredItems(repository.dumpertTV)
    }

    var body: some View {
        ZStack {
            if repository.isLoading && items.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        sectionHeader
                        SkeletonGridView(columnCount: repository.settings.tileSize.gridColumnCount)
                    }
                    .padding(.vertical, 30)
                }
                .transition(.opacity)
            } else if items.isEmpty && !repository.isLoading {
                VStack(spacing: 30) {
                    sectionHeader

                    if let error = repository.error {
                        EmptyStateView(
                            title: "Er ging iets mis",
                            systemImage: "exclamationmark.triangle",
                            description: "\(error)"
                        ) {
                            Task { await repository.refreshAll() }
                        }
                    } else {
                        EmptyStateView(
                            title: "Geen video's",
                            systemImage: "tv.slash",
                            description: "Geen Dumpert TV afleveringen gevonden"
                        ) {
                            Task { await repository.refreshAll() }
                        }
                    }
                }
                .transition(.opacity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        sectionHeader

                        LazyVGrid(
                            columns: repository.settings.tileSize.gridColumns,
                            spacing: 35
                        ) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                Button {
                                    item.present(selectedVideo: $selectedVideo, selectedPhoto: $selectedPhoto)
                                } label: {
                                    VideoCardView(
                                        item: item,
                                        isWatched: repository.isWatched(item.id),
                                        progress: repository.progressFor(item.id),
                                        isFocused: focusedItem == item.id,
                                        thumbnailPreviewEnabled: repository.settings.thumbnailPreviewEnabled,
                                        smartThumbnailsEnabled: repository.settings.smartThumbnailsEnabled
                                    )
                                }
                                .buttonStyle(.card)
                                .focused($focusedItem, equals: item.id)
                                .videoContextMenu(item: item, repository: repository, toastMessage: $toastMessage)
                                .onAppear {
                                    let prefetchRange = (index + 1)..<min(index + 6, items.count)
                                    if !prefetchRange.isEmpty {
                                        let upcoming = Array(items[prefetchRange])
                                        Task { await ImagePrefetchService.shared.prefetch(upcoming) }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 50)
                    }
                    .padding(.vertical, 30)
                }
                .refreshable {
                    await repository.refreshAll()
                }
            }
        }
        .animation(.easeOut(duration: 0.3), value: repository.isLoading)
        .fullScreenCover(item: $selectedVideo) { video in
            let videoPlaylist = items.compactMap { item -> Video? in
                if case .video(let v) = item { return v }
                return nil
            }
            VideoPlayerView(viewModel: VideoPlayerViewModel(
                video: video,
                playlist: videoPlaylist,
                repository: repository
            ))
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            FullScreenImageView(photo: photo, repository: repository)
        }
        .toast(message: $toastMessage)
    }

    private var sectionHeader: some View {
        Text("Dumpert TV")
            .font(.title2)
            .fontWeight(.bold)
            .padding(.horizontal, 50)
    }
}
