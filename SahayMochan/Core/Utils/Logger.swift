import Foundation
import os

enum AppLogger {
    private static let logger = Logger(subsystem: "SahayMochan", category: "App")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
