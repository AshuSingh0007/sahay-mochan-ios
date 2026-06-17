import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window?.enableScreenshotProtection()
        return true
    }
}

private extension UIWindow {
    func enableScreenshotProtection() {
        let secureTextField = UITextField(frame: bounds)
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.backgroundColor = .clear

        guard let secureView = secureTextField.subviews.first else { return }
        secureView.frame = bounds
        secureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(secureTextField)
        secureTextField.addSubview(secureView)
        sendSubviewToBack(secureTextField)
    }
}
