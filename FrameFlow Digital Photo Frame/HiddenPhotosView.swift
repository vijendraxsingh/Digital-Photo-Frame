import Photos
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct HiddenPhotosView: View {
    @ObservedObject var settingsStore: SettingsStore
    var onDismiss: () -> Void

    @State private var source: PhotoSource = .allPhotos
    @State private var albums: [PHAssetCollection] = []
    @State private var selectedAlbumIdentifier: String?
    @State private var assets: [PHAsset] = []
    @State private var loadToken = UUID()

    private enum PhotoSource: String, CaseIterable, Identifiable {
        case allPhotos
        case album
        case hiddenPhotos

        var id: String { rawValue }
        var title: String {
            switch self {
            case .allPhotos: return "All Photos"
            case .album: return "Album"
            case .hiddenPhotos: return "Hidden Photos"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Browse", selection: $source) {
                    ForEach(PhotoSource.allCases) { source in
                        Text(source.title).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                if source == .album {
                    if albums.isEmpty {
                        Text("No albums available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Album", selection: $selectedAlbumIdentifier) {
                            Text("Choose an album").tag(String?.none)
                            ForEach(albums, id: \.localIdentifier) { album in
                                Text(album.localizedTitle ?? "Untitled Album")
                                    .tag(Optional(album.localIdentifier))
                            }
                        }
                    }
                }

                 Text(source == .hiddenPhotos
                     ? "Hidden Photos"
                     : "Hidden Photos: \(settingsStore.hiddenAssetIdentifiers.count)")
                    .font(.headline)

                if assets.isEmpty {
                    Text(source == .album && selectedAlbumIdentifier == nil
                         ? "Choose an album to manage hidden photos."
                         : "No photos found.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                            ForEach(assets, id: \.localIdentifier) { asset in
                                Button(action: { toggleHidden(asset) }) {
                                    HiddenPhotoThumbnail(
                                        asset: asset,
                                        isHidden: settingsStore.hiddenAssetIdentifiers.contains(asset.localIdentifier)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Hidden Photos")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .onAppear {
            selectedAlbumIdentifier = settingsStore.selectedAlbumIdentifier
            DispatchQueue.main.async {
                refreshPhotos()
            }
        }
        .onChange(of: source) { _, _ in loadAssets() }
        .onChange(of: selectedAlbumIdentifier) { _, _ in loadAssets() }
    }

    private func loadAlbums() {
        PhotoLibraryService.shared.fetchAlbums { loadedAlbums in
            albums = loadedAlbums
        }
    }

    private func refreshPhotos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            PhotoLibraryService.shared.requestAuthorization { authorized in
                guard authorized else { return }
                loadAlbums()
                loadAssets()
            }
        } else if status == .authorized || status == .limited {
            loadAlbums()
            loadAssets()
        }
    }

    private func loadAssets() {
        let token = UUID()
        loadToken = token
        let requestedSource = source
        let requestedAlbumIdentifier = selectedAlbumIdentifier
        let hiddenIdentifiers = settingsStore.hiddenAssetIdentifiers

        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized ||
                PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited else {
            assets = []
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var loadedAssets: [PHAsset] = []
            if requestedSource == .hiddenPhotos {
                let result = PHAsset.fetchAssets(withLocalIdentifiers: Array(hiddenIdentifiers), options: nil)
                result.enumerateObjects { asset, _, _ in
                    if asset.mediaType == .image { loadedAssets.append(asset) }
                }
            } else if requestedSource == .allPhotos {
                let options = PHFetchOptions()
                options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                let result = PHAsset.fetchAssets(with: options)
                result.enumerateObjects { asset, _, _ in loadedAssets.append(asset) }
            } else if let identifier = requestedAlbumIdentifier,
                      let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil).firstObject {
                let result = PHAsset.fetchAssets(in: album, options: nil)
                result.enumerateObjects { asset, _, _ in
                    if asset.mediaType == .image { loadedAssets.append(asset) }
                }
            }

            DispatchQueue.main.async {
                guard token == loadToken else { return }
                assets = loadedAssets
            }
        }
    }

    private func toggleHidden(_ asset: PHAsset) {
        if settingsStore.hiddenAssetIdentifiers.contains(asset.localIdentifier) {
            settingsStore.hiddenAssetIdentifiers.remove(asset.localIdentifier)
            if source == .hiddenPhotos {
                assets.removeAll { $0.localIdentifier == asset.localIdentifier }
            }
        } else {
            settingsStore.hiddenAssetIdentifiers.insert(asset.localIdentifier)
        }
    }
}

private struct HiddenPhotoThumbnail: View {
    let asset: PHAsset
    let isHidden: Bool

    #if os(iOS)
    @State private var image: UIImage?
    #else
    @State private var image: NSImage?
    #endif

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                    #endif
                } else {
                    Color.secondary.opacity(0.2)
                        .overlay { ProgressView() }
                }
            }
            .frame(minWidth: 110, minHeight: 110)
            .aspectRatio(1, contentMode: .fit)
            .clipped()

            if isHidden {
                Image(systemName: "eye.slash.fill")
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.black.opacity(0.7), in: Circle())
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear { loadImage() }
    }

    private func loadImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        let size = CGSize(width: 300, height: 300)
        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async { self.image = image }
        }
    }
}
