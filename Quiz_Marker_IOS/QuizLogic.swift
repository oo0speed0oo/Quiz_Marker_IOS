import Foundation
import Observation

@Observable
class QuizManager {
    var questions: [Question] = []
    var currentIndex = 0
    var score = 0
    var isFinished = false
    
    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    func loadQuestions(filename: String, units: [String], chapters: [String], limit: Int) {
        let cleanName = filename.replacingOccurrences(of: ".csv", with: "")
        guard let path = Bundle.main.path(forResource: cleanName, ofType: "csv") else { return }
        
        var loaded: [Question] = []
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            for line in lines.dropFirst() {
                let cols = CSVParser.safeSplit(line: line)
                guard cols.count >= 9 else { continue }
                
                let qUnit = cols[1].trimmed
                let qChap = cols[2].trimmed
                
                if (units.isEmpty || units.contains(qUnit)) && (chapters.isEmpty || chapters.contains(qChap)) {
                    let q = Question(
                        number: cols[0],
                        unit: qUnit,
                        chapter: qChap,
                        rawText: cols[3],
                        choiceA: cols[4],
                        choiceB: cols[5],
                        choiceC: cols[6],
                        choiceD: cols[7],
                        answer: cols[8]
                    )
                    loaded.append(q)
                }
            }
            
            DispatchQueue.main.async {
                let shuffled = loaded.shuffled()
                let actualLimit = limit > 0 ? min(limit, shuffled.count) : shuffled.count
                self.questions = Array(shuffled.prefix(actualLimit))
                self.currentIndex = 0
                self.score = 0
                self.isFinished = false
            }
        } catch { print("Read Error: \(error)") }
    }
    
    func checkAnswer(_ letter: String) -> Bool {
        guard let current = currentQuestion else { return false }
        let correct = current.answer == letter.uppercased()
        if correct { score += 1 }
        return correct
    }
    
    func nextQuestion() {
        if currentIndex + 1 < questions.count { currentIndex += 1 } else { isFinished = true }
    }
}

// Keeping the trimmed extension here is fine
extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
