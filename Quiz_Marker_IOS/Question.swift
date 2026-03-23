import Foundation

struct Question: Identifiable, Hashable {
    let id         = UUID()
    let number:     String
    let unit:       String
    let chapter:    String
    let grammarRef: String   // ← links to grammar_rules.csv; empty if not set
    let text:       String
    let choices:    [String: String]
    let answer:     String

    init(number: String, unit: String, chapter: String, grammarRef: String, rawText: String,
         choiceA: String, choiceB: String, choiceC: String, choiceD: String, answer: String) {
        self.number     = number.trimmed
        self.unit       = unit.trimmed
        self.chapter    = chapter.trimmed
        self.grammarRef = grammarRef.trimmed
        self.answer     = answer.trimmed.uppercased()
        self.text       = rawText.replacingOccurrences(of: "\\n", with: "\n").trimmed
        self.choices    = ["A": choiceA.trimmed, "B": choiceB.trimmed, "C": choiceC.trimmed, "D": choiceD.trimmed]
    }

    func option(for letter: String) -> String {
        choices[letter.uppercased()] ?? ""
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
