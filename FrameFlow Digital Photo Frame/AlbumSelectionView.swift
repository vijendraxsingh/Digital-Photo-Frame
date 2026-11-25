import SwiftUI
import Photos

struct AlbumSelectionView: View {
    @StateObject private var viewModel: AlbumSelectionViewModel
    @ObservedObject var settingsStore: SettingsStore
    var onStartSlideshow: () -> Void
    var onOpenSettings: () -> Void

    init(
        settingsStore: SettingsStore,
        onStartSlideshow: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self._viewModel = StateObject(wrappedValue: AlbumSelectionViewModel(settingsStore: settingsStore))
        self.onStartSlideshow = onStartSlideshow
        self.onOpenSettings = onOpenSettings
    }

    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    ProgressView("Loading Albums...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else if viewModel.isPermissionDenied {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.slash")
                            .font(.largeTitle)
                        Text("Photo Library Access Denied")
                            .font(.headline)
                        Text("Please enable photo access in Settings to use this app.")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                    }
                } else if viewModel.albums.isEmpty {
                    VStack(spacing: 16) {
                        Text("No albums found")
                            .font(.headline)
                        Text("Create an album in Photos, then try again.")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                        Button("Try Again", action: viewModel.checkPermissionAndFetchAlbums)
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Section(header: Text("Your Albums")) {
                        ForEach(Array(viewModel.albums.enumerated()), id: \.offset) { _, collection in
                            let isSelected = settingsStore.selectedAlbumIdentifier == collection.localIdentifier
                            let textColor: Color = isSelected ? .accentColor : .primary
                            let fontWeight: Font.Weight = isSelected ? .bold : .regular
                            Button(action: {
                                viewModel.selectAlbum(collection)
                            }) {
                                HStack {
                                    Text(collection.localizedTitle ?? "Untitled Album")
                                        .foregroundColor(textColor)
                                        .fontWeight(fontWeight)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Photo Frame")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .automatic) {
                    if settingsStore.selectedAlbumIdentifier != nil {
                        Button("Start Slideshow") {
                            onStartSlideshow()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .onAppear {
            viewModel.checkPermissionAndFetchAlbums()
        }
    }
}

