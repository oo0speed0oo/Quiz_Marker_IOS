import SwiftUI
import Translation

struct QuizView: View {
    @Binding var path: NavigationPath
    var manager: QuizManager
    
    @State private var showingAnswer = false
    @State private var grammarRuleText: String = "Tap the button below for help."
    @State private var showTranslation = false
    @State private var hasCopied = false

    let file: String
    let units: [String]
    let chapters: [String]
    let limit: Int

    var body: some View {
        VStack(spacing: 15) {
            if manager.questions.isEmpty {
                ProgressView("Loading...")
            } else if let q = manager.currentQuestion {
                
                // 1. TOP HEADER: Progress and Score
                HStack {
                    Text("Question \(manager.currentIndex + 1) of \(manager.questions.count)")
                    Spacer()
                    Text("Score: \(manager.score)")
                }
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

                // 2. DATA TRACKING HEADER: File ID, Unit, Chapter
                // This helps you find mistakes in your CSV file easily
                HStack {
                    Label("File ID: \(q.number)", systemImage: "number.square")
                    Spacer()
                    Text("Unit: \(q.unit)")
                    Spacer()
                    Text("Ch: \(q.chapter)")
                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)

                // 3. QUESTION TEXT
                VStack(spacing: 10) {
                    ScrollView {
                        Text(q.text)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: 140)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)

                    // TRANSLATE & COPY BUTTONS
                    HStack(spacing: 20) {
                        Button(action: { showTranslation.toggle() }) {
                            Label("Translate", systemImage: "character.book.closed")
                                .font(.caption.bold())
                        }
                        .translationPresentation(isPresented: $showTranslation, text: q.text)

                        Button(action: {
                            UIPasteboard.general.string = q.text
                            hasCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { hasCopied = false }
                        }) {
                            Label(hasCopied ? "Copied!" : "Copy", systemImage: hasCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.caption.bold())
                                .foregroundColor(hasCopied ? .green : .blue)
                        }
                    }
                }
                .padding(.horizontal)

                // 4. GRAMMAR SECTION
                VStack(alignment: .leading, spacing: 8) {
                    Text(grammarRuleText)
                        .font(.system(size: 14, design: .rounded))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 90)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)

                    Button(action: { fetchGrammarRule(for: q.chapter) }) {
                        Label("Show Grammar Rule", systemImage: "book.pages.fill")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // 5. CHOICES
                VStack(spacing: 10) {
                    ForEach(["A", "B", "C", "D"], id: \.self) { letter in
                        let optionText = q.option(for: letter)
                        Button(action: {
                            if !showingAnswer {
                                _ = manager.checkAnswer(letter)
                                withAnimation { showingAnswer = true }
                            }
                        }) {
                            HStack {
                                Text("\(letter): \(optionText)")
                                Spacer()
                                if showingAnswer {
                                    Image(systemName: letter == q.answer ? "checkmark.circle.fill" : "xmark.circle.fill")
                                }
                            }
                            .padding()
                            .background(buttonColor(for: letter, q: q))
                            .foregroundColor(buttonTextColor(for: letter, q: q))
                            .cornerRadius(10)
                        }
                        .disabled(showingAnswer)
                    }
                }
                .padding(.horizontal)

                // NEXT BUTTON
                if showingAnswer {
                    Button(action: { getNewQuestion() }) {
                        Text(manager.currentIndex + 1 < manager.questions.count ? "Next Question" : "See Results")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
        }
        .onAppear {
            manager.loadQuestions(filename: file, units: units, chapters: chapters, limit: limit)
        }
    }

    func getNewQuestion() {
        showingAnswer = false
        hasCopied = false
        grammarRuleText = "Tap the button below for help."
        manager.nextQuestion()
    }

    func fetchGrammarRule(for chapter: String) {
        guard let path = Bundle.main.path(forResource: "grammar rules", ofType: "csv") else {
            self.grammarRuleText = "Grammar file not found."
            return
        }
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines)
            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count >= 3 {
                    let csvChapter = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if csvChapter == chapter.trimmingCharacters(in: .whitespacesAndNewlines) {
                        self.grammarRuleText = columns[2].replacingOccurrences(of: "\"", with: "")
                        return
                    }
                }
            }
            self.grammarRuleText = "No notes found for Chapter \(chapter)."
        } catch {
            self.grammarRuleText = "Error reading grammar file."
        }
    }

    func buttonColor(for letter: String, q: Question) -> Color {
        guard showingAnswer else { return Color.blue.opacity(0.1) }
        if letter == q.answer { return .green.opacity(0.2) }
        return Color.gray.opacity(0.1)
    }
    
    func buttonTextColor(for letter: String, q: Question) -> Color {
        guard showingAnswer else { return .primary }
        if letter == q.answer { return .green }
        return .secondary
    }
}
