import SwiftUI

struct ClassicsSectionView: View {
    @Environment(VideoRepository.self) private var repository
    @Environment(ImmersiveBackgroundState.self) private var backgroundState
    @State private var selectedVideo: Video?
    @State private var selectedPhoto: Photo?
    @State private var toastMessage: String?
    @FocusState private var focusedItem: String?

    private var items: [MediaItem] {
        repository.filteredItems(repository.classics)
    }

    var body: some View {
        ZStack {
            if repository.isLoading && items.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        classicsHeader
                        SkeletonGridView(columnCount: repository.settings.tileSize.gridColumnCount)
                    }
                    .padding(.vertical, 30)
                }
                .transition(.opacity)
            } else if items.isEmpty && !repository.isLoading {
                VStack(spacing: 30) {
                    classicsHeader

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
                            description: "Geen classics gevonden"
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
                            classicsHeader
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
                                            smartThumbnailsEnabled: repository.settings.smartThumbnailsEnabled
                                        )
                                        .overlay(alignment: .topLeading) {
                                            // Vintage year badge for classics
                                            if let date = item.date {
                                                Text(date.classicsYearString)
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .monospacedDigit()
                                                    .foregroundStyle(.white.opacity(0.9))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .modifier(GlassPillModifier())
                                                    .padding(6)
                                            }
                                        }
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
                                        if index >= items.count - 3 {
                                            Task { await repository.loadMoreClassics() }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 50)

                            if repository.isClassicsLoadingMore {
                                ProgressView("Meer laden...")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .accessibilityLabel("Meer classics laden")
                            } else if repository.classicsHasMore && !items.isEmpty {
                                Button("Laad meer") {
                                    Task { await repository.loadMoreClassics() }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .accessibilityHint("Laad meer classics")
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
        .onChange(of: focusedItem) { _, newId in
            Task { @MainActor in
                if let id = newId, let item = items.first(where: { $0.id == id }) {
                    backgroundState.update(for: item)
                }
            }
        }
    }

    private var classicsHeader: some View {
        Text("Classics")
            .font(.title2)
            .fontWeight(.bold)
            .padding(.horizontal, 50)
    }
}

// MARK: - Date Extension for Classics

extension Date {
    private static let classicsYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f
    }()

    var classicsYearString: String {
        Date.classicsYearFormatter.string(from: self)
    }
}
