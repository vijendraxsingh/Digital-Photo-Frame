import Combine
import SwiftUI
#if os(iOS)
import UIKit
#endif

/// The top-level view that manages navigation between the Selection and Slideshow modes.
struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var presenceMonitor = PresenceMonitor()
    @State private var isSlideshowActive: Bool = false
    @State private var isStandby = false
    @State private var isManualStandby = false
    @State private var lastPersonSeenAt = Date()
    @State private var isAlbumSelectionActive: Bool = false
    @State private var isHiddenPhotosActive: Bool = false
    @State private var slideshowViewModel: SlideshowViewModel?
    private let idleTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if isSlideshowActive, let slideshowViewModel {
                // We pass the selected album ID to the ViewModel via the RootView's state or directly.
                // In this case, we use the ID from settingsStore.
                SlideshowView(
                    viewModel: slideshowViewModel,
                    settingsStore: settingsStore,
                    onDismiss: {
                        isSlideshowActive = false
                    },
                    isStandby: isStandby,
                    isManualStandby: isManualStandby,
                    presenceErrorMessage: presenceMonitor.errorMessage,
                    onResumeFromStandby: {
                        setStandby(false)
                    },
                    onEnterManualStandby: {
                        setStandby(true, manually: true)
                    }
                )
            } else if isHiddenPhotosActive {
                HiddenPhotosView(settingsStore: settingsStore) {
                    isHiddenPhotosActive = false
                }
            } else if isAlbumSelectionActive {
                AlbumSelectionView(
                    settingsStore: settingsStore,
                    onStartSlideshow: {
                        if settingsStore.selectedAlbumIdentifier != nil || settingsStore.allPhotosSelected {
                            slideshowViewModel = SlideshowViewModel(
                                settingsStore: settingsStore,
                                selectedAlbumIdentifier: settingsStore.selectedAlbumIdentifier
                            )
                            isSlideshowActive = true
                        }
                    },
                    onOpenSettings: {
                        isAlbumSelectionActive = false
                    }
                )
            } else {
                SettingsView(
                    settingsStore: settingsStore,
                    onSelectAlbum: {
                        isAlbumSelectionActive = true
                    },
                    onStartFrameFlow: {
                        if settingsStore.selectedAlbumIdentifier == nil {
                            settingsStore.allPhotosSelected = true
                        }
                        slideshowViewModel = SlideshowViewModel(
                            settingsStore: settingsStore,
                            selectedAlbumIdentifier: settingsStore.selectedAlbumIdentifier
                        )
                        isSlideshowActive = true
                    },
                    onManageHiddenPhotos: {
                        isHiddenPhotosActive = true
                    }
                )
            }
        }
        .onChange(of: isSlideshowActive) { _, _ in
            updatePresenceMonitoring()
        }
        .onChange(of: settingsStore.presenceTimeoutSeconds) { _, _ in
            updatePresenceMonitoring()
        }
        .onChange(of: settingsStore.automaticPresenceSleepEnabled) { _, _ in
            updatePresenceMonitoring()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                updatePresenceMonitoring()
            } else {
                presenceMonitor.stop()
                #if os(iOS)
                UIApplication.shared.isIdleTimerDisabled = false
                #endif
            }
        }
        .onChange(of: presenceMonitor.isPersonPresent) { _, isPresent in
            guard isPresent == true else { return }
            lastPersonSeenAt = Date()
            if !isManualStandby {
                setStandby(false)
            }
        }
        .onChange(of: presenceMonitor.errorMessage) { _, _ in
            updateIdleTimer()
        }
        .onReceive(idleTimer) { now in
            guard isSlideshowActive,
                  settingsStore.automaticPresenceSleepEnabled,
                  settingsStore.presenceTimeoutSeconds > 0,
                  presenceMonitor.errorMessage == nil,
                  presenceMonitor.isPersonPresent == false else { return }
            if now.timeIntervalSince(lastPersonSeenAt) >= settingsStore.presenceTimeoutSeconds {
                setStandby(true)
            }
        }
        .onDisappear {
            presenceMonitor.stop()
            setStandby(false)
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
    }

    private func startSlideshow() {
        if settingsStore.selectedAlbumIdentifier == nil {
            settingsStore.allPhotosSelected = true
        }
        slideshowViewModel = SlideshowViewModel(
            settingsStore: settingsStore,
            selectedAlbumIdentifier: settingsStore.selectedAlbumIdentifier
        )
        isSlideshowActive = true
    }

    private func updatePresenceMonitoring() {
        #if os(iOS)
        guard isSlideshowActive,
              settingsStore.automaticPresenceSleepEnabled,
              settingsStore.presenceTimeoutSeconds > 0 else {
            presenceMonitor.stop()
            setStandby(false)
            updateIdleTimer()
            return
        }

        lastPersonSeenAt = Date()
        presenceMonitor.start()
        updateIdleTimer()
        #endif
    }

    private func updateIdleTimer() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled =
            isSlideshowActive
            && settingsStore.automaticPresenceSleepEnabled
            && settingsStore.presenceTimeoutSeconds > 0
            && presenceMonitor.errorMessage == nil
        #endif
    }

    private func setStandby(_ shouldEnterStandby: Bool, manually: Bool = false) {
        guard isStandby != shouldEnterStandby else { return }
        isStandby = shouldEnterStandby
        if shouldEnterStandby {
            isManualStandby = manually
            slideshowViewModel?.pause()
        } else {
            isManualStandby = false
            lastPersonSeenAt = Date()
            if isSlideshowActive {
                slideshowViewModel?.resume()
            }
        }
    }
}