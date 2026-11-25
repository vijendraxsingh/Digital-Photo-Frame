import SwiftUI
import Photos
import AVKit
import CoreLocation
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

struct SlideshowView: View {
    @ObservedObject var viewModel: SlideshowViewModel
    @ObservedObject var settingsStore: SettingsStore
    var onDismiss: () -> Void
    var isStandby: Bool = false
    var isManualStandby: Bool = false
    var presenceErrorMessage: String? = nil
    var onResumeFromStandby: () -> Void = {}
    var onEnterManualStandby: () -> Void = {}

    @State private var showControls: Bool = true
    @State private var isPointerHovering: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let identifier = viewModel.currentAssetIdentifier {
                PhotoDisplayView(
                    assetIdentifier: identifier,
                    displayMode: settingsStore.displayMode,
                    showMetadata: settingsStore.showPhotoMetadata,
                    videoPlaybackMode: settingsStore.videoPlaybackMode
                )
            }

            // UI Overlay Layer
            if showControls {
                VStack {
                    HStack {
                        Spacer()
                        SlideshowControlButton(systemImage: "xmark", title: "Close", action: onDismiss)
                    }
                    .padding(.top)
                    .padding(.horizontal)

                    Spacer()

                    HStack(alignment: .bottom) {
                        SlideshowControlButton(
                            systemImage: viewModel.isPaused ? "play.fill" : "pause.fill",
                            title: viewModel.isPaused ? "Play" : "Pause",
                            action: { viewModel.isPaused ? viewModel.resume() : viewModel.pause() }
                        )

                        Spacer()

                        HStack(alignment: .bottom, spacing: 12) {
                            if let identifier = viewModel.currentAssetIdentifier {
                                SlideshowControlButton(
                                    systemImage: "eye.slash.fill",
                                    title: "Hide",
                                    action: {
                                        settingsStore.hiddenAssetIdentifiers.insert(identifier)
                                        viewModel.skipCurrent()
                                    }
                                )
                            }

                            SlideshowControlButton(
                                systemImage: "moon.zzz.fill",
                                title: "Sleep",
                                action: onEnterManualStandby
                            )
                        }
                    }
                    .padding()
                }
            }

            if let presenceErrorMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                        Text(presenceErrorMessage)
                            .multilineTextAlignment(.leading)
                        #if os(iOS)
                        Button("Open Settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(url)
                        }
                        .buttonStyle(.bordered)
                        #endif
                    }
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
            }

            if isStandby {
                StandbyView(
                    isManualStandby: isManualStandby,
                    onResume: onResumeFromStandby
                )
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onTapGesture {
            withAnimation {
                showControls = true
            }
            hideControlsAfterDelay()
        }
        .onAppear {
            viewModel.start()
            hideControlsAfterDelay()
        }
        .onHover { isHovering in
            isPointerHovering = isHovering
            if isHovering {
                showControls = true
            } else {
                hideControlsAfterDelay()
            }
        }
        .onChange(of: isStandby) { _, isInStandby in
            if isInStandby {
                showControls = false
            } else {
                showControls = true
                hideControlsAfterDelay()
            }
        }
    }

    private func hideControlsAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if showControls && !isPointerHovering {
                withAnimation {
                    showControls = false
                }
            }
        }
    }

}

private struct SlideshowControlButton: View {
    let systemImage: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(.white.opacity(0.18), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    }

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(width: 72)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct StandbyView: View {
    var isManualStandby: Bool
    var onResume: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Button(action: onResume) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 96, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: 180, height: 180)
                    .background(.white.opacity(0.12), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tap the standby icon to resume the slideshow")

            Text(isManualStandby ? "Slideshow paused" : "FrameFlow is resting")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text(
                isManualStandby
                    ? "Tap the standby icon to start the slideshow again."
                    : "Move in front of your device to resume the slideshow."
            )
                .font(.body)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .ignoresSafeArea()
    }

}

struct PhotoDisplayView: View {
    let assetIdentifier: String
    let displayMode: SettingsStore.DisplayMode
    let showMetadata: Bool
    let videoPlaybackMode: SettingsStore.VideoPlaybackMode

    #if os(iOS)
    @State private var displayedImage: UIImage?
    #else
    @State private var displayedImage: NSImage?
    #endif
    @State private var metadataText: String?
    @State private var player: AVPlayer?
    var body: some View {
        ZStack {
            Color.black

            Group {
                if let player {
                    VideoPlayer(player: player)
                        .onAppear { player.play() }
                        .onDisappear { player.pause() }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let image = displayedImage {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    #endif
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }

            VStack {
                Spacer()
                if showMetadata, let metadataText {
                    Text(metadataText)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.65), in: Capsule())
                        .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: assetIdentifier) { _, _ in
            metadataText = nil
            player = nil
            loadImage()
        }
        .onChange(of: videoPlaybackMode) { _, mode in
            player?.isMuted = mode == .muted
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func loadImage() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", assetIdentifier)
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)

        if let asset = fetchResult.firstObject {
            if showMetadata {
                loadMetadata(for: asset)
            }
            if asset.mediaType == .video {
                loadVideo(for: asset)
                return
            }
            let manager = PHImageManager.default()
            #if os(iOS)
            let targetSize = UIScreen.main.bounds.size
            #else
            let targetSize = NSScreen.main?.frame.size ?? CGSize(width: 1200, height: 800)
            #endif
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .opportunistic
            requestOptions.resizeMode = .fast
            requestOptions.isNetworkAccessAllowed = true

            manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
                DispatchQueue.main.async {
                    self.displayedImage = image
                }
            }
        }
    }

    private func loadVideo(for asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let avAsset else { return }
            DispatchQueue.main.async {
                let newPlayer = AVPlayer(playerItem: AVPlayerItem(asset: avAsset))
                newPlayer.isMuted = videoPlaybackMode == .muted
                player = newPlayer
                newPlayer.play()
            }
        }
    }

    private func loadMetadata(for asset: PHAsset) {
        var values: [String] = []

        if let creationDate = asset.creationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            values.append(formatter.string(from: creationDate))
        }

        if let location = asset.location {
            let fallback = String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
            values.append(fallback)
            metadataText = values.joined(separator: " • ")

            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                let place = placemarks?.first
                let locationName = [place?.locality, place?.administrativeArea, place?.country]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                guard !locationName.isEmpty else { return }
                DispatchQueue.main.async {
                    guard self.showMetadata else { return }
                    var updatedValues = values
                    updatedValues[updatedValues.count - 1] = locationName
                    self.metadataText = updatedValues.joined(separator: " • ")
                }
            }
        } else if !values.isEmpty {
            metadataText = values.joined(separator: " • ")
        }
    }
}