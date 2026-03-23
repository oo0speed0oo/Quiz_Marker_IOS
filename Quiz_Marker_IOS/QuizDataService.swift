import Foundation

/// Reads a CSV file once and provides filtered views of its data.
/// The file is never read more than once per instance.
struct QuizDataService {

    let schema: CSVParser.Schema
    private let rows: [[String]]

    init?(file: String) {
        guard let result = CSVParser.load(resource: file) else { return nil }
        self.schema = result.schema
        self.rows   = result.rows
    }

    // MARK: - Units

    var allUnits: [String] {
        guard let unitIdx = schema.unit else { return [] }
        return uniqueSorted(rows.compactMap { row in
            guard row.count > unitIdx else { return nil }
            let u = row[unitIdx].trimmed
            return u.isEmpty ? nil : u
        })
    }

    // MARK: - Chapters

    func chapters(inUnits units: [String]) -> [String] {
        guard let chapterIdx = schema.chapter else { return [] }
        return uniqueSorted(rows.compactMap { row -> String? in
            guard row.count > chapterIdx else { return nil }

            if !units.isEmpty, let unitIdx = schema.unit {
                guard row.count > unitIdx, units.contains(row[unitIdx].trimmed) else { return nil }
            }

            let c = row[chapterIdx].trimmed
            return c.isEmpty ? nil : c
        })
    }

    // MARK: - Questions

    func questions(units: [String], chapters: [String], limit: Int) -> [Question] {
        let s = schema
        let matched: [Question] = rows.compactMap { row in
            // Skip any row that doesn't have enough columns to fill all required fields.
            // This silently drops malformed rows rather than crashing or showing blank answers.
            let required = max(s.number, s.text, s.choiceA, s.choiceB, s.choiceC, s.choiceD, s.answer)
            guard row.count > required else { return nil }

            let unit       = s.unit.flatMap       { row.count > $0 ? row[$0].trimmed : nil } ?? ""
            let chapter    = s.chapter.flatMap    { row.count > $0 ? row[$0].trimmed : nil } ?? ""
            let grammarRef = s.grammarRef.flatMap  { row.count > $0 ? row[$0].trimmed : nil } ?? ""

            let unitMatch    = units.isEmpty    || units.contains(unit)
            let chapterMatch = chapters.isEmpty || chapters.contains(chapter)
            guard unitMatch && chapterMatch else { return nil }

            // Skip rows where the answer is missing or blank
            let answer = row[s.answer].trimmed
            guard !answer.isEmpty else { return nil }

            return Question(
                number:     row[s.number].trimmed,
                unit:       unit,
                chapter:    chapter,
                grammarRef: grammarRef,
                rawText:    row[s.text].trimmed,
                choiceA: row[s.choiceA].trimmed,
                choiceB: row[s.choiceB].trimmed,
                choiceC: row[s.choiceC].trimmed,
                choiceD: row[s.choiceD].trimmed,
                answer:  answer
            )
        }

        let shuffled = matched.shuffled()
        let cap      = limit > 0 ? min(limit, shuffled.count) : shuffled.count
        return Array(shuffled.prefix(cap))
    }

    /// Total matching questions (no shuffle/limit) — used for the count screen.
    func questionCount(units: [String], chapters: [String]) -> Int {
        questions(units: units, chapters: chapters, limit: 0).count
    }

    // MARK: - Helpers

    private func uniqueSorted(_ values: [String]) -> [String] {
        Array(Set(values)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}
