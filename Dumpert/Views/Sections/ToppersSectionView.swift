import SwiftUI

struct ToppersSectionView: View {
    @Environment(VideoRepository.self) private var repository
    @State private var selectedVideo: Video?
    @State private var selectedPhoto: Photo?
    @State private var toastMessage: String?
    @State private var heroIndex = 0
    @State private var heroAutoRotate = true
    @FocusState private var focusedItem: String?

    private var heroItems: [MediaItem] {
        Array(repository.filteredItems(repository.hotshiz).prefix(5))
    }

    var body: some View {
        ZStack {
            if repository.isLoading && repository.hotshiz.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        // Skeleton hero — matches heroCarousel layout
                        ZStack(alignment: .bottomLeading) {
                            Color.white.opacity(0.05)
                                .frame(height: 460)
                                .shimmering()

                            // Info overlay placeholder
                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white.opacity(0.1))
                                    .frame(width: 320, height: 22)
                                    .shimmering()
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.white.opacity(0.06))
                                    .frame(width: 200, height: 14)
                                HStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(.white.opacity(0.06))
                                        .frame(width: 60, height: 12)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(.white.opacity(0.06))
                                        .frame(width: 40, height: 12)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(.white.opacity(0.06))
                                        .frame(width: 70, height: 12)
                                }
                            }
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)

                            // Page indicators placeholder
                            HStack(spacing: 8) {
                                ForEach(0..<5, id: \.self) { i in
                                    Circle()
                                        .fill(i == 0 ? Color.white.opacity(0.3) : .white.opacity(0.1))
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(20)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))

                        SkeletonRowView(cardWidth: repository.settings.tileSize.horizontalCardWidth)
                        SkeletonRowView(cardWidth: repository.settings.tileSize.horizontalCardWidth)
                        SkeletonRowView(cardWidth: repository.settings.tileSize.horizontalCardWidth)
                    }
                    .padding(.horizontal, 50)
                    .padding(.vertical, 30)
                }
                .transition(.opacity)
            } else if let error = repository.error, repository.hotshiz.isEmpty {
                errorView(message: error)
                    .transition(.opacity)
            } else if !repository.isLoading && repository.hotshiz.isEmpty
                        && repository.topWeek.isEmpty {
                EmptyStateView(
                    title: "Geen video's",
                    systemImage: "video.slash",
                    description: "Kon geen video's laden. Controleer je internetverbinding."
                ) {
                    Task { await repository.refreshAll() }
                }
                .transition(.opacity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        // Hero Carousel
                        if !heroItems.isEmpty {
                            heroCarousel
                        }

                        mediaRow(title: "Trending Nu", items: repository.filteredItems(repository.hotshiz))
                        mediaRow(title: "Top Deze Week", items: repository.filteredItems(repository.topWeek))
                        mediaRow(title: "Top Deze Maand", items: repository.filteredItems(repository.topMonth))
                    }
                    .padding(.horizontal, 50)
                    .padding(.vertical, 30)
                }
                .refreshable {
                    await repository.refreshAll()
                }
            }
        }
        .animation(.easeOut(duration: 0.3), value: repository.isLoading)
        .fullScreenCover(item: $selectedVideo) { video in
            let videoPlaylist = repository.filteredItems(repository.hotshiz).compactMap { item -> Video? in
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

    @ViewBuilder
    private func mediaRow(title: LocalizedStringKey, items: [MediaItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 30) {
                        ForEach(items) { item in
                            Button {
                                item.present(selectedVideo: $selectedVideo, selectedPhoto: $selectedPhoto)
                            } label: {
                                VideoCardView(
                                    item: item,
                                    isWatched: repository.isWatched(item.id),
                                    progress: repository.progressFor(item.id),
                                    isFocused: focusedItem == item.id,
                                    thumbnailPreviewEnabled: repository.settings.thumbnailPreviewEnabled
                                )
                            }
                            .buttonStyle(.card)
                            .frame(width: repository.settings.tileSize.horizontalCardWidth)
                            .focused($focusedItem, equals: item.id)
                            .contextMenu {
                                Button(repository.isWatched(item.id) ? "Markeer als onbekeken" : "Markeer als bekeken") {
                                    let wasWatched = repository.isWatched(item.id)
                                    repository.toggleWatched(videoId: item.id)
                                    toastMessage = wasWatched ? String(localized: "Gemarkeerd als onbekeken") : String(localized: "Gemarkeerd als bekeken")
                                }
                                ForEach(VideoCategory.allCases.filter { !$0.usesLatestEndpoint }) { category in
                                    Button("Voeg toe aan \(category.displayName)") {
                                        repository.addToCategory(videoId: item.id, category: category)
                                        toastMessage = String(localized: "Toegevoegd aan \(category.displayName)")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                .scrollClipDisabled()
            }
        }
    }

    // MARK: - Hero Carousel

    private var heroCarousel: some View {
        Button {
            heroItems[heroIndex].present(selectedVideo: $selectedVideo, selectedPhoto: $selectedPhoto)
        } label: {
            ZStack(alignment: .bottomLeading) {
                // All hero thumbnails stacked, crossfading via opacity
                ZStack {
                    ForEach(Array(heroItems.enumerated()), id: \.element.id) { index, item in
                        FaceCenteredThumbnailView(
                            url: item.thumbnailURL,
                            useIntrinsicAspectRatio: false
                        )
                        .frame(height: 460)
                        .clipped()
                        .opacity(index == heroIndex ? 1 : 0)
                    }
                }

                // Info overlay crossfades with the thumbnail
                heroInfoOverlay(for: heroItems[heroIndex])
                    .id(heroItems[heroIndex].id)
                    .transition(.opacity)

                // Page indicators
                if heroItems.count > 1 {
                    pageIndicators
                }
            }
            .cornerRadius(24)
            .animation(.spring(duration: 0.7, bounce: 0.15), value: heroIndex)
        }
        .buttonStyle(.card)
        .onMoveCommand { direction in
            switch direction {
            case .left:
                heroAutoRotate = false
                withAnimation(.spring(duration: 0.7, bounce: 0.15)) {
                    heroIndex = (heroIndex - 1 + heroItems.count) % heroItems.count
                }
                resumeAutoRotateAfterDelay()
            case .right:
                heroAutoRotate = false
                withAnimation(.spring(duration: 0.7, bounce: 0.15)) {
                    heroIndex = (heroIndex + 1) % heroItems.count
                }
                resumeAutoRotateAfterDelay()
            default:
                break
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(heroItems[heroIndex].title), item \(heroIndex + 1) van \(heroItems.count)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                heroIndex = (heroIndex + 1) % heroItems.count
            case .decrement:
                heroIndex = (heroIndex - 1 + heroItems.count) % heroItems.count
            @unknown default:
                break
            }
        }
        .onChange(of: heroItems.count) {
            if heroIndex >= heroItems.count && !heroItems.isEmpty {
                heroIndex = 0
            }
        }
        .task(id: heroItems.count) {
            guard heroItems.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(6))
                guard !Task.isCancelled else { return }
                if heroAutoRotate {
                    heroIndex = (heroIndex + 1) % heroItems.count
                }
            }
        }
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<heroItems.count, id: \.self) { index in
                Circle()
                    .fill(index == heroIndex ? Color.dumpiGreen : .white.opacity(0.4))
                    .frame(width: 10, height: 10)
                    .scaleEffect(index == heroIndex ? 1.3 : 1.0)
                    .animation(.spring(duration: 0.4, bounce: 0.3), value: heroIndex)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(20)
    }

    @ViewBuilder
    private func heroInfoOverlay(for hero: MediaItem) -> some View {
        let infoContent = VStack(alignment: .leading, spacing: 8) {
            Text(hero.title)
                .font(.title2)
                .fontWeight(.bold)
            if !hero.descriptionText.isEmpty {
                Text(hero.descriptionText)
                    .font(.callout)
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(0.8))
            }
            HStack(spacing: 10) {
                KudosBadgeView(kudos: hero.kudosTotal)
                if hero.isVideo && hero.duration > 0 {
                    Text(hero.duration.formattedDuration)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.7))
                }
                if hero.isPhoto {
                    Image(systemName: "photo.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                if let date = hero.date {
                    Text(date.relativeString)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }

        if #available(tvOS 26, *) {
            infoContent
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(in: UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 0,
                        bottomLeading: 20,
                        bottomTrailing: 20,
                        topTrailing: 0
                    )
                ))
        } else {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.3),
                        .init(color: .black.opacity(0.9), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                infoContent
                    .padding(36)
            }
        }
    }

    private func resumeAutoRotateAfterDelay() {
        Task {
            try? await Task.sleep(for: .seconds(10))
            heroAutoRotate = true
        }
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            title: "Er ging iets mis",
            systemImage: "exclamationmark.triangle",
            description: "\(message)"
        ) {
            Task { await repository.refreshAll() }
        }
    }
}
