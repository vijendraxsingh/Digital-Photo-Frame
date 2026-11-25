import Combine
import Foundation

final class SettingsStore: ObservableObject {
    private enum Keys {
        static let selectedAlbumIdentifier = "selected_album_identifier"
        static let selectedAlbumName = "selected_album_name"
        static let allPhotosSelected = "all_photos_selected"
        static let photoDurationSeconds = "photo_duration_seconds"
        static let automaticPresenceSleepEnabled = "automatic_presence_sleep_enabled"
        static let presenceTimeoutSeconds = "presence_timeout_seconds"
        static let transitionType = "transition_type"
        static let orderMode = "order_mode"
        static let displayMode = "display_mode"
        static let showPhotoMetadata = "show_photo_metadata"
        static let videoPlaybackMode = "video_playback_mode"
        static let hiddenAssetIdentifiers = "hidden_asset_identifiers"
    }

    @Published var selectedAlbumIdentifier: String? {
        didSet { UserDefaults.standard.set(selectedAlbumIdentifier, forKey: Keys.selectedAlbumIdentifier) }
    }

    @Published var selectedAlbumName: String? {
        didSet { UserDefaults.standard.set(selectedAlbumName, forKey: Keys.selectedAlbumName) }
    }

    @Published var allPhotosSelected: Bool {
        didSet { UserDefaults.standard.set(allPhotosSelected, forKey: Keys.allPhotosSelected) }
    }

    @Published var photoDurationSeconds: Double {
        didSet { UserDefaults.standard.set(photoDurationSeconds, forKey: Keys.photoDurationSeconds) }
    }

    @Published var automaticPresenceSleepEnabled: Bool {
        didSet { UserDefaults.standard.set(automaticPresenceSleepEnabled, forKey: Keys.automaticPresenceSleepEnabled) }
    }

    @Published var presenceTimeoutSeconds: Double {
        didSet { UserDefaults.standard.set(presenceTimeoutSeconds, forKey: Keys.presenceTimeoutSeconds) }
    }

    @Published var transitionType: TransitionType {
        didSet { UserDefaults.standard.set(transitionType.rawValue, forKey: Keys.transitionType) }
    }

    @Published var orderMode: OrderMode {
        didSet { UserDefaults.standard.set(orderMode.rawValue, forKey: Keys.orderMode) }
    }

    @Published var displayMode: DisplayMode {
        didSet { UserDefaults.standard.set(displayMode.rawValue, forKey: Keys.displayMode) }
    }

    @Published var showPhotoMetadata: Bool {
        didSet { UserDefaults.standard.set(showPhotoMetadata, forKey: Keys.showPhotoMetadata) }
    }

    @Published var videoPlaybackMode: VideoPlaybackMode {
        didSet { UserDefaults.standard.set(videoPlaybackMode.rawValue, forKey: Keys.videoPlaybackMode) }
    }

    @Published var hiddenAssetIdentifiers: Set<String> {
        didSet { UserDefaults.standard.set(Array(hiddenAssetIdentifiers), forKey: Keys.hiddenAssetIdentifiers) }
    }

    enum TransitionType: String { case crossFade, none }
    enum OrderMode: String { case random, sequential }
    enum DisplayMode: String { case fit, fill }
    enum VideoPlaybackMode: String { case skip, sound, muted }

    init() {
        let defaults = UserDefaults.standard
        selectedAlbumIdentifier = defaults.string(forKey: Keys.selectedAlbumIdentifier)
        selectedAlbumName = defaults.string(forKey: Keys.selectedAlbumName)
        allPhotosSelected = defaults.bool(forKey: Keys.allPhotosSelected)
        let duration = defaults.double(forKey: Keys.photoDurationSeconds)
        photoDurationSeconds = duration == 0 ? 30 : duration
        automaticPresenceSleepEnabled = defaults.bool(forKey: Keys.automaticPresenceSleepEnabled)
        let presenceTimeout = defaults.double(forKey: Keys.presenceTimeoutSeconds)
        presenceTimeoutSeconds = presenceTimeout > 0 ? presenceTimeout : 900
        transitionType = TransitionType(rawValue: defaults.string(forKey: Keys.transitionType) ?? "") ?? .crossFade
        orderMode = OrderMode(rawValue: defaults.string(forKey: Keys.orderMode) ?? "") ?? .random
        displayMode = DisplayMode(rawValue: defaults.string(forKey: Keys.displayMode) ?? "") ?? .fit
        showPhotoMetadata = defaults.object(forKey: Keys.showPhotoMetadata) == nil
            ? true
            : defaults.bool(forKey: Keys.showPhotoMetadata)
        videoPlaybackMode = VideoPlaybackMode(rawValue: defaults.string(forKey: Keys.videoPlaybackMode) ?? "") ?? .skip
        hiddenAssetIdentifiers = Set(defaults.stringArray(forKey: Keys.hiddenAssetIdentifiers) ?? [])
    }
}
