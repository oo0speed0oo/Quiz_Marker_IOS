import SwiftUI

enum QuizRoute: Hashable {
    case unitSelection(file: String)
    case chapterSelection(file: String, units: [String])
    case questionCount(file: String, units: [String], chapters: [String])
    case activeQuiz(file: String, units: [String], chapters: [String], limit: Int)
    case reviewMistakes   // ← NEW: launches the wrong-answer review quiz
}
