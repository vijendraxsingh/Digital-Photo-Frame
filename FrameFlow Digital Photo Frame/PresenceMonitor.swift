#if os(iOS)
@preconcurrency import AVFoundation
import Combine
import Vision

@MainActor
final class PresenceMonitor: NSObject, ObservableObject {
    @Published private(set) var isPersonPresent: Bool?
    @Published private(set) var errorMessage: String?

    nonisolated(unsafe) private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "FrameFlow.PresenceMonitor.Session")
    private let videoQueue = DispatchQueue(label: "FrameFlow.PresenceMonitor.Video")
    nonisolated(unsafe) private let videoOutput = AVCaptureVideoDataOutput()
    private var isRequested = false
    nonisolated(unsafe) private var isConfigured = false
    nonisolated(unsafe) private var lastDetectionTime: TimeInterval = 0

    func start() {
        guard !isRequested else { return }
        isRequested = true
        errorMessage = nil

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self, self.isRequested else { return }
                    if granted {
                        self.startSession()
                    } else {
                        self.errorMessage = "Camera access is needed for presence detection. Allow it in Settings."
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "Camera access is needed for presence detection. Allow it in Settings."
        @unknown default:
            errorMessage = "Camera access is unavailable, so presence detection cannot start."
        }
    }

    func stop() {
        isRequested = false
        isPersonPresent = nil
        errorMessage = nil
        sessionQueue.async { [session, videoOutput] in
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            do {
                if !self.isConfigured {
                    try self.configureSession()
                }
                self.videoOutput.setSampleBufferDelegate(self, queue: self.videoQueue)
                self.session.startRunning()
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Presence detection could not start: \(error.localizedDescription)"
                }
            }
        }
    }

    nonisolated private func configureSession() throws {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw PresenceMonitorError.frontCameraUnavailable
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .low

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw PresenceMonitorError.cannotAddCameraInput
        }
        session.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        guard session.canAddOutput(videoOutput) else {
            throw PresenceMonitorError.cannotAddVideoOutput
        }
        session.addOutput(videoOutput)
        isConfigured = true
    }

    private enum PresenceMonitorError: LocalizedError {
        case frontCameraUnavailable
        case cannotAddCameraInput
        case cannotAddVideoOutput

        var errorDescription: String? {
            switch self {
            case .frontCameraUnavailable:
                return "This device has no front camera."
            case .cannotAddCameraInput:
                return "The front camera could not be opened."
            case .cannotAddVideoOutput:
                return "The camera video stream could not be configured."
            }
        }
    }
}

extension PresenceMonitor: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastDetectionTime >= 0.5 else { return }
        lastDetectionTime = now
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanRectanglesRequest()
        request.upperBodyOnly = true

        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up).perform([request])
            let foundPerson = !(request.results ?? []).isEmpty
            DispatchQueue.main.async { [weak self] in
                self?.isPersonPresent = foundPerson
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Presence detection failed: \(error.localizedDescription)"
            }
        }
    }
}
#else
import Combine

@MainActor
final class PresenceMonitor: ObservableObject {
    @Published private(set) var isPersonPresent: Bool?
    @Published private(set) var errorMessage: String?

    func start() {}
    func stop() {}
}
#endif
