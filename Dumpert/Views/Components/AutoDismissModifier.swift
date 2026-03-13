import SwiftUI

/// Auto-dismisses a boolean binding after a delay with a smooth animation.
/// Used for transient feedback indicators (checkmarks, confirmation toasts).
extension View {
    func autoDismiss(_ isShowing: Binding<Bool>, after duration: TimeInterval = 4) -> some View {
        self.onChange(of: isShowing.wrappedValue) {
            if isShowing.wrappedValue {
                Task {
                    try? await Task.sleep(for: .seconds(duration))
                    withAnimation(.smooth) { isShowing.wrappedValue = false }
                }
            }
        }
    }
}
