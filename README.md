"# Photo Frame App

## Project Overview
**Project:** Private Random Photo Frame for iPad/macOS
**Goal:** A native, privacy-first digital photo frame that displays photos in a randomized order.

---

## 1. Requirements Summary

### Primary Goal
- Access photos via Apple's PhotoKit.
- Select an existing Photos album.
- Display photos in a full-screen slideshow.
- Randomized/shuffled order with no repeats within a cycle.
- Automatic restart of cycles.
- Designed for permanent placement (iPad/Mac).

### Privacy (Fundamental Requirement)
- **No uploads:** Never upload photos or metadata.
- **No registration/accounts:** No user accounts or cloud services required.
- **No ads/tracking/analytics:** Zero external telemetry or advertising.
- **Local only:** All settings and data stored locally on the device.

### Technical Requirements
- **Platform:** iPadOS 17.7+ and macOS (Multiplatform SwiftUI).
- **Photo Integration:** Use PhotoKit to handle permissions, album enumeration, and asset retrieval.
- **Randomization Algorithm:** Shuffle logic to ensure full coverage of the album before repeats.
- **Display Mode:** Support for 'Fit' and 'Fill' aspect ratios.
- **Lifecycle Management:** Handle background/foreground transitions gracefully.
- **Presence-based standby (iPad):** After a configurable period without a person in view (15 minutes by default), show a black standby screen with the app logo. Resume the slideshow when a person is detected. Detection uses the front camera on-device; camera images are not saved or sent anywhere.

---

## 2. Proposed Architecture (MVVM)

### Layers
- **View Layer (SwiftUI):** `AlbumSelectionView`, `SlideshowView`, `SettingsView`, `RootView`.
- **ViewModel Layer:** 
    - `AlbumSelectionViewModel`: Man-manages album fetching and selection.
    - `SlideshowViewModel`: Handles the timer, shuffle logic triggers, and current asset state.
    - `SettingsStore`: Centralized `ObservableObject` for local persistence via `UserDefaults`.
- **Service/Logic Layer:**
    - `PhotoLibraryService`: Wrapper for `PhotoKit` (permissions, asset fetching).
    - `ShuffleManager`: Pure logic for the randomization and cycle algorithm.

---

## 3. Implementation Plan

### Phase 1: Foundation
- [x] Create directory structure.
- [x] Implement `SettingsStore` (Persistence).
- [x] Implement `ShuffleManager` (Core Logic).
- [x] Implement `PhotoLibraryService` (PhotoKit Wrapper).

### Phase 2: Selection & Discovery
- [x] Implement `AlbumSelectionViewModel`.
- [x] Implement `AlbumSelectionView` (UI).

### Phase 3: Slideshow Engine
- [x] Implement `SlideshowViewModel` (Timer, Shuffle Cycle).
- [x] Implement `SlideshowView` (Full-screen Display).

### Phase 4: UI Refinement & Settings
- [x] Implement `SettingsView` (Configuration).
- [x] Implement `RootView` (Navigation/Lifecycle).

### Phase 5: Testing & Validation
- [x] Implement `ShuffleManagerTests` (Unit Tests).
- [ ] Perform manual testing on iPad and macOS.

---

## 4. How to Build and Install
1. Open `FrameFlow Digital Photo Frame.xcodeproj` in Xcode.
2. Select the `FrameFlow Digital Photo Frame` scheme and a supported iPad or Mac destination.
3. Build and run the app.
5. Build and run on iPad or Mac.

On iPad, **Automatic Sleep** is off by default. Enable it in Settings to allow FrameFlow to request camera access when the slideshow starts, then choose the standby delay. Camera images are processed on-device and are not saved or sent anywhere. While presence detection is active, the iPad stays awake so it can resume when someone returns.

The in-app **Documentation** option in Settings describes the features, privacy behavior, and supported operating-system versions.
"