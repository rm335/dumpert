import SwiftUI

struct UpNextSettingsView: View {
    @Environment(VideoRepository.self) private var repository

    var body: some View {
        @Bindable var settings = repository.settings

        List {
            Section {
                Toggle(isOn: $settings.upNextOverlayEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Overlay tonen")
                            Text("Toon een aftelling met de volgende video")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 12)
                    } icon: {
                        Image(systemName: settings.upNextOverlayEnabled ? "rectangle.inset.filled" : "rectangle")
                            .foregroundStyle(settings.upNextOverlayEnabled ? .dumpiGreen : .secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            } footer: {
                if !settings.upNextOverlayEnabled {
                    Text("De volgende video start direct zonder aftelling.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if settings.upNextOverlayEnabled {
                Section {
                    NavigationLink {
                        SettingsPickerDestination(
                            title: "Aftelling",
                            selection: $settings.upNextCountdownSeconds,
                            options: [
                                ("3 seconden", 3),
                                ("5 seconden", 5),
                                ("10 seconden", 10),
                            ]
                        )
                    } label: {
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Aftelling")
                                    Text("Aantal seconden voordat de volgende video start")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.leading, 12)
                            } icon: {
                                Image(systemName: "timer")
                            }
                            Spacer()
                            Text("\(settings.upNextCountdownSeconds) seconden")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                    }

                    NavigationLink {
                        SettingsPickerDestination(
                            title: "Minimale videolengte",
                            selection: $settings.upNextMinimumVideoSeconds,
                            options: [
                                ("Geen minimum", 0),
                                ("30 seconden", 30),
                                ("1 minuut", 60),
                                ("2 minuten", 120),
                                ("5 minuten", 300),
                            ]
                        )
                    } label: {
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Minimale videolengte")
                                    Text("Toon de overlay alleen bij langere video's")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.leading, 12)
                            } icon: {
                                Image(systemName: "film")
                            }
                            Spacer()
                            Text(minimumVideoLengthLabel(settings.upNextMinimumVideoSeconds))
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        }
                    }
                }
            }
        }
        .navigationTitle("Volgende video")
        .animation(.smooth, value: settings.upNextOverlayEnabled)
    }

    private func minimumVideoLengthLabel(_ seconds: Int) -> LocalizedStringKey {
        switch seconds {
        case 0: "Geen minimum"
        case 30: "30 seconden"
        case 60: "1 minuut"
        case 120: "2 minuten"
        case 300: "5 minuten"
        default: "\(seconds)s"
        }
    }
}
