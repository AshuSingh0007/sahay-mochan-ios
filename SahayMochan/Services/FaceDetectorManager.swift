import Foundation
import MLKitFaceDetection
import UIKit
import MLKitVision

final class FaceDetectorManager {
    static let shared = FaceDetectorManager()
    
    let detector: FaceDetector
    
    private init() {
        let options = FaceDetectorOptions()
        options.performanceMode = .fast
        options.landmarkMode = .all
        options.contourMode = .all
        options.classificationMode = .all
        options.minFaceSize = 0.15
        detector = FaceDetector.faceDetector(options: options)
    }
    
    func process(_ image: VisionImage, completion: @escaping ([Face]?, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let faces = try self.detector.results(in: image)
                DispatchQueue.main.async {
                    completion(faces, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
}
