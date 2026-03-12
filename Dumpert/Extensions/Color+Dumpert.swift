import SwiftUI

extension Color {
    /// Dumpert brand green (#65B32E)
    static let dumpiGreen = Color(red: 0.396, green: 0.702, blue: 0.180)

    /// Slightly lighter variant for highlights
    static let dumpiGreenLight = Color(red: 0.45, green: 0.78, blue: 0.25)

    /// Darker variant for backgrounds/subtle accents
    static let dumpiGreenDark = Color(red: 0.30, green: 0.55, blue: 0.12)
}

extension ShapeStyle where Self == Color {
    /// Dumpert brand green
    static var dumpiGreen: Color { .dumpiGreen }
}
