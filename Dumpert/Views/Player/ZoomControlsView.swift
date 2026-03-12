import SwiftUI

extension FullScreenImageView {
    var zoomControls: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            currentScale = min(currentScale + zoomStep, maxScale)
                        }
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.title3)
                            .frame(width: 50, height: 50)
                    }
                    .accessibilityLabel("Inzoomen")

                    if currentScale > minScale {
                        Text("\(Int(currentScale * 100))%")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            let newScale = currentScale - zoomStep
                            if newScale <= minScale {
                                resetZoom()
                            } else {
                                currentScale = newScale
                            }
                        }
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.title3)
                            .frame(width: 50, height: 50)
                    }
                    .accessibilityLabel("Uitzoomen")
                    .disabled(currentScale <= minScale)

                    if currentScale > minScale {
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                resetZoom()
                            }
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.title3)
                                .frame(width: 50, height: 50)
                        }
                        .accessibilityLabel("Zoom resetten")
                    }
                }
                .buttonStyle(.plain)
                .padding(16)
                .modifier(GlassControlsModifier())
                .focusSection()
            }
            .padding(.trailing, 40)
            .padding(.bottom, 40)
        }
    }
}

/// Applies Liquid Glass on tvOS 26+, no additional background on older versions.
struct GlassControlsModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(tvOS 26, *) {
            content
                .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        } else {
            content
        }
    }
}
