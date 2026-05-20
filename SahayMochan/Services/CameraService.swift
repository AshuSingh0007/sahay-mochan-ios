import AVFoundation
import Combine
import Combine
import SwiftUI

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
