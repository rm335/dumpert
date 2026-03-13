import SwiftUI

struct ResumeOverlayView: View {
    let formattedTime: String
    let isVisible: Bool
    let onPlayFromBeginning: () -> Void

    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 16) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))

                    Text("Hervat op \(formattedTime)")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Button(action: onPlayFromBeginning) {
                        Text("Speel vanaf begin")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(ResumeButtonStyle())
                    .accessibilityLabel("Speel video vanaf het begin")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.top, 20)
                .padding(.leading, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Hervat op \(formattedTime)")
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.5), value: isVisible)
    }
}

// MARK: - Button Style

private struct ResumeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.2))
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
