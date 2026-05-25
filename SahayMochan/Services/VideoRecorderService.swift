import AVFoundation
import Combine
import Foundation
import UIKit

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
            case .permissionDenied: return "Camera permission was denied."
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
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.sahaymochan.video-session", qos: .userInitiated)
    private let frameQueue = DispatchQueue(label: "com.sahaymochan.video-frames", qos: .userInitiated)
    private var completion: ((Result<URL, Error>) -> Void)?
    private var configured = false
    var frameHandler: ((CMSampleBuffer) -> Void)?

    func requestPermissions() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    func configureSession() throws {
        guard !configured else { return }
        session.beginConfiguration()
        session.sessionPreset = .medium
        defer { session.commitConfiguration() }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { throw RecorderError.cameraUnavailable }
        let cameraInput = try AVCaptureDeviceInput(device: camera)

        guard session.canAddInput(cameraInput), session.canAddOutput(movieOutput), session.canAddOutput(videoOutput) else {
            throw RecorderError.sessionNotConfigured
        }
        session.addInput(cameraInput)
        session.addOutput(movieOutput)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: frameQueue)
        session.addOutput(videoOutput)

        if let movieConnection = movieOutput.connection(with: .video) {
            configure(connection: movieConnection)
        }
        if let frameConnection = videoOutput.connection(with: .video) {
            configure(connection: frameConnection)
        }

        configured = true
    }

    func startSession() {
        guard configured, !session.isRunning else { return }
        sessionQueue.async { self.session.startRunning() }
    }

    func stopSession() {
        guard session.isRunning else { return }
        sessionQueue.async { self.session.stopRunning() }
    }

    func startRecording() throws {
        guard configured else { throw RecorderError.sessionNotConfigured }
        guard !movieOutput.isRecording else { return }
        let url = try Self.newDocumentsVideoURL()
        if let connection = movieOutput.connection(with: .video) { configure(connection: connection) }
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

    static func newDocumentsVideoURL() throws -> URL {
        let directory = FileManager.default.sahayMochanDirectory.appendingPathComponent("Videos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent("assessment-\(UUID().uuidString).mp4")
    }

    private func configure(connection: AVCaptureConnection) {
        if connection.isVideoOrientationSupported {
            // ✅ iOS 17+ compatibility
            if #available(iOS 17.0, *) {
                connection.videoRotationAngle = 90.0
            } else {
                connection.videoOrientation = .portrait
            }
        }
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }
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

extension VideoRecorderService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // ✅ Pass frame to handler on background thread
        frameHandler?(sampleBuffer)
    }
}
