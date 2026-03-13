import SwiftUI

/// Shared context menu for video/photo items across all section views.
/// Provides watch toggle and category management actions.
struct VideoContextMenuModifier: ViewModifier {
    let item: MediaItem
    let repository: VideoRepository
    @Binding var toastMessage: String?
    var currentCategory: VideoCategory?

    func body(content: Content) -> some View {
        content.contextMenu {
            Button(repository.isWatched(item.id) ? "Markeer als onbekeken" : "Markeer als bekeken") {
                let wasWatched = repository.isWatched(item.id)
                repository.toggleWatched(videoId: item.id)
                toastMessage = wasWatched
                    ? String(localized: "Gemarkeerd als onbekeken")
                    : String(localized: "Gemarkeerd als bekeken")
            }

            if let currentCategory, !currentCategory.usesLatestEndpoint {
                Button("Verwijder uit \(currentCategory.displayName)") {
                    repository.removeFromCategory(videoId: item.id, category: currentCategory)
                    toastMessage = String(localized: "Verwijderd uit \(currentCategory.displayName)")
                }
            }

            ForEach(VideoCategory.allCases.filter { $0 != currentCategory && !$0.usesLatestEndpoint }) { category in
                Button("Voeg toe aan \(category.displayName)") {
                    repository.addToCategory(videoId: item.id, category: category)
                    toastMessage = String(localized: "Toegevoegd aan \(category.displayName)")
                }
            }
        }
    }
}

extension View {
    func videoContextMenu(
        item: MediaItem,
        repository: VideoRepository,
        toastMessage: Binding<String?>,
        currentCategory: VideoCategory? = nil
    ) -> some View {
        modifier(VideoContextMenuModifier(
            item: item,
            repository: repository,
            toastMessage: toastMessage,
            currentCategory: currentCategory
        ))
    }
}
