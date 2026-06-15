import Foundation
#if canImport(TensorFlowLite)
import TensorFlowLite
#endif

final class DepressionModel {
    private let modelName = "best_bilstm_transformer_model"
    private var actualSpec: ModelTensorSpec?

    // MARK: - Public Prediction
    func predict(questionnaireScore: Int, auFrames: [AUFrame]) -> Double {
        do {
            let rawOutput = try runModel(questionnaireScore: questionnaireScore, auFrames: auFrames)
            return scale(rawOutput: rawOutput, maximumScore: 27.0)
        } catch {
            print("⚠️ DepressionModel inference failed: \(error.localizedDescription). Using fallback.")
            return fallbackPrediction(questionnaireScore: questionnaireScore, auFrames: auFrames, maximumScore: 27.0)
        }
    }

    // MARK: - Private Helpers
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
    // MARK: - TensorFlow Lite Inference (synchronous, with timeout)
    private func runModel(questionnaireScore: Int, auFrames: [AUFrame]) throws -> Float32 {
        let modelPath = try modelURL().path
        let interpreter = try createInterpreter(modelPath: modelPath)

        // Allocate tensors
        try interpreter.allocateTensors()
        guard interpreter.inputTensorCount > 0, interpreter.outputTensorCount > 0 else {
            throw ModelInferenceError.invalidTensorShape("Model has no input/output tensors.")
        }

        let inputTensor = try interpreter.input(at: 0)
        guard inputTensor.dataType == .float32 else {
            throw ModelInferenceError.unsupportedTensorType("Expected Float32 input tensor, got \(inputTensor.dataType).")
        }

        // Prepare input sequence
        let inputDims = inputTensor.shape.dimensions
        let (seqLen, featureCount) = try sequenceSpec(from: inputDims)
        // Depression model expects 17 features (AU only, no gaze)
        let framesToUse = auFrames.map { frame in
            AUFrame(timestamp: frame.timestamp, values: Array(frame.values.prefix(17)))
        }
        let inputValues = try AUSequencePreprocessor.input(
            frames: framesToUse,
            targetLength: seqLen,
            featureCount: featureCount
        )
        try interpreter.copy(inputValues.tensorData(), toInputAt: 0)

        // Handle possible additional inputs (questionnaire score)
        if interpreter.inputTensorCount > 1 {
            for idx in 1..<interpreter.inputTensorCount {
                let tensor = try interpreter.input(at: idx)
                if tensor.dataType == .float32 {
                    let count = max(tensor.shape.dimensions.reduce(1, *), 1)
                    var values = Array(repeating: Float32(0), count: count)
                    values[0] = Float32(min(1, max(0, Double(questionnaireScore) / 27.0)))
                    try interpreter.copy(values.tensorData(), toInputAt: idx)
                }
            }
        }

        // Run inference synchronously with a timeout (5 seconds)
        var inferenceError: Error?
        var outputValue: Float32 = 0
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try interpreter.invoke()
                outputValue = try self.readOutput(from: interpreter)
                group.leave()
            } catch {
                inferenceError = error
                group.leave()
            }
        }
        let result = group.wait(timeout: .now() + 5.0)
        if result == .timedOut {
            throw ModelInferenceError.runtimeUnavailable("Inference timed out.")
        }
        if let error = inferenceError {
            throw error
        }
        return outputValue
    }

    private func createInterpreter(modelPath: String) throws -> Interpreter {
        #if canImport(TensorFlowLiteSelectTfOps)
        do {
            let delegate = try FlexDelegate()
            return try Interpreter(modelPath: modelPath, delegates: [delegate])
        } catch {
            print("⚠️ Could not create interpreter with FlexDelegate, falling back to default: \(error)")
            return try Interpreter(modelPath: modelPath)
        }
        #else
        // Fallback to standard interpreter (may fail if model needs Flex ops)
        return try Interpreter(modelPath: modelPath)
        #endif
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
        throw ModelInferenceError.invalidTensorShape("Expected rank-2 or rank-3 input tensor, got \(dimensions).")
    }

    private func readOutput(from interpreter: Interpreter) throws -> Float32 {
        let outputTensor = try interpreter.output(at: 0)
        guard outputTensor.dataType == .float32 else {
            throw ModelInferenceError.unsupportedTensorType("Expected Float32 output, got \(outputTensor.dataType).")
        }
        let data = outputTensor.data
        guard data.count >= MemoryLayout<Float32>.size else {
            throw ModelInferenceError.invalidTensorShape("Output tensor is empty.")
        }
        // Safe memory access
        return data.withUnsafeBytes { rawBuffer in
            rawBuffer.bindMemory(to: Float32.self).first ?? 0
        }
    }
    #else
    private func runModel(questionnaireScore: Int, auFrames: [AUFrame]) throws -> Float32 {
        _ = questionnaireScore
        _ = auFrames
        _ = try modelURL()
        throw ModelInferenceError.runtimeUnavailable("TensorFlowLiteSwift is not available.")
    }
    #endif
}
