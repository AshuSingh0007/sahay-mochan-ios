import Foundation

struct QuestionnaireQuestion: Identifiable, Equatable {
    let id: Int
    let text: String
}

enum GAD7 {
    static let questions: [QuestionnaireQuestion] = [
        .init(id: 0, text: "Feeling nervous, anxious, or on edge"),
        .init(id: 1, text: "Not being able to stop or control worrying"),
        .init(id: 2, text: "Worrying too much about different things"),
        .init(id: 3, text: "Trouble relaxing"),
        .init(id: 4, text: "Being so restless that it is hard to sit still"),
        .init(id: 5, text: "Becoming easily annoyed or irritable"),
        .init(id: 6, text: "Feeling afraid as if something awful might happen")
    ]
}

struct AUFrame: Codable, Identifiable {
    var id = UUID()
    let timestamp: TimeInterval
    let values: [Float]
}

enum AUFeatureSet {
    static let canonicalFeatures = [
        "AU01_r", "AU02_r", "AU04_r", "AU05_r", "AU06_r", "AU07_r",
        "AU09_r", "AU10_r", "AU12_r", "AU14_r", "AU15_r", "AU17_r",
        "AU20_r", "AU23_r", "AU25_r", "AU26_r", "AU45_r", "gaze_x", "gaze_y"
    ]
}
