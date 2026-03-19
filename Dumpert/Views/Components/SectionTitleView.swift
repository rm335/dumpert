import SwiftUI

/// Section title with a Dumpert green underline that matches the text width.
struct SectionTitleView: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    init(_ title: String) {
        self.title = LocalizedStringKey(title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .fontWeight(.bold)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.dumpiGreen)
                    .frame(width: geo.size.width / 3, height: 3)
            }
            .frame(height: 3)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
