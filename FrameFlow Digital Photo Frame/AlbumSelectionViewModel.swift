import Combine
import Photos

final class AlbumSelectionViewModel: ObservableObject {
    @Published var albums: [PHAssetCollection] = []
    @Published var isPermissionDenied = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let photoLibraryService = PhotoLibraryService.shared
    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func checkPermissionAndFetchAlbums() {
        isLoading = true
        errorMessage = nil
        switch photoLibraryService.authorizationStatus() {
        case .notDetermined:
            photoLibraryService.requestAuthorization { [weak self] authorized in
                authorized ? self?.fetchAlbums() : self?.handlePermissionDenied()
            }
        case .authorized, .limited:
            fetchAlbums()
        default:
            handlePermissionDenied()
        }
    }

    func fetchAlbums() {
        photoLibraryService.fetchAlbums { [weak self] albums in
            self?.albums = albums
            self?.isLoading = false
        }
    }

    func selectAlbum(_ collection: PHAssetCollection) {
        settingsStore.selectedAlbumIdentifier = collection.localIdentifier
        settingsStore.selectedAlbumName = collection.localizedTitle ?? "Untitled Album"
        settingsStore.allPhotosSelected = false
    }

    private func handlePermissionDenied() {
        isLoading = false
        isPermissionDenied = true
    }
}
