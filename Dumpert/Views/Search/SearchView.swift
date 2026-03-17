import SwiftUI

struct SearchView: View {
    @Environment(VideoRepository.self) var repository
    @Environment(ImmersiveBackgroundState.self) private var backgroundState
    @State private var viewModel: SearchViewModel?
    @State private var selectedVideo: Video?
    @State private var selectedPhoto: Photo?
    @State private var toastMessage: String?
    @FocusState private var focusedItem: String?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    searchContent(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Zoeken")
            .searchable(
                text: Binding(
                    get: { viewModel?.searchQuery ?? "" },
                    set: { viewModel?.searchQuery = $0 }
                ),
                prompt: "Zoek op Dumpert"
            )
            .searchSuggestions {
                if let viewModel, !viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let query = viewModel.searchQuery.lowercased()
                    // Matching popular tags
                    let matchingTags = repository.popularTags.filter { $0.lowercased().contains(query) }.prefix(5)
                    ForEach(Array(matchingTags), id: \.self) { tag in
                        Label(tag.capitalized, systemImage: "flame.fill")
                            .searchCompletion(tag)
                    }
                    // Matching recent searches
                    let matchingRecent = repository.searchHistory.filter { $0.query.lowercased().contains(query) }.prefix(3)
                    ForEach(Array(matchingRecent)) { entry in
                        Label(entry.query, systemImage: "clock.arrow.circlepath")
                            .searchCompletion(entry.query)
                    }
                    // Matching categories
                    let matchingCategories = Self.categories.filter { $0.query.lowercased().contains(query) }.prefix(3)
                    ForEach(Array(matchingCategories), id: \.query) { cat in
                        Label(cat.name, systemImage: cat.icon)
                            .searchCompletion(cat.query)
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SearchViewModel(
                    apiClient: repository.apiClient,
                    repository: repository
                )
            }
            backgroundState.useFallback()
        }
        .fullScreenCover(item: $selectedVideo) { video in
            if let viewModel {
                let videoPlaylist = viewModel.filteredResults.compactMap { item -> Video? in
                    if case .video(let v) = item { return v }
                    return nil
                }
                VideoPlayerView(viewModel: VideoPlayerViewModel(
                    video: video,
                    playlist: videoPlaylist,
                    repository: repository
                ))
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            FullScreenImageView(photo: photo, repository: repository)
        }
        .toast(message: $toastMessage)
        .onChange(of: focusedItem) { _, newId in
            if let id = newId, let results = viewModel?.filteredResults,
               let item = results.first(where: { $0.id == id }) {
                backgroundState.update(for: item)
            } else {
                backgroundState.useFallback()
            }
        }
    }

    @ViewBuilder
    private func searchContent(_ viewModel: SearchViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    suggestionsView(viewModel)
                } else if viewModel.isSearching && viewModel.results.isEmpty {
                    SkeletonGridView(columnCount: repository.settings.tileSize.gridColumnCount)
                        .padding(.vertical, 30)
                } else if let error = viewModel.error {
                    errorView(error, viewModel: viewModel)
                } else if viewModel.filteredResults.isEmpty && viewModel.hasSearched && !viewModel.isSearching {
                    if viewModel.results.isEmpty {
                        EmptyStateView(
                            title: "Geen resultaten",
                            systemImage: "magnifyingglass",
                            description: "Geen resultaten voor \"\(viewModel.searchQuery)\""
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 20) {
                            filterBar(viewModel)
                            EmptyStateView(
                                title: "Geen resultaten met deze filters",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: "Pas je filters aan om meer resultaten te zien"
                            ) {
                                viewModel.resetFilters()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        if viewModel.hasSearched {
                            filterBar(viewModel)
                        }
                        resultsGrid(viewModel)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.isSearching)
    }

    // MARK: - Error

    private func errorView(_ error: String, viewModel: SearchViewModel) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Er ging iets mis")
                .font(.title3)
                .fontWeight(.semibold)
            Text(error)
                .font(.body)
                .foregroundStyle(.secondary)
            Button("Opnieuw proberen") {
                Task { await viewModel.search() }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Results Grid

    private func resultsGrid(_ viewModel: SearchViewModel) -> some View {
        VStack(spacing: 30) {
            LazyVGrid(
                columns: repository.settings.tileSize.gridColumns,
                spacing: 35
            ) {
                ForEach(Array(viewModel.filteredResults.enumerated()), id: \.element.id) { index, item in
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
                        let results = viewModel.filteredResults
                        let prefetchRange = (index + 1)..<min(index + 6, results.count)
                        if !prefetchRange.isEmpty {
                            let upcoming = Array(results[prefetchRange])
                            Task { await ImagePrefetchService.shared.prefetch(upcoming) }
                        }
                        if index >= results.count - 3 {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
            }
            .padding(.horizontal, 50)

            if viewModel.isLoadingMore {
                ProgressView("Meer laden...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(.vertical, 30)
    }
}
