import SwiftUI

enum QuizRoute: Hashable {
    case unitSelection(file: String)
    case chapterSelection(file: String, units: [String])
    case questionCount(file: String, units: [String], chapters: [String])
    case activeQuiz(file: String, units: [String], chapters: [String], limit: Int)
    case reviewMistakes
    case flashcardUnitSelection(file: String)
    case flashcardChapterSelection(file: String, units: [String])
    case flashcards(file: String, units: [String], chapters: [String])
}
