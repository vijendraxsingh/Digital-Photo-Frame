import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    var onSelectAlbum: () -> Void
    var onStartFrameFlow: () -> Void
    var onManageHiddenPhotos: () -> Void
    @State private var isDocumentationPresented = false

    init(
        settingsStore: SettingsStore,
        onSelectAlbum: @escaping () -> Void = {},
        onStartFrameFlow: @escaping () -> Void = {},
        onManageHiddenPhotos: @escaping () -> Void = {}
    ) {
        self.settingsStore = settingsStore
        self.onSelectAlbum = onSelectAlbum
        self.onStartFrameFlow = onStartFrameFlow
        self.onManageHiddenPhotos = onManageHiddenPhotos
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    logoPanel
                    settingsPanel
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $isDocumentationPresented) {
            DocumentationView()
        }
    }

    private var logoPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            bundledLogo
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220, alignment: .topLeading)
                .accessibilityLabel("FrameFlow")

            Text("Your private digital photo frame")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var bundledLogo: Image {
        guard let path = Bundle.main.path(forResource: "FrameFlow", ofType: "png") else {
            return Image(systemName: "photo")
        }

        #if os(iOS)
        guard let image = UIImage(contentsOfFile: path) else {
            return Image(systemName: "photo")
        }
        return Image(uiImage: image)
        #else
        guard let image = NSImage(contentsOfFile: path) else {
            return Image(systemName: "photo")
        }
        return Image(nsImage: image)
        #endif
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsSection("Photo Library", description: "Choose which photos FrameFlow uses.") {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Selected Source")
                            .foregroundColor(.secondary)
                        Text(settingsStore.selectedAlbumIdentifier == nil ? "All Photos" : (settingsStore.selectedAlbumName ?? "Unknown Album"))
                    }

                    describedButton(
                        "Start FrameFlow",
                        description: "Start the slideshow using the selected photo source.",
                        systemImage: "play.fill",
                        action: onStartFrameFlow,
                        prominent: true
                    )

                    describedButton(
                        "Select Album",
                        description: "Choose a Photos album for the slideshow.",
                        systemImage: "photo.on.rectangle.angled",
                        action: onSelectAlbum
                    )

                    describedButton(
                        "Manage Hidden Photos",
                        description: "Review or restore photos you have hidden from the slideshow.",
                        systemImage: "eye.slash",
                        action: onManageHiddenPhotos
                    )
                }
            }

            settingsSection("Playback", description: "Choose how long photos appear and how the slideshow advances.") {
                VStack(alignment: .leading, spacing: 18) {
                    describedPicker(
                        "Photo Duration",
                        description: "Set how long each photo stays on screen.",
                        selection: $settingsStore.photoDurationSeconds
                    ) {
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("15 seconds").tag(15.0)
                        Text("30 seconds").tag(30.0)
                        Text("1 minute").tag(60.0)
                        Text("5 minutes").tag(300.0)
                    }

                    describedPicker(
                        "Order",
                        description: "Choose shuffled playback or follow the album's order.",
                        selection: $settingsStore.orderMode
                    ) {
                        Text("Random").tag(SettingsStore.OrderMode.random)
                        Text("Sequential").tag(SettingsStore.OrderMode.sequential)
                    }

                    describedPicker(
                        "Transition",
                        description: "Choose whether photos cross-dissolve as they change.",
                        selection: $settingsStore.transitionType
                    ) {
                        Text("Cross Dissolve").tag(SettingsStore.TransitionType.crossFade)
                        Text("None").tag(SettingsStore.TransitionType.none)
                    }

                    describedPicker(
                        "Videos",
                        description: "Choose whether videos play and whether their audio is used.",
                        selection: $settingsStore.videoPlaybackMode
                    ) {
                        Text("Skip Videos").tag(SettingsStore.VideoPlaybackMode.skip)
                        Text("Play With Sound").tag(SettingsStore.VideoPlaybackMode.sound)
                        Text("Play Muted").tag(SettingsStore.VideoPlaybackMode.muted)
                    }
                }
            }

            settingsSection("Display", description: "Adjust photo framing and optional details.") {
                VStack(alignment: .leading, spacing: 18) {
                    describedPicker(
                        "Display Mode",
                        description: "Fit shows the whole photo; Fill crops it to fill the screen.",
                        selection: $settingsStore.displayMode
                    ) {
                        Text("Fill").tag(SettingsStore.DisplayMode.fill)
                        Text("Fit").tag(SettingsStore.DisplayMode.fit)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Show Time and Location", isOn: $settingsStore.showPhotoMetadata)
                        Text("Show available capture time and location details over each photo.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            settingsSection("Automatic Sleep", description: "Put the slideshow into standby when nobody is in front of the iPad.") {
                #if os(iOS)
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Enable Automatic Sleep", isOn: $settingsStore.automaticPresenceSleepEnabled)
                        Text("Off by default. When enabled, FrameFlow asks for camera access when you start the slideshow. Camera images are processed on this device and are not saved or sent anywhere.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    describedPicker(
                        "Sleep Delay",
                        description: "Choose how long a person must be absent before standby starts.",
                        selection: $settingsStore.presenceTimeoutSeconds
                    ) {
                        Text("1 minute").tag(60.0)
                        Text("5 minutes").tag(300.0)
                        Text("10 minutes").tag(600.0)
                        Text("15 minutes").tag(900.0)
                        Text("20 minutes").tag(1200.0)
                        Text("30 minutes").tag(1800.0)
                        Text("45 minutes").tag(2700.0)
                        Text("1 hour").tag(3600.0)
                    }
                    .disabled(!settingsStore.automaticPresenceSleepEnabled)
                }
                #else
                Text("Presence-based standby is available on iPad.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                #endif
            }

            settingsSection("Help", description: "Learn about features, privacy, and supported devices.") {
                describedButton(
                    "Documentation",
                    description: "Open the in-app guide to FrameFlow's features and requirements.",
                    systemImage: "book.closed"
                ) {
                    isDocumentationPresented = true
                }
            }

            Text(minimumOSVersion)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsSection<Content: View>(
        _ title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func describedButton(
        _ title: String,
        description: String,
        systemImage: String,
        action: @escaping () -> Void,
        prominent: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            if prominent {
                Button(action: action) {
                    Label(title, systemImage: systemImage)
                        .frame(minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: action) {
                    Label(title, systemImage: systemImage)
                        .frame(minHeight: 40)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func describedPicker<SelectionValue: Hashable, Content: View>(
        _ title: String,
        description: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            Picker(title, selection: selection, content: content)
        }
    }

    private var minimumOSVersion: String {
        #if os(iOS)
        return "Minimum OS: iOS/iPadOS 17.7+"
        #else
        return "Minimum OS: macOS 14.0+"
        #endif
    }
}
