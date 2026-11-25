import Combine
import Photos

final class SlideshowViewModel: ObservableObject {
    @Published var currentAssetIdentifier: String?
    @Published var isPaused = false
    @Published var isLoading = false

    private let settingsStore: SettingsStore
    private let shuffleManager: ShuffleManager
    private let photoLibraryService = PhotoLibraryService.shared
    private var timer: Timer?
    private let selectedAlbumIdentifier: String?

    init(settingsStore: SettingsStore, selectedAlbumIdentifier: String?) {
        self.settingsStore = settingsStore
        self.selectedAlbumIdentifier = selectedAlbumIdentifier
        shuffleManager = ShuffleManager(orderMode: settingsStore.orderMode)
    }

    func start() {
        isLoading = true
        let authorizationStatus = photoLibraryService.authorizationStatus()
        if authorizationStatus == .notDetermined {
            photoLibraryService.requestAuthorization { [weak self] authorized in
                guard let self else { return }
                if authorized {
                    start()
                } else {
                    isLoading = false
                }
            }
            return
        }
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            isLoading = false
            return
        }

        let includeVideos = settingsStore.videoPlaybackMode != .skip
        if settingsStore.allPhotosSelected {
            photoLibraryService.fetchInitialAsset(includeVideos: includeVideos, excluding: settingsStore.hiddenAssetIdentifiers) { [weak self] identifier in
                self?.currentAssetIdentifier = identifier
                self?.isLoading = false
            }
            photoLibraryService.fetchAllAssets(includeVideos: includeVideos, excluding: settingsStore.hiddenAssetIdentifiers) { [weak self] identifiers, _ in
                guard let self else { return }
                shuffleManager.setItems(identifiers, avoidIdentifier: currentAssetIdentifier)
                if currentAssetIdentifier == nil {
                    currentAssetIdentifier = shuffleManager.nextItem()
                }
                photoLibraryService.prefetchImages(with: identifiers.prefix(10).map { $0 }, targetSize: CGSize(width: 1200, height: 1200))
                isLoading = false
                startTimer()
            }
            return
        }
        guard let albumIdentifier = selectedAlbumIdentifier else {
            isLoading = false
            return
        }
        let albums = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumIdentifier], options: nil)
        guard let album = albums.firstObject else {
            isLoading = false
            return
        }
        photoLibraryService.fetchInitialAsset(from: album, includeVideos: includeVideos, excluding: settingsStore.hiddenAssetIdentifiers) { [weak self] identifier in
            guard let self else { return }
            currentAssetIdentifier = identifier
            isLoading = false
        }
        photoLibraryService.fetchAssets(from: album, includeVideos: includeVideos, excluding: settingsStore.hiddenAssetIdentifiers) { [weak self] identifiers, _ in
            guard let self else { return }
            shuffleManager.setItems(identifiers, avoidIdentifier: currentAssetIdentifier)
            if currentAssetIdentifier == nil {
                currentAssetIdentifier = shuffleManager.nextItem()
            }
            photoLibraryService.prefetchImages(with: identifiers.prefix(10).map { $0 }, targetSize: CGSize(width: 1200, height: 1200))
            isLoading = false
            startTimer()
        }
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        isPaused = false
        startTimer()
    }

    func skipCurrent() {
        currentAssetIdentifier = shuffleManager.nextItem()
        if currentAssetIdentifier == nil { start() }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: settingsStore.photoDurationSeconds, repeats: true) { [weak self] _ in
            guard let self, !isPaused else { return }
            currentAssetIdentifier = shuffleManager.nextItem()
            if currentAssetIdentifier == nil { start() }
        }
    }

    deinit { timer?.invalidate() }
}
