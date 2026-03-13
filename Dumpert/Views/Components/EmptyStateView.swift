import SwiftUI

struct EmptyStateView: View {
    let title: LocalizedStringKey
    let systemImage: String
    let description: LocalizedStringKey
    var retryAction: (() -> Void)?

    @State private var iconPulse = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5), isActive: iconPulse)
                .onAppear { iconPulse = true }
                .onDisappear { iconPulse = false }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction {
                Button("Opnieuw proberen", action: retryAction)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}
