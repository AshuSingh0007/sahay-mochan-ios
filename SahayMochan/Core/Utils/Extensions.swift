import Foundation
import SwiftUI

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension FileManager {
    var sahayMochanDirectory: URL {
        let directory = urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("SahayMochan", isDirectory: true)
        if !fileExists(atPath: directory.path) { try? createDirectory(at: directory, withIntermediateDirectories: true) }
        return directory
    }

    func writeCSV(named name: String, rows: [[String]]) throws -> URL {
        let url = sahayMochanDirectory.appendingPathComponent(name)
        let body = rows.map { row in row.map { $0.replacingOccurrences(of: "\"", with: "\"\"") }.map { "\"\($0)\"" }.joined(separator: ",") }.joined(separator: "\n")
        try body.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
}

extension Double {
    var percentText: String { "\(Int((self * 100).rounded()))%" }
}
