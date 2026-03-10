import Foundation

struct Question: Identifiable, Hashable {
    let id = UUID()
    let number: String
    let unit: String
    let chapter: String
    let text: String
    let choices: [String: String]
    let answer: String

    init(number: String, unit: String, chapter: String, rawText: String, choiceA: String, choiceB: String, choiceC: String, choiceD: String, answer: String) {
        self.number = number.trimmingCharacters(in: .whitespacesAndNewlines)
        self.unit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        self.chapter = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
        self.answer = answer.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.text = rawText.replacingOccurrences(of: "\\n", with: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.choices = [
            "A": choiceA.trimmingCharacters(in: .whitespacesAndNewlines),
            "B": choiceB.trimmingCharacters(in: .whitespacesAndNewlines),
            "C": choiceC.trimmingCharacters(in: .whitespacesAndNewlines),
            "D": choiceD.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
    }

    // ✅ This fixes the "no member 'option'" error
    func option(for letter: String) -> String {
        return choices[letter.uppercased()] ?? ""
    }

    var cleanTextForTranslation: String {
        return self.text.replacingOccurrences(of: "\\s?\\(.*?\\)", with: "", options: .regularExpression)
    }
}
