import AVFoundation
import Combine
import Foundation
import UIKit

final class VideoRecorderService: NSObject, ObservableObject {
    enum RecorderError: LocalizedError {
        case cameraUnavailable
        case permissionDenied
        case sessionNotConfigured
        case assetWriterCreationFailed
        case assetWriterStartFailed
        case noValidFrames
        case recordingFailed(String)
        case fileNotSaved

        var errorDescription: String? {
            switch self {
            case .cameraUnavailable: return "Camera is not available on this device."
            case .permissionDenied: return "Camera permission was denied."
            case .sessionNotConfigured: return "Video recorder session is not configured."
            case .assetWriterCreationFailed: return "Could not create video writer."
            case .assetWriterStartFailed: return "Could not start video writer."
            case .noValidFrames: return "No video frames were captured."
            case .recordingFailed(let message): return message
            case .fileNotSaved: return "Video file was not saved to disk."
            }
        }
    }

    @Published private(set) var isRecording = false
    @Published private(set) var lastRecordedURL: URL?
    @Published private(set) var errorMessage: String?

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.sahaymochan.video-session", qos: .userInitiated)
    private let recordingQueue = DispatchQueue(label: "com.sahaymochan.video-recording", qos: .userInitiated)
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var startTime: CMTime?
    private var completion: ((Result<URL, Error>) -> Void)?
    private var configured = false
    var frameHandler: ((CMSampleBuffer) -> Void)?

    func requestPermissions() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    func configureSession() throws {
        guard !configured else { return }

        let videoDir = FileManager.default.sahayMochanDirectory.appendingPathComponent("Videos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: videoDir.path) {
            try FileManager.default.createDirectory(at: videoDir, withIntermediateDirectories: true)
            print("📁 Created video directory at: \(videoDir)")
        }

        session.beginConfiguration()
        session.sessionPreset = .medium
        defer { session.commitConfiguration() }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw RecorderError.cameraUnavailable
        }
        let cameraInput = try AVCaptureDeviceInput(device: camera)

        guard session.canAddInput(cameraInput), session.canAddOutput(videoOutput) else {
            throw RecorderError.sessionNotConfigured
        }
        session.addInput(cameraInput)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: recordingQueue)
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            configure(connection: connection)
        }

        configured = true
        print("✅ VideoRecorderService configured (AssetWriter mode)")
    }

    func startSession() {
        guard configured, !session.isRunning else { return }
        sessionQueue.async {
            self.session.startRunning()
            print("🎥 Camera session started")
        }
    }

    func stopSession() {
        guard session.isRunning else { return }
        sessionQueue.async {
            self.session.stopRunning()
            print("🎥 Camera session stopped")
        }
    }

    func startRecording() throws {
        guard configured else { throw RecorderError.sessionNotConfigured }
        guard !isRecording else { return }

        let outputURL = try Self.newDocumentsVideoURL()
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            throw RecorderError.assetWriterCreationFailed
        }

        // Portrait dimensions – width 720, height 1280
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 720,
            AVVideoHeightKey: 1280
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = true

        // ✅ No transform – rely on connection's rotation (videoRotationAngle = 90.0)
        writerInput.transform = .identity

        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput,
                                                           sourcePixelBufferAttributes: pixelBufferAttributes)

        if assetWriter.canAdd(writerInput) {
            assetWriter.add(writerInput)
        } else {
            throw RecorderError.assetWriterCreationFailed
        }

        self.assetWriter = assetWriter
        self.videoInput = writerInput
        self.pixelBufferAdaptor = adaptor
        self.startTime = nil

        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        isRecording = true
        errorMessage = nil
        print("🔴 Recording started (AssetWriter), will write to \(outputURL.lastPathComponent)")
    }

    func stopRecording() async throws -> URL {
        guard isRecording else {
            if let lastURL = lastRecordedURL, FileManager.default.fileExists(atPath: lastURL.path) {
                print("⚠️ stopRecording called but no active recording – returning lastRecordedURL: \(lastURL)")
                return lastURL
            }
            throw RecorderError.recordingFailed("No active recording was found.")
        }
        return try await withCheckedThrowingContinuation { continuation in
            completion = { continuation.resume(with: $0) }
            self.videoInput?.markAsFinished()
            self.assetWriter?.finishWriting { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isRecording = false
                    if let error = self.assetWriter?.error {
                        print("❌ Recording finished with writer error: \(error)")
                        self.completion?(.failure(error))
                    } else if let url = self.assetWriter?.outputURL,
                              FileManager.default.fileExists(atPath: url.path),
                              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                              let fileSize = attrs[.size] as? Int, fileSize > 0 {
                        self.lastRecordedURL = url
                        print("✅ Recording saved successfully: \(url.path) (size: \(fileSize) bytes)")
                        self.completion?(.success(url))
                    } else {
                        print("❌ Recording finished but file is missing or empty!")
                        self.completion?(.failure(RecorderError.fileNotSaved))
                    }
                    self.completion = nil
                    self.assetWriter = nil
                    self.videoInput = nil
                    self.pixelBufferAdaptor = nil
                    self.startTime = nil
                }
            }
            print("⏹️ stopRecording requested")
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

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension VideoRecorderService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameHandler?(sampleBuffer)

        guard isRecording, let assetWriter = assetWriter, let videoInput = videoInput, videoInput.isReadyForMoreMediaData else {
            return
        }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if startTime == nil {
            startTime = timestamp
            assetWriter.startSession(atSourceTime: timestamp)
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if pixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: timestamp) == false {
            print("⚠️ Failed to append pixel buffer at time \(timestamp.seconds)")
        }
    }
}
