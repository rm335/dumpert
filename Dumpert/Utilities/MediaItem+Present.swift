import SwiftUI

extension MediaItem {
    func present(selectedVideo: Binding<Video?>, selectedPhoto: Binding<Photo?>) {
        switch self {
        case .video(let video):
            selectedVideo.wrappedValue = video
        case .photo(let photo):
            selectedPhoto.wrappedValue = photo
        }
    }
}
