import Foundation
import Observation

// Represents one wrong answer during a session
struct WrongAnswer: Identifiable {
    let id          = UUID()
    let question:   Question
    let chosen:     String   // letter the user picked, e.g. "B"
}

@Observable
class QuizManager {
    var questions:    [Question]    = []
    var wrongAnswers: [WrongAnswer] = []   // ← NEW: collects mistakes this session
    var currentIndex = 0
    var score        = 0
    var isFinished   = false
    var isLoading    = false

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    /// Always loads fresh with the exact limit passed in.
    func load(file: String, units: [String], chapters: [String], limit: Int) {
        guard !isLoading else { return }
        isLoading    = true
        questions    = []
        wrongAnswers = []
        currentIndex = 0
        score        = 0
        isFinished   = false

        DispatchQueue.global(qos: .userInitiated).async {
            guard let service = QuizDataService(file: file) else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            let loaded = service.questions(units: units, chapters: chapters, limit: limit)
            DispatchQueue.main.async {
                self.questions = loaded
                self.isLoading = false
            }
        }
    }

    func reset() {
        questions    = []
        wrongAnswers = []
        currentIndex = 0
        score        = 0
        isFinished   = false
        isLoading    = false
    }

    /// Returns true if correct. Records the mistake if wrong.
    @discardableResult
    func checkAnswer(_ letter: String) -> Bool {
        guard let current = currentQuestion else { return false }
        let upper   = letter.uppercased()
        let correct = current.answer == upper
        if correct {
            score += 1
        } else {
            wrongAnswers.append(WrongAnswer(question: current, chosen: upper))
        }
        return correct
    }

    func nextQuestion() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            isFinished = true
        }
    }
}
