import AVFoundation
import Combine
import SwiftUI
import UIKit

final class CameraService: NSObject, ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    func requestAccess() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run { authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video) }
        return granted
    }
}

struct CameraPreviewPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(MochanTheme.sageSoft)
            VStack(spacing: 10) {
                Image(systemName: "camera.viewfinder").font(.largeTitle).foregroundColor(MochanTheme.purple)
                Text("Camera assessment area").font(.caption).foregroundColor(MochanTheme.sageDark)
            }
        }
        .frame(height: 220)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
