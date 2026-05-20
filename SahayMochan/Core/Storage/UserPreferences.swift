import Foundation

final class UserPreferences {
    static let shared = UserPreferences()
    private let defaults = UserDefaults.standard
    private let userKey = "current_user"

    var currentUser: User? {
        get {
            guard let data = defaults.data(forKey: userKey) else { return nil }
            return try? JSONDecoder().decode(User.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: userKey)
            } else {
                defaults.removeObject(forKey: userKey)
            }
        }
    }

    func clearSession() {
        currentUser = nil
        KeychainManager.shared.token = nil
    }
}
