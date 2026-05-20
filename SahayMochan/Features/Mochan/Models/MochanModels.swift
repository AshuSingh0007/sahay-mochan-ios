import Foundation

enum PHQ9 {
    static let questions: [QuestionnaireQuestion] = [
        .init(id: 0, text: "Little interest or pleasure in doing things"),
        .init(id: 1, text: "Feeling down, depressed, or hopeless"),
        .init(id: 2, text: "Trouble falling or staying asleep, or sleeping too much"),
        .init(id: 3, text: "Feeling tired or having little energy"),
        .init(id: 4, text: "Poor appetite or overeating"),
        .init(id: 5, text: "Feeling bad about yourself"),
        .init(id: 6, text: "Trouble concentrating on things"),
        .init(id: 7, text: "Moving or speaking slowly, or being fidgety/restless"),
        .init(id: 8, text: "Thoughts that you would be better off dead or hurting yourself")
    ]
}
