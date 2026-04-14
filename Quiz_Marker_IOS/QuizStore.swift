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
    let id:             UUID
    let quizName:       String
    let chapter:        String
    let unit:           String
    let questionNumber: String
    let questionText:   String
    let choiceA:        String
    let choiceB:        String
    let choiceC:        String
    let choiceD:        String
    let correctAnswer:  String
    let chosenAnswer:   String
    let date:           Date
}

/// A note the user wrote, optionally used to generate quiz questions.
struct Note: Codable, Identifiable {
    let id:        UUID
    var title:     String
    var body:      String
    let createdAt: Date
    var updatedAt: Date
}

/// A question the user has bookmarked for later review.
struct PersistedBookmark: Codable, Identifiable {
    let id:             UUID
    let quizName:       String
    let chapter:        String
    let unit:           String
    let questionNumber: String
    let questionText:   String
    let choiceA:        String
    let choiceB:        String
    let choiceC:        String
    let choiceD:        String
    let correctAnswer:  String
    let date:           Date
}

/// Tracks when a user last completed a full pass through a flashcard chapter.
struct FlashcardProgress: Codable, Identifiable {
    let id:        UUID
    let fileName:  String   // the CSV file name e.g. "jlpt_n5.csv"
    let chapter:   String
    var lastReviewed: Date
    var reviewCount:  Int   // how many full passes completed
}

/// Cumulative correct/total attempts for one chapter across ALL sessions.
/// Merging strategy: each new quiz session adds to the running totals.
struct ChapterAttempt: Codable, Identifiable {
    let id:       UUID
    let quizName: String
    let chapter:  String
    var correct:  Int
    var total:    Int
    var lastSeen: Date

    var percentage: Int {
        guard total > 0 else { return 0 }
        return Int(Double(correct) / Double(total) * 100)
    }
}

// MARK: - Store

@Observable
class QuizStore {
    private(set) var records:           [QuizRecord]           = []
    private(set) var sessions:          [StudySession]         = []
    private(set) var wrongAnswers:      [PersistedWrongAnswer] = []
    private(set) var chapterAttempts:   [ChapterAttempt]       = []
    private(set) var bookmarks:         [PersistedBookmark]    = []
    private(set) var flashcardProgress: [FlashcardProgress]    = []
    private(set) var notes:             [Note]                 = []

    private let recordsKey            = "quiz_records_v1"
    private let sessionsKey           = "quiz_sessions_v1"
    private let wrongAnswersKey       = "wrong_answers_v1"
    private let chapterAttemptsKey    = "chapter_attempts_v1"
    private let bookmarksKey          = "bookmarks_v1"
    private let flashcardProgressKey  = "flashcard_progress_v1"
    private let notesKey              = "notes_v1"

    init() { load() }

    // MARK: - Save Quiz Record

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

    // MARK: - Save Chapter Attempts

    /// Called at end of each quiz with the per-chapter breakdown from QuizManager.
    /// Merges into existing running totals so scores improve over time.
    func saveChapterAttempts(_ breakdown: [String: (correct: Int, total: Int)], quizName: String) {
        guard !breakdown.isEmpty else { return }
        let now = Date()

        for (chapter, counts) in breakdown {
            // Find existing record for this quiz+chapter and accumulate
            if let idx = chapterAttempts.firstIndex(where: {
                $0.quizName == quizName && $0.chapter == chapter
            }) {
                chapterAttempts[idx].correct  += counts.correct
                chapterAttempts[idx].total    += counts.total
                chapterAttempts[idx].lastSeen  = now
            } else {
                chapterAttempts.append(ChapterAttempt(
                    id:       UUID(),
                    quizName: quizName,
                    chapter:  chapter,
                    correct:  counts.correct,
                    total:    counts.total,
                    lastSeen: now
                ))
            }
        }
        persist(chapterAttempts, key: chapterAttemptsKey)
    }

    /// Look up the cumulative attempt record for one chapter.
    func chapterAttempt(chapter: String, quizName: String) -> ChapterAttempt? {
        chapterAttempts.first { $0.chapter == chapter && $0.quizName == quizName }
    }

    // MARK: - Flashcard Progress

