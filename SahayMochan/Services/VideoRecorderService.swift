import AVFoundation
import Combine
import Foundation

final class VideoRecorderService: NSObject, ObservableObject {
    enum RecorderError: LocalizedError {
        case cameraUnavailable
        case microphoneUnavailable
        case permissionDenied
        case sessionNotConfigured
        case recordingFailed(String)

        var errorDescription: String? {
            switch self {
            case .cameraUnavailable: return "Camera is not available on this device."
            case .microphoneUnavailable: return "Microphone is not available on this device."
            case .permissionDenied: return "Camera or microphone permission was denied."
            case .sessionNotConfigured: return "Video recorder session is not configured."
            case .recordingFailed(let message): return message
            }
        }
    }

    @Published private(set) var isRecording = false
    @Published private(set) var lastRecordedURL: URL?
    @Published private(set) var errorMessage: String?

    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var completion: ((Result<URL, Error>) -> Void)?
    private var configured = false

    func requestPermissions() async -> Bool {
        let video = await AVCaptureDevice.requestAccess(for: .video)
        let audio = await AVCaptureDevice.requestAccess(for: .audio)
        return video && audio
    }

    func configureSession() throws {
        guard !configured else { return }
        session.beginConfiguration()
        session.sessionPreset = .high
        defer { session.commitConfiguration() }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { throw RecorderError.cameraUnavailable }
        guard let microphone = AVCaptureDevice.default(for: .audio) else { throw RecorderError.microphoneUnavailable }
        let cameraInput = try AVCaptureDeviceInput(device: camera)
        let microphoneInput = try AVCaptureDeviceInput(device: microphone)

        guard session.canAddInput(cameraInput), session.canAddInput(microphoneInput), session.canAddOutput(movieOutput) else {
            throw RecorderError.sessionNotConfigured
        }
        session.addInput(cameraInput)
        session.addInput(microphoneInput)
        session.addOutput(movieOutput)
        configured = true
    }

    func startSession() {
        guard configured, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { self.session.stopRunning() }
    }

    func startRecording() throws {
        guard configured else { throw RecorderError.sessionNotConfigured }
        guard !movieOutput.isRecording else { return }
        let url = Self.newTemporaryVideoURL()
        if let connection = movieOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        movieOutput.startRecording(to: url, recordingDelegate: self)
        isRecording = true
        errorMessage = nil
    }

    func stopRecording() async throws -> URL {
        guard movieOutput.isRecording else {
            if let lastRecordedURL { return lastRecordedURL }
            throw RecorderError.recordingFailed("No active recording was found.")
        }
        return try await withCheckedThrowingContinuation { continuation in
            completion = { continuation.resume(with: $0) }
            movieOutput.stopRecording()
        }
    }

    static func newTemporaryVideoURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("assessment-\(UUID().uuidString).mp4")
    }
}

extension VideoRecorderService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            if let error {
                self.errorMessage = error.localizedDescription
                self.completion?(.failure(error))
            } else {
                self.lastRecordedURL = outputFileURL
                self.completion?(.success(outputFileURL))
            }
            self.completion = nil
        }
    }
}
