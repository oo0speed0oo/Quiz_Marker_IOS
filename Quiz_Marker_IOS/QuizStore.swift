import Foundation

// MARK: - Models

struct QuizRecord: Codable, Identifiable {
    let id: UUID
    let quizName: String
    let score: Int
    let total: Int
    let date: Date
    let durationSeconds: Double

    var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((Double(score) / Double(total)) * 100)
    }
}

struct StudySession: Codable, Identifiable {
    let id: UUID
    let quizName: String
    let date: Date
    let durationSeconds: Double
}

/// One question the user got wrong — stored persistently so they can review later.
struct PersistedWrongAnswer: Codable, Identifiable {
    let id:          UUID
    let quizName:    String
    let chapter:     String
    let unit:        String
    let questionNumber: String
    let questionText: String
    let choiceA:     String
    let choiceB:     String
    let choiceC:     String
    let choiceD:     String
    let correctAnswer: String   // letter, e.g. "B"
    let chosenAnswer:  String   // what the user actually picked
    let date:        Date
}

/// Aggregate performance per chapter, across all attempts.
struct ChapterScore: Identifiable {
    let id      = UUID()
    let chapter: String
    var correct: Int
    var total:   Int
    var percentage: Int {
        guard total > 0 else { return 0 }
        return Int(Double(correct) / Double(total) * 100)
    }
}

// MARK: - Store

@Observable
class QuizStore {
    private(set) var records:      [QuizRecord]           = []
    private(set) var sessions:     [StudySession]         = []
    private(set) var wrongAnswers: [PersistedWrongAnswer] = []

    private let recordsKey      = "quiz_records_v1"
    private let sessionsKey     = "quiz_sessions_v1"
    private let wrongAnswersKey = "wrong_answers_v1"

    init() { load() }

    // MARK: - Save

    func saveRecord(quizName: String, score: Int, total: Int, durationSeconds: Double) {
        let record = QuizRecord(
            id: UUID(), quizName: quizName,
            score: score, total: total,
            date: Date(), durationSeconds: durationSeconds
        )
        records.insert(record, at: 0)
        persist(records, key: recordsKey)

        let session = StudySession(
            id: UUID(), quizName: quizName,
            date: Date(), durationSeconds: durationSeconds
        )
        sessions.insert(session, at: 0)
        persist(sessions, key: sessionsKey)
    }

    /// Call at end of quiz with all WrongAnswer objects from QuizManager.
    func saveWrongAnswers(_ mistakes: [WrongAnswer], quizName: String) {
        guard !mistakes.isEmpty else { return }
        let persisted: [PersistedWrongAnswer] = mistakes.map { w in
            PersistedWrongAnswer(
                id:             UUID(),
                quizName:       quizName,
                chapter:        w.question.chapter,
                unit:           w.question.unit,
                questionNumber: w.question.number,
                questionText:   w.question.text,
                choiceA:        w.question.option(for: "A"),
                choiceB:        w.question.option(for: "B"),
                choiceC:        w.question.option(for: "C"),
                choiceD:        w.question.option(for: "D"),
                correctAnswer:  w.question.answer,
                chosenAnswer:   w.chosen,
                date:           Date()
            )
        }
        // Prepend so newest appear first; keep max 500 entries to avoid bloat
        wrongAnswers = Array((persisted + wrongAnswers).prefix(500))
        persist(wrongAnswers, key: wrongAnswersKey)
    }

    /// Remove a single wrong answer by ID (called when user answers correctly in review mode).
    func removeWrongAnswer(id: UUID) {
        wrongAnswers.removeAll { $0.id == id }
        persist(wrongAnswers, key: wrongAnswersKey)
    }

    /// Remove all stored wrong answers (user can clear after they've reviewed).
    func clearWrongAnswers() {
        wrongAnswers = []
        persist(wrongAnswers, key: wrongAnswersKey)
    }

    // MARK: - Chapter Score Summaries

    /// Returns per-chapter performance derived from persisted wrong answers + total attempts.
    /// Key: chapter string → ChapterScore
    func chapterScores(for quizName: String, questions: [Question]) -> [String: ChapterScore] {
        // We compute scores from the records + wrong answers.
        // For each question answered (total seen), we count how many were wrong per chapter.
        // "total seen" comes from sessions' question counts; we approximate using wrong answers
        // as the denominator anchor and record scores for the percentage.
        // Simpler approach: track per chapter from wrong answers + record data.
        // Since we don't store per-question correct history, we derive:
        //   correct = (record correct answers that belong to chapter, estimated by proportion)
        // Real per-question tracking is in wrongAnswers though, so we do:
        //   wrong per chapter = count from wrongAnswers
        //   total per chapter = from all records (we store that info per quiz, not per chapter)
        // Best we can do without extra data: show "X wrong" per chapter from wrongAnswers.
        var scores: [String: ChapterScore] = [:]
        for w in wrongAnswers where w.quizName == quizName {
            if scores[w.chapter] == nil {
                scores[w.chapter] = ChapterScore(chapter: w.chapter, correct: 0, total: 0)
            }
            scores[w.chapter]!.total += 1   // every stored entry = a wrong attempt
        }
        return scores
    }

    /// How many times a chapter question was answered wrong (simple badge count).
    func wrongCount(for chapter: String, quizName: String) -> Int {
        wrongAnswers.filter { $0.chapter == chapter && $0.quizName == quizName }.count
    }

    // MARK: - Computed

    var cumulativeTimeByQuiz: [(name: String, seconds: Double)] {
        var totals: [String: Double] = [:]
        for s in sessions { totals[s.quizName, default: 0] += s.durationSeconds }
        return totals.map { (name: $0.key, seconds: $0.value) }
                     .sorted { $0.name < $1.name }
    }

    // MARK: - Persistence

    private func load() {
        records      = decode([QuizRecord].self,           key: recordsKey)      ?? []
        sessions     = decode([StudySession].self,         key: sessionsKey)     ?? []
        wrongAnswers = decode([PersistedWrongAnswer].self,  key: wrongAnswersKey) ?? []
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
