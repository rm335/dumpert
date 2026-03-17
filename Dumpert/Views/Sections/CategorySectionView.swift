import SwiftUI

struct CategorySectionView: View {
    let category: VideoCategory
    @Environment(VideoRepository.self) private var repository
    @State private var selectedVideo: Video?
    @State private var selectedPhoto: Photo?
    @State private var toastMessage: String?
    @FocusState private var focusedItem: String?

    private var items: [MediaItem] {
        repository.filteredItems(repository.categoryVideos[category] ?? [])
    }

    private var sortOrder: SortOrder {
        repository.categorySortOrder[category] ?? .dateNewest
    }

    private var hasMore: Bool {
        repository.categoryHasMore[category] ?? false
    }

    private var isLoadingMore: Bool {
        repository.isCategoryLoadingMore[category] ?? false
    }

var body: some View {
        ZStack {
            if repository.isLoading && items.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        Text(category.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 50)
                        SkeletonGridView(columnCount: repository.settings.tileSize.gridColumnCount)
                    }
                    .padding(.vertical, 30)
                }
                .transition(.opacity)
            } else if items.isEmpty && !repository.isLoading {
                VStack(spacing: 30) {
                    Text(category.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 50)

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
                            systemImage: "video.slash",
                            description: "Geen video's gevonden voor \(category.displayName)"
                        ) {
                            Task { await repository.refreshAll() }
                        }
                    }
                }
                .transition(.opacity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            HStack {
                                Text(category.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                if !category.usesLatestEndpoint {
                                    sortPicker
                                }
                            }
                            .padding(.horizontal, 50)
                            .id("top")

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
                                            smartThumbnailsEnabled: repository.settings.smartThumbnailsEnabled && category != .reeten && category != .vrijmico
                                        )
                                    }
                                    .buttonStyle(.card)
                                    .focused($focusedItem, equals: item.id)
                                    .videoContextMenu(item: item, repository: repository, toastMessage: $toastMessage, currentCategory: category)
                                    .onAppear {
                                        let prefetchRange = (index + 1)..<min(index + 6, items.count)
                                        if !prefetchRange.isEmpty {
                                            let upcoming = Array(items[prefetchRange])
                                            Task { await ImagePrefetchService.shared.prefetch(upcoming) }
                                        }
                                        if index >= items.count - 3 {
                                            Task { await repository.loadMoreForCategory(category) }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 50)

                            // Load more indicator
                            if isLoadingMore {
                                ProgressView("Meer laden...")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .accessibilityLabel("Meer video's laden")
                            } else if hasMore && !items.isEmpty {
                                Button("Laad meer") {
                                    Task { await repository.loadMoreForCategory(category) }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .accessibilityHint("Laad meer video's in \(category.displayName)")
                            }

                            // Scroll to top button
                            if items.count > repository.settings.tileSize.gridColumnCount * 3 {
                                Button {
                                    withAnimation(.spring(duration: 0.5)) {
                                        proxy.scrollTo("top", anchor: .top)
                                    }
                                } label: {
                                    Label("Naar boven", systemImage: "arrow.up")
                                        .font(.callout)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 20)
                                .accessibilityLabel("Scroll naar boven")
                            }
                        }
                        .padding(.vertical, 30)
                    }
                    .refreshable {
                        await repository.refreshAll()
                    }
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

    private var sortPicker: some View {
        Button {
            let cases = SortOrder.allCases
            let idx = cases.firstIndex(of: sortOrder) ?? cases.startIndex
            let next = cases[(cases.distance(from: cases.startIndex, to: idx) + 1) % cases.count]
            repository.setSortOrder(next, for: category)
        } label: {
            Label(sortOrder.displayName, systemImage: sortOrder.systemImage)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.dumpiGreen, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sortering: \(sortOrder.displayName)")
        .accessibilityHint("Wijzig de sorteervolgorde")
    }
}
