import Photos

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()
    private let imageCacheManager = PHCachingImageManager()
    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status == .authorized || status == .limited)
            }
        }
    }

    func authorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func fetchAlbums(completion: @escaping ([PHAssetCollection]) -> Void) {
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        var albums: [PHAssetCollection] = []
        var identifiers = Set<String>()
        for result in [userAlbums, smartAlbums] {
            result.enumerateObjects { collection, _, _ in
                if identifiers.insert(collection.localIdentifier).inserted {
                    albums.append(collection)
                }
            }
        }
        DispatchQueue.main.async { completion(albums) }
    }

    func fetchAssets(from collection: PHAssetCollection, includeVideos: Bool, excluding hiddenIdentifiers: Set<String> = [], completion: @escaping ([String], Int) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let options = PHFetchOptions()
            options.predicate = self.assetPredicate(includeVideos: includeVideos, excluding: hiddenIdentifiers)
            let assets = PHAsset.fetchAssets(in: collection, options: options)
            var identifiers: [String] = []
            identifiers.reserveCapacity(assets.count)
            assets.enumerateObjects { asset, _, _ in identifiers.append(asset.localIdentifier) }
            DispatchQueue.main.async { completion(identifiers, assets.count) }
        }
    }

    func fetchInitialAsset(from collection: PHAssetCollection, includeVideos: Bool, excluding hiddenIdentifiers: Set<String> = [], completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let options = PHFetchOptions()
            options.predicate = self.assetPredicate(includeVideos: includeVideos, excluding: hiddenIdentifiers)
            let assets = PHAsset.fetchAssets(in: collection, options: options)
            let identifier = assets.firstObject?.localIdentifier
            DispatchQueue.main.async { completion(identifier) }
        }
    }

    func fetchAllAssets(includeVideos: Bool, excluding hiddenIdentifiers: Set<String> = [], completion: @escaping ([String], Int) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let options = self.assetOptions(includeVideos: includeVideos, excluding: hiddenIdentifiers)
            let assets = PHAsset.fetchAssets(with: options)
            var identifiers: [String] = []
            identifiers.reserveCapacity(assets.count)
            assets.enumerateObjects { asset, _, _ in identifiers.append(asset.localIdentifier) }
            DispatchQueue.main.async { completion(identifiers, assets.count) }
        }
    }

    func fetchInitialAsset(includeVideos: Bool, excluding hiddenIdentifiers: Set<String> = [], completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let assets = PHAsset.fetchAssets(with: self.assetOptions(includeVideos: includeVideos, excluding: hiddenIdentifiers))
            let identifier = assets.firstObject?.localIdentifier
            DispatchQueue.main.async { completion(identifier) }
        }
    }

    private func assetOptions(includeVideos: Bool, excluding hiddenIdentifiers: Set<String> = []) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = assetPredicate(includeVideos: includeVideos, excluding: hiddenIdentifiers)
        return options
    }

    private func assetPredicate(includeVideos: Bool, excluding hiddenIdentifiers: Set<String>) -> NSPredicate? {
        var predicates: [NSPredicate] = []
        if !includeVideos {
            predicates.append(NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue))
        }
        if !hiddenIdentifiers.isEmpty {
            predicates.append(NSPredicate(format: "NOT (localIdentifier IN %@)", Array(hiddenIdentifiers)))
        }
        return predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    func prefetchImages(with identifiers: [String], targetSize: CGSize) {
        guard !identifiers.isEmpty else { return }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var imageAssets: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            if asset.mediaType == .image {
                imageAssets.append(asset)
            }
        }
        guard !imageAssets.isEmpty else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        imageCacheManager.startCachingImages(
            for: imageAssets,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        )
    }
}
