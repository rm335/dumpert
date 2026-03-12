import SwiftUI

struct SettingsPickerDestination<V: Hashable>: View {
    let title: LocalizedStringKey
    @Binding var selection: V
    let options: [(LocalizedStringKey, V)]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button {
                    selection = option.1
                    dismiss()
                } label: {
                    HStack {
                        Text(option.0)
                        Spacer()
                        if selection == option.1 {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.dumpiGreen)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}
