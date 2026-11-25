import SwiftUI

struct DocumentationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("FrameFlow displays photos from your Apple Photos library as a private digital photo frame.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    documentationSection(
                        "Photos and albums",
                        details: [
                            "Choose a Photos album or use All Photos as the slideshow source.",
                            "Grant Photos access when prompted. Limited Photos access is supported.",
                            "Hide a photo from the slideshow and manage the hidden-photo list from Settings."
                        ]
                    )

                    documentationSection(
                        "Slideshow",
                        details: [
                            "Choose random order, which shuffles photos without repeating before the cycle completes, or sequential order.",
                            "Set how long each photo is displayed and choose a cross-dissolve transition or no transition.",
                            "Choose Fit to show the whole photo or Fill to fill the screen.",
                            "Optionally show photo time and location metadata.",
                            "Choose to skip videos, play them with sound, or play them muted."
                        ]
                    )

                    documentationSection(
                        "Slideshow controls",
                        details: [
                            "Tap the slideshow to show or hide its controls.",
                            "Pause or resume, hide the current photo, or open Settings from the controls.",
                            "Tap the moon-and-sleep icon in the controls to enter manual standby. Tap the standby icon on the standby screen to resume."
                        ]
                    )

                    documentationSection(
                        "Presence-based standby on iPad",
                        details: [
                            "When no person is detected for the configured delay, the slideshow pauses and shows a black standby screen.",
                            "Automatic Sleep is off by default. Enable it in Settings to use presence detection; the default delay is 15 minutes, with options from 1 minute to 1 hour.",
                            "Automatic standby resumes when a person is detected. Manual standby resumes only when you tap the standby icon.",
                            "FrameFlow requests camera access only after Automatic Sleep is enabled and you start the slideshow. If access is unavailable, the slideshow remains usable, but automatic presence-based standby is unavailable.",
                            "The iPad stays awake while presence detection is active. Locking or backgrounding the app stops camera detection."
                        ]
                    )

                    documentationSection(
                        "Privacy",
                        details: [
                            "Photos are read from the device's Photos library. FrameFlow does not upload photos.",
                            "Camera frames are analyzed on-device for human presence; they are not saved or sent anywhere.",
                            "Settings, including the selected source and slideshow preferences, are stored locally on the device."
                        ]
                    )

                    documentationSection(
                        "Platform requirements",
                        details: [
                            "iPad: iPadOS 17.7 or later. A working front camera and camera permission are needed for automatic presence detection; this feature is off by default.",
                            "Mac: macOS 14.0 or later. Slideshow features are available; presence-based standby is currently iPad-only."
                        ]
                    )
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .navigationTitle("Documentation")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func documentationSection(_ title: String, details: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))

            ForEach(Array(details.enumerated()), id: \.offset) { _, detail in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.secondary)
                    Text(detail)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
