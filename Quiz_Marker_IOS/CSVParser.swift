import Foundation

struct CSVParser {

    // MARK: - File Loading

    static func load(resource: String) -> (schema: Schema, rows: [[String]])? {
        let name = resource.replacingOccurrences(of: ".csv", with: "")
        guard
            let path    = Bundle.main.path(forResource: name, ofType: "csv"),
            let content = try? String(contentsOfFile: path, encoding: .utf8)
        else { return nil }

        let rows = parseRows(content)
        guard let headerRow = rows.first, let schema = Schema(headers: headerRow) else { return nil }
        return (schema, Array(rows.dropFirst()))
    }

    // MARK: - Column Schema

    struct Schema {
        let number:     Int
        let unit:       Int?
        let chapter:    Int?
        let grammarRef: Int?   // ← new: links to grammar_rules.csv
        let text:       Int
        let choiceA:    Int
        let choiceB:    Int
        let choiceC:    Int
        let choiceD:    Int
        let answer:     Int

        init?(headers: [String]) {
            let h = headers.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }

            func col(_ exact: String, suffix: String? = nil) -> Int? {
                if let i = h.firstIndex(of: exact) { return i }
                if let s = suffix { return h.firstIndex(where: { $0.hasSuffix(s) }) }
                return nil
            }

            guard let textIdx = col("question") else { return nil }

            guard
                let aIdx      = col("choice_a", suffix: "_a"),
                let bIdx      = col("choice_b", suffix: "_b"),
                let cIdx      = col("choice_c", suffix: "_c"),
                let dIdx      = col("choice_d", suffix: "_d"),
                let answerIdx = col("answer")
            else { return nil }

            number     = col("question_number", suffix: "_number") ?? 0
            unit       = col("unit_number") ?? col("unit")
            chapter    = col("chapter_number") ?? col("chapter") ?? col("section_number") ?? col("section")
            grammarRef = col("grammar_ref")
            text       = textIdx
            choiceA    = aIdx
            choiceB    = bIdx
            choiceC    = cIdx
            choiceD    = dIdx
            answer     = answerIdx
        }
    }

    // MARK: - Full-File Row Parser

    static func parseRows(_ content: String) -> [[String]] {
        var rows:    [[String]] = []
        var current: [String]  = []
        var field    = ""
        var inQuotes = false

        let text = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r",   with: "\n")

        for char in text {
            switch char {
            case "\"":
                inQuotes.toggle()
            case ",":
                if inQuotes { field.append(char) }
                else { current.append(field.trimmed); field = "" }
            case "\n":
                if inQuotes {
                    field.append(" ")
                } else {
                    current.append(field.trimmed)
                    field = ""
                    if !current.allSatisfy({ $0.isEmpty }) { rows.append(current) }
                    current = []
                }
            default:
                field.append(char)
            }
        }
        current.append(field.trimmed)
        if !current.allSatisfy({ $0.isEmpty }) { rows.append(current) }
        return rows
    }

    // MARK: - Single Line Split

    static func safeSplit(line: String) -> [String] {
        var result:      [String] = []
        var current      = ""
        var insideQuotes = false

        for char in line.replacingOccurrences(of: "\r", with: "") {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current.trimmingCharacters(in: .init(charactersIn: "\" ")))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .init(charactersIn: "\" ")))
        return result.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
