import Foundation
#if canImport(TensorFlowLite)
import TensorFlowLite
#endif

final class DepressionModel {
    private let modelName = "best_bilstm_transformer_model"
    private let expectedFallbackSpec = ModelTensorSpec(sequenceLength: 40, featureCount: 17, outputCount: 1)

    func predict(questionnaireScore: Int, auFrames: [AUFrame]) throws -> Double {
        let rawOutput = try runModel(auFrames: auFrames)
        return scale(rawOutput: rawOutput, maximumScore: 24)
    }

    private func scale(rawOutput: Float, maximumScore: Double) -> Double {
        let value = Double(rawOutput)
        if value <= 1 { return min(maximumScore, max(0, value * maximumScore)) }
        return min(maximumScore, max(0, value))
    }

    private func modelURL() throws -> URL {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "tflite") else {
            throw ModelInferenceError.modelNotFound("\(modelName).tflite")
        }
        return url
    }

    #if canImport(TensorFlowLite)
    private func runModel(auFrames: [AUFrame]) throws -> Float {
        let interpreter = try Interpreter(modelPath: try modelURL().path)
        try interpreter.allocateTensors()
        let inputTensor = try interpreter.input(at: 0)
        let outputTensor = try interpreter.output(at: 0)
        let inputSpec = try tensorSpec(input: inputTensor, output: outputTensor)
        var input = try AUSequencePreprocessor.input(frames: auFrames, sequenceLength: inputSpec.sequenceLength, featureCount: inputSpec.featureCount)
        let inputData = input.withUnsafeMutableBufferPointer { Data(buffer: $0) }
        try interpreter.copy(inputData, toInputAt: 0)
        try interpreter.invoke()
        let output = try interpreter.output(at: 0)
        guard output.data.count >= MemoryLayout<Float32>.size else {
            throw ModelInferenceError.invalidTensorShape("Depression model output tensor is empty.")
        }
        return output.data.withUnsafeBytes { $0.load(as: Float32.self) }
    }

    private func tensorSpec(input: Tensor, output: Tensor) throws -> ModelTensorSpec {
        let dimensions = input.shape.dimensions
        guard dimensions.count == 3 else {
            throw ModelInferenceError.invalidTensorShape("Depression model expected rank-3 input, found \(dimensions).")
        }
        let outputCount = output.shape.dimensions.reduce(1, *)
        return ModelTensorSpec(sequenceLength: dimensions[1], featureCount: dimensions[2], outputCount: outputCount)
    }
    #else
    private func runModel(auFrames: [AUFrame]) throws -> Float {
        _ = try modelURL()
        _ = try AUSequencePreprocessor.input(frames: auFrames, sequenceLength: expectedFallbackSpec.sequenceLength, featureCount: expectedFallbackSpec.featureCount)
        throw ModelInferenceError.runtimeUnavailable("TensorFlowLiteSwift is not installed. Run pod install and open the workspace to enable real depression inference.")
    }
    #endif
}
