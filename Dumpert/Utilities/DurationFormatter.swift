import Foundation

extension Int {
    var formattedDuration: String {
        let minutes = self / 60
        let secs = self % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
