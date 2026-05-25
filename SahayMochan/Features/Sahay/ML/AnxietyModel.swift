import Foundation
#if canImport(TensorFlowLite)
import TensorFlowLite
#endif

final class AnxietyModel {
    private let modelName = "new_hybrid_anxiety_model"
    private var actualSpec: ModelTensorSpec?

    func predict(questionnaireScore: Int, auFrames: [AUFrame]) -> Double {
        do {
            let rawOutput = try runModel(questionnaireScore: questionnaireScore, auFrames: auFrames)
            return scale(rawOutput: rawOutput, maximumScore: 21)
        } catch {
            print("AnxietyModel inference failed: \(error.localizedDescription). Using fallback.")
            return fallbackPrediction(questionnaireScore: questionnaireScore, auFrames: auFrames, maximumScore: 21)
        }
    }

    private func scale(rawOutput: Float32, maximumScore: Double) -> Double {
        guard rawOutput.isFinite else { return 0 }
        let value = Double(rawOutput)

        if value >= 0, value <= 1 {
            return min(maximumScore, max(0, value * maximumScore))
        }

        return min(maximumScore, max(0, value))
    }

    private func modelURL() throws -> URL {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "tflite"),
              FileManager.default.fileExists(atPath: url.path) else {
            throw ModelInferenceError.modelNotFound("\(modelName).tflite")
        }
        return url
    }

    private func fallbackPrediction(questionnaireScore: Int, auFrames: [AUFrame], maximumScore: Double) -> Double {
        guard !auFrames.isEmpty else {
            return min(maximumScore, max(0, Double(questionnaireScore)))
        }

        let values = auFrames.flatMap(\.values).filter { $0.isFinite }
        guard !values.isEmpty else {
            return min(maximumScore, max(0, Double(questionnaireScore)))
        }

        let mean = values.reduce(Float(0), +) / Float(values.count)
        let normalizedMean = min(1, max(0, Double(mean)))
        let expressionScore = normalizedMean * maximumScore
        return min(maximumScore, max(0, Double(questionnaireScore) * 0.7 + expressionScore * 0.3))
    }

    #if canImport(TensorFlowLite)
    private func runModel(questionnaireScore: Int, auFrames: [AUFrame]) throws -> Float32 {
        let modelPath = try modelURL().path
        let interpreter = try makeInterpreter(modelPath: modelPath)
        try interpreter.allocateTensors()

        guard interpreter.inputTensorCount > 0 else {
            throw ModelInferenceError.invalidTensorShape("Model has no input tensors.")
        }
        guard interpreter.outputTensorCount > 0 else {
            throw ModelInferenceError.invalidTensorShape("Model has no output tensors.")
        }

        let inputTensor = try interpreter.input(at: 0)
        guard inputTensor.dataType == .float32 else {
            throw ModelInferenceError.unsupportedTensorType("Expected Float32 input tensor, got \(inputTensor.dataType).")
        }

        let inputSpec = try sequenceSpec(from: inputTensor.shape.dimensions)

        let inputValues = try AUSequencePreprocessor.input(
            frames: auFrames,
            targetLength: inputSpec.sequenceLength,
            featureCount: inputSpec.featureCount
        )
        try interpreter.copy(inputValues.tensorData(), toInputAt: 0)
        try copyAdditionalInputs(questionnaireScore: questionnaireScore, interpreter: interpreter)
        try interpreter.invoke()

        let output = try interpreter.output(at: 0)
        guard output.dataType == .float32 else {
            throw ModelInferenceError.unsupportedTensorType("Expected Float32 output tensor, got \(output.dataType).")
        }
        actualSpec = ModelTensorSpec(
            sequenceLength: inputSpec.sequenceLength,
            featureCount: inputSpec.featureCount,
            outputCount: max(output.shape.dimensions.reduce(1, *), 1)
        )
        return try firstFloat(from: output.data)
    }

    private func makeInterpreter(modelPath: String) throws -> Interpreter {
        var options = Interpreter.Options()
        options.threadCount = 1

        do {
            return try Interpreter(modelPath: modelPath, options: options)
        } catch {
            print("AnxietyModel interpreter creation failed with options for path \(modelPath): \(error)")
            return try Interpreter(modelPath: modelPath)
        }
    }

    private func sequenceSpec(from dimensions: [Int]) throws -> (sequenceLength: Int, featureCount: Int) {
        if dimensions.count == 3 {
            guard dimensions[0] == 1 || dimensions[0] == -1 else {
                throw ModelInferenceError.invalidTensorShape("Expected batch size 1 for rank-3 input, got \(dimensions).")
            }
            return (dimensions[1], dimensions[2])
        }

        if dimensions.count == 2 {
            return (dimensions[0], dimensions[1])
        }

        throw ModelInferenceError.invalidTensorShape("Expected rank-2 or rank-3 AU input tensor, got \(dimensions).")
    }

    private func copyAdditionalInputs(questionnaireScore: Int, interpreter: Interpreter) throws {
        guard interpreter.inputTensorCount > 1 else { return }

        for inputIndex in 1..<interpreter.inputTensorCount {
            let tensor = try interpreter.input(at: inputIndex)
            guard tensor.dataType == .float32 else { continue }

            let elementCount = max(tensor.shape.dimensions.reduce(1, *), 1)
            var values = Array(repeating: Float32(0), count: elementCount)
            values[0] = Float32(min(1, max(0, Double(questionnaireScore) / 21.0)))
            try interpreter.copy(values.tensorData(), toInputAt: inputIndex)
        }
    }

    private func firstFloat(from data: Data) throws -> Float32 {
        guard data.count >= MemoryLayout<Float32>.size else {
            throw ModelInferenceError.invalidTensorShape("Output tensor is empty.")
        }

        return data.withUnsafeBytes { rawBuffer in
            rawBuffer.bindMemory(to: Float32.self)[0]
        }
    }
    #else
    private func runModel(questionnaireScore: Int, auFrames: [AUFrame]) throws -> Float32 {
        _ = questionnaireScore
        _ = auFrames
        _ = try modelURL()
        throw ModelInferenceError.runtimeUnavailable("TensorFlowLiteSwift is not available in this build.")
    }
    #endif
}
