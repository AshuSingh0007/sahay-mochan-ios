import CoreGraphics
import Foundation
import QuartzCore
import UIKit
#if canImport(MLKitFaceDetection) && canImport(MLKitVision)
import MLKitFaceDetection
import MLKitVision
#endif

final class FaceLandmarkerService {
    private let targetFrameInterval: TimeInterval = 1.0 / 12.0
    private var lastFrameTime: TimeInterval = 0

    static func sampleFrames() -> [AUFrame] {
        (0..<40).map { index in
            let base = Float(index % 10) / 10.0
            let values = AUFeatureSet.canonicalFeatures.indices.map { feature in
                min(1, max(0, base * 0.45 + Float(feature % 7) * 0.055))
            }
            return AUFrame(timestamp: Double(index) / 12.0, values: values)
        }
    }

    #if canImport(MLKitFaceDetection) && canImport(MLKitVision)
    
    // ✅ Use Singleton pattern to avoid multiple instances
    private var detector: FaceDetector {
        return FaceDetectorManager.shared.detector
    }

    func extractActionUnits(from image: UIImage, timestamp: TimeInterval = CACurrentMediaTime()) async throws -> AUFrame? {
        guard timestamp - lastFrameTime >= targetFrameInterval else { return nil }
        lastFrameTime = timestamp
        
        // ✅ Run MLKit on background thread
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let visionImage = VisionImage(image: image)
                visionImage.orientation = image.imageOrientation
                
                do {
                    let faces = try self.detector.results(in: visionImage)
                    guard let face = faces.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) else {
                        continuation.resume(returning: nil)
                        return
                    }
                    let auFrame = AUFrame(timestamp: timestamp, values: Self.actionUnits(from: face))
                    continuation.resume(returning: auFrame)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func actionUnits(from face: Face) -> [Float] {
        let frame = face.frame
        let width = max(frame.width, 1)
        let height = max(frame.height, 1)
        let leftEyeOpen = Float(face.leftEyeOpenProbability >= 0 ? face.leftEyeOpenProbability : 0.5)
        let rightEyeOpen = Float(face.rightEyeOpenProbability >= 0 ? face.rightEyeOpenProbability : 0.5)
        let smile = Float(face.smilingProbability >= 0 ? face.smilingProbability : 0)
        let roll = Float(face.headEulerAngleZ / 45.0)
        let yaw = Float(face.headEulerAngleY / 45.0)

        // Convert VisionPoint to CGPoint using direct properties
        let leftEye = center(points: face.contour(ofType: .leftEye)?.points.map { CGPoint(x: $0.x, y: $0.y) } ?? [])
        let rightEye = center(points: face.contour(ofType: .rightEye)?.points.map { CGPoint(x: $0.x, y: $0.y) } ?? [])
        let upperLip = center(points: face.contour(ofType: .upperLipTop)?.points.map { CGPoint(x: $0.x, y: $0.y) } ?? [])
        let lowerLip = center(points: face.contour(ofType: .lowerLipBottom)?.points.map { CGPoint(x: $0.x, y: $0.y) } ?? [])
        
        // Convert nose landmark position correctly
        let nosePoint: CGPoint
        if let noseLandmark = face.landmark(ofType: .noseBase)?.position {
            nosePoint = CGPoint(x: noseLandmark.x, y: noseLandmark.y)
        } else {
            nosePoint = CGPoint(x: frame.midX, y: frame.midY)
        }
        
        let mouthGap = Float(abs(lowerLip.y - upperLip.y) / height)
        let eyeDistance = Float(abs(rightEye.x - leftEye.x) / width)
        let browLift = Float(max(0, (nosePoint.y - min(leftEye.y, rightEye.y)) / height))
        let blink = 1 - ((leftEyeOpen + rightEyeOpen) / 2)

        let au01 = clamp(browLift)
        let au02 = clamp(browLift * 0.8 + max(0, yaw) * 0.1)
        let au04 = clamp(1 - browLift)
        let au05 = clamp((leftEyeOpen + rightEyeOpen) / 2)
        let au06 = clamp(smile * 0.65 + (1 - blink) * 0.2)
        let au07 = clamp(blink * 0.7)
        let au09 = clamp(abs(Float(nosePoint.x - frame.midX) / Float(width)))
        let au10 = clamp(Float(max(0, frame.midY - upperLip.y) / height))
        let au12 = clamp(smile)
        let au14 = clamp(smile * 0.6 + eyeDistance * 0.25)
        let au15 = clamp((1 - smile) * mouthGap)
        let au17 = clamp(Float(max(0, lowerLip.y - frame.midY) / height))
        let au20 = clamp(mouthGap * 1.6)
        let au23 = clamp((1 - mouthGap) * (1 - smile))
        let au25 = clamp(mouthGap)
        let au26 = clamp(mouthGap * 1.25)
        let au45 = clamp(blink)
        let gazeX = clampSigned(yaw)
        let gazeY = clampSigned(roll)
        
        return [au01, au02, au04, au05, au06, au07, au09, au10, au12, au14, au15, au17, au20, au23, au25, au26, au45, gazeX, gazeY]
    }
    #else
    func extractActionUnits(from image: UIImage, timestamp: TimeInterval = CACurrentMediaTime()) async throws -> AUFrame? {
        guard timestamp - lastFrameTime >= targetFrameInterval else { return nil }
        lastFrameTime = timestamp
        return Self.sampleFrames().first
    }
    #endif

    func extractActionUnits() async -> [AUFrame] {
        Self.sampleFrames()
    }

    private static func center(points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }

    private static func clamp(_ value: Float) -> Float {
        min(1, max(0, value))
    }

    private static func clampSigned(_ value: Float) -> Float {
        min(1, max(-1, value))
    }
}
