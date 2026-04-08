import SwiftUI

struct WatchedSectionView: View {
    @Environment(VideoRepository.self) private var repository
    @Environment(ImmersiveBackgroundState.self) private var backgroundState
    @State private var selectedVideo: Video?
    @State private var selectedPhoto: Photo?
    @State private var toastMessage: String?
    @FocusState private var focusedItem: String?

    var body: some View {
        ZStack {
            if repository.isLoadingWatched && repository.watchedVideos.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        watchedHeader
                        SkeletonGridView(columnCount: repository.settings.tileSize.gridColumnCount)
                    }
                    .padding(.vertical, 30)
                }
                .transition(.opacity)
            } else if repository.watchedVideos.isEmpty && !repository.isLoadingWatched {
                VStack(spacing: 30) {
                    watchedHeader

                    EmptyStateView(
                        title: "Nog niets bekeken",
                        systemImage: "eye.slash",
                        description: "Video's die je bekijkt verschijnen hier"
                    ) {
                        Task { await repository.fetchWatchedVideos() }
                    }
                }
                .transition(.opacity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            watchedHeader
                                .id("top")

                            LazyVGrid(
                                columns: repository.settings.tileSize.gridColumns,
                                spacing: 35
                            ) {
                                ForEach(Array(repository.watchedVideos.enumerated()), id: \.element.id) { index, item in
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
                                        let prefetchRange = (index + 1)..<min(index + 6, repository.watchedVideos.count)
                                        if !prefetchRange.isEmpty {
                                            let upcoming = Array(repository.watchedVideos[prefetchRange])
                                            Task { await ImagePrefetchService.shared.prefetch(upcoming) }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 50)

                            // Scroll to top button
                            if repository.watchedVideos.count > repository.settings.tileSize.gridColumnCount * 3 {
                                Button {
                                    withAnimation(.spring(duration: 0.5)) {
                                        proxy.scrollTo("top", anchor: .top)
                                    }
                                } label: {
                                    Label(
                                        String(localized: "Naar boven", comment: "Scroll to top button"),
                                        systemImage: "arrow.up"
                                    )
                                    .font(.callout)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 20)
                                .accessibilityLabel(Text("Scroll naar boven", comment: "Accessibility: scroll to top"))
                            }
                        }
                        .padding(.vertical, 30)
                    }
                    .refreshable {
                        await repository.fetchWatchedVideos()
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.3), value: repository.isLoadingWatched)
        .task {
            if repository.watchedVideos.isEmpty {
                await repository.fetchWatchedVideos()
            }
        }
        .fullScreenCover(item: $selectedVideo) { video in
            let videoPlaylist = repository.watchedVideos.compactMap { item -> Video? in
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
        .onChange(of: focusedItem) { _, newId in
            Task { @MainActor in
                if let id = newId, let item = repository.watchedVideos.first(where: { $0.id == id }) {
                    backgroundState.update(for: item)
                }
            }
        }
    }

    private var watchedHeader: some View {
        SectionTitleView(String(localized: "Gekeken", comment: "Watched tab: section title"))
            .font(.title2)
            .padding(.horizontal, 50)
    }
}
