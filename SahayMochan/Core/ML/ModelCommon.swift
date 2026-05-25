import Foundation

struct AUFrame: Codable, Identifiable, Equatable, Sendable {
    static let featureCount = 19

    var id: UUID
    let timestamp: TimeInterval
    let values: [Float]

    init(id: UUID = UUID(), timestamp: TimeInterval, values: [Float]) {
        self.id = id
        self.timestamp = timestamp
        self.values = Self.normalizedFeatureVector(values)
    }

    enum CodingKeys: String, CodingKey {
        case id, timestamp, values
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        values = Self.normalizedFeatureVector(try container.decode([Float].self, forKey: .values))
    }

    private static func normalizedFeatureVector(_ source: [Float]) -> [Float] {
        var output = Array(source.prefix(featureCount))
        if output.count < featureCount {
            output.append(contentsOf: Array(repeating: 0, count: featureCount - output.count))
        }
        return output.map { value in
            guard value.isFinite else { return 0 }
            return min(1, max(-1, value))
        }
    }
}

struct ModelTensorSpec: Equatable {
    let sequenceLength: Int
    let featureCount: Int
    let outputCount: Int
}

enum ModelInferenceError: LocalizedError {
    case emptyInput
    case modelNotFound(String)
    case invalidTensorShape(String)
    case unsupportedTensorType(String)
    case runtimeUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "No action-unit frames are available for model inference."
        case .modelNotFound(let name):
            return "Model file not found: \(name)."
        case .invalidTensorShape(let message):
            return message
        case .unsupportedTensorType(let message):
            return message
        case .runtimeUnavailable(let message):
            return message
        }
    }
}

enum AUSequencePreprocessor {
    static func input(frames: [AUFrame], targetLength: Int, featureCount: Int) throws -> [Float32] {
        guard !frames.isEmpty else { throw ModelInferenceError.emptyInput }
        guard targetLength > 0, featureCount > 0 else {
            throw ModelInferenceError.invalidTensorShape("Invalid input tensor dimensions: sequence=\(targetLength), features=\(featureCount).")
        }

        let orderedFrames = frames.sorted { $0.timestamp < $1.timestamp }
        let selectedFrames: [AUFrame]

        if orderedFrames.count >= targetLength {
            selectedFrames = Array(orderedFrames.suffix(targetLength))
        } else {
            let paddingFrame = orderedFrames.last ?? AUFrame(timestamp: 0, values: [])
            selectedFrames = orderedFrames + Array(repeating: paddingFrame, count: targetLength - orderedFrames.count)
        }

        var values = [Float32]()
        values.reserveCapacity(targetLength * featureCount)

        for frame in selectedFrames {
            for index in 0..<featureCount {
                let rawValue = index < frame.values.count ? frame.values[index] : 0
                values.append(normalized(rawValue))
            }
        }

        return values
    }

    private static func normalized(_ value: Float) -> Float32 {
        guard value.isFinite else { return 0 }

        if value >= -1, value <= 1 {
            return Float32((value + 1) / 2)
        }

        if value >= 0, value <= 100 {
            return Float32(min(1, max(0, value / 100)))
        }

        return Float32(min(1, max(0, value)))
    }
}

extension Array where Element == Float32 {
    func tensorData() -> Data {
        withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }
}