    /// Returns the progress record for a specific file + chapter, if it exists.
    func flashcardProgress(fileName: String, chapter: String) -> FlashcardProgress? {
        flashcardProgress.first { $0.fileName == fileName && $0.chapter == chapter }
    }

    /// Call this when the user finishes a full pass through a chapter's cards.
    func markFlashcardChapterComplete(fileName: String, chapter: String) {
        if let idx = flashcardProgress.firstIndex(where: {
            $0.fileName == fileName && $0.chapter == chapter
        }) {
            flashcardProgress[idx].lastReviewed = Date()
            flashcardProgress[idx].reviewCount  += 1
        } else {
            flashcardProgress.append(FlashcardProgress(
                id:           UUID(),
                fileName:     fileName,
                chapter:      chapter,
                lastReviewed: Date(),
                reviewCount:  1
            ))
        }
        persist(flashcardProgress, key: flashcardProgressKey)
    }

    /// Resets the completed status for a chapter so it shows as unreviewed again.
    func resetFlashcardProgress(fileName: String, chapter: String) {
        flashcardProgress.removeAll { $0.fileName == fileName && $0.chapter == chapter }
        persist(flashcardProgress, key: flashcardProgressKey)
    }

    // MARK: - Bookmarks

    func isBookmarked(questionNumber: String, quizName: String) -> Bool {
        bookmarks.contains { $0.questionNumber == questionNumber && $0.quizName == quizName }
    }

    func toggleBookmark(quizName: String, chapter: String, unit: String,
                        questionNumber: String, questionText: String,
                        choiceA: String, choiceB: String, choiceC: String, choiceD: String,
                        correctAnswer: String) {
        if let idx = bookmarks.firstIndex(where: {
            $0.questionNumber == questionNumber && $0.quizName == quizName
        }) {
            bookmarks.remove(at: idx)
        } else {
            bookmarks.insert(PersistedBookmark(
                id:             UUID(),
                quizName:       quizName,
                chapter:        chapter,
                unit:           unit,
                questionNumber: questionNumber,
                questionText:   questionText,
                choiceA:        choiceA,
                choiceB:        choiceB,
                choiceC:        choiceC,
                choiceD:        choiceD,
                correctAnswer:  correctAnswer,
                date:           Date()
            ), at: 0)
        }
        persist(bookmarks, key: bookmarksKey)
    }

    func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        persist(bookmarks, key: bookmarksKey)
    }

    func clearBookmarks() {
        bookmarks = []
        persist(bookmarks, key: bookmarksKey)
    }

    // MARK: - Notes

    @discardableResult
    func addNote(title: String, body: String) -> Note {
        let note = Note(id: UUID(), title: title, body: body, createdAt: Date(), updatedAt: Date())
        notes.insert(note, at: 0)
        persist(notes, key: notesKey)
        return note
    }

    func updateNote(id: UUID, title: String, body: String) {
        guard let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[idx].title     = title
        notes[idx].body      = body
        notes[idx].updatedAt = Date()
        persist(notes, key: notesKey)
    }

    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        persist(notes, key: notesKey)
    }

    // MARK: - Wrong Answers

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
        wrongAnswers = Array((persisted + wrongAnswers).prefix(500))
        persist(wrongAnswers, key: wrongAnswersKey)
    }

    func removeWrongAnswer(id: UUID) {
        wrongAnswers.removeAll { $0.id == id }
        persist(wrongAnswers, key: wrongAnswersKey)
    }

    func clearWrongAnswers() {
        wrongAnswers = []
        persist(wrongAnswers, key: wrongAnswersKey)
    }

    /// How many times a chapter question was answered wrong (red badge).
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
        records           = decode([QuizRecord].self,           key: recordsKey)           ?? []
        sessions          = decode([StudySession].self,         key: sessionsKey)          ?? []
        wrongAnswers      = decode([PersistedWrongAnswer].self,  key: wrongAnswersKey)      ?? []
        chapterAttempts   = decode([ChapterAttempt].self,        key: chapterAttemptsKey)   ?? []
        bookmarks         = decode([PersistedBookmark].self,     key: bookmarksKey)         ?? []
        flashcardProgress = decode([FlashcardProgress].self,     key: flashcardProgressKey) ?? []
        notes             = decode([Note].self,                  key: notesKey)             ?? []
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
