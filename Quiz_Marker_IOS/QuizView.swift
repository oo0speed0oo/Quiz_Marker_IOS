import SwiftUI
import Translation

struct QuizView: View {
    @Binding var path: NavigationPath
    @Bindable var manager: QuizManager
    let store: QuizStore

    let file: String
    let units: [String]
    let chapters: [String]
    let limit: Int

    @State private var showingAnswer    = false
    @State private var showTranslation  = false
    @State private var hasCopied        = false
    @State private var grammarRuleText  = ""
    @State private var moreText         = ""
    @State private var grammarCache: [String: (rule: String, more: String)] = [:]
    @State private var translatingChoice: String? = nil
    @State private var sessionStart: Date = Date()
    @State private var lastAnswerCorrect: Bool? = nil   // ← NEW: visual feedback

    private var quizDisplayName: String {
        file.replacingOccurrences(of: ".csv", with: "").capitalized
    }

    var body: some View {
        Group {
            if manager.isFinished {
                QuizResultsView(
                    score: manager.score,
                    total: manager.questions.count,
                    wrongAnswers: manager.wrongAnswers   // ← pass mistakes to results
                ) {
                    manager.reset()
                    path.removeLast(path.count)
                }
            } else if manager.isLoading || manager.questions.isEmpty {
                ProgressView("Loading…")
            } else if let q = manager.currentQuestion {
                questionView(for: q)
            }
        }
        .onAppear {
            sessionStart = Date()
            manager.load(file: file, units: units, chapters: chapters, limit: limit)
        }
        .onDisappear {
            if !manager.isFinished { manager.reset() }
        }
        .onChange(of: manager.isFinished) { _, finished in
            guard finished else { return }
            let duration = Date().timeIntervalSince(sessionStart)
            store.saveRecord(
                quizName: quizDisplayName,
                score: manager.score,
                total: manager.questions.count,
                durationSeconds: duration
            )
            // ← Save wrong answers to persistent store
            store.saveWrongAnswers(manager.wrongAnswers, quizName: quizDisplayName)
        }
    }

    // MARK: - Question View

    @ViewBuilder
    private func questionView(for q: Question) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                progressHeader(q: q)
                metaHeader(q: q)
                questionTextBlock(q: q)
                grammarBlock(q: q)
                choicesBlock(q: q)
                if showingAnswer { nextButton }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Subviews

    private func progressHeader(q: Question) -> some View {
        HStack {
            Text("Question \(manager.currentIndex + 1) of \(manager.questions.count)")
            Spacer()
            // ← Show wrong count as a little red badge
            if !manager.wrongAnswers.isEmpty {
                Label("\(manager.wrongAnswers.count) wrong", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption.bold())
            }
            Text("Score: \(manager.score)")
        }
        .font(.caption.bold())
        .foregroundColor(.secondary)
        .padding(.horizontal)
    }

    private func metaHeader(q: Question) -> some View {
        HStack {
            Label("ID: \(q.number)", systemImage: "number.square")
            Spacer()
            Text("Unit \(q.unit)")
            Spacer()
            Text("Ch. \(q.chapter)")
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private func questionTextBlock(q: Question) -> some View {
        VStack(spacing: 10) {
            Text(q.text)
                .font(.title3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)

            HStack(spacing: 20) {
                Button { showTranslation.toggle() } label: {
                    Label("Translate", systemImage: "character.book.closed")
                        .font(.caption.bold())
                }
                .translationPresentation(isPresented: $showTranslation, text: q.text)

                Button {
                    UIPasteboard.general.string = q.text
                    hasCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { hasCopied = false }
                } label: {
                    Label(hasCopied ? "Copied!" : "Copy",
                          systemImage: hasCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.caption.bold())
                        .foregroundColor(hasCopied ? .green : .blue)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Grammar Block

    private func grammarBlock(q: Question) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            styledText(
                grammarRuleText.isEmpty ? "Tap 'Grammar' to load the rule." : grammarRuleText,
                font: .system(size: 13, design: .rounded)
            )
            .fixedSize(horizontal: false, vertical: true)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)

            if !moreText.isEmpty {
                styledText(moreText, font: .system(size: 13, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(8)
            }

            HStack(spacing: 8) {
                Button { loadGrammarRule(for: q.grammarRef) } label: {
                    Label("Grammar", systemImage: "book.pages.fill")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button { loadMore(for: q.grammarRef) } label: {
                    Label("More", systemImage: "text.append")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Choices Block

    private func choicesBlock(q: Question) -> some View {
        VStack(spacing: 10) {
            ForEach(["A", "B", "C", "D"], id: \.self) { letter in
                let choiceText = q.option(for: letter)
                GeometryReader { geo in
                    HStack(spacing: 8) {
                        Button {
                            guard !showingAnswer else { return }
                            let correct = manager.checkAnswer(letter)
                            lastAnswerCorrect = correct
                            withAnimation { showingAnswer = true }
                        } label: {
                            HStack {
                                Text("\(letter): \(choiceText)")
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if showingAnswer {
                                    Image(systemName: letter == q.answer
                                          ? "checkmark.circle.fill" : "xmark.circle.fill")
                                }
                            }
                            .padding()
                            .frame(width: geo.size.width * 0.75)
                            .frame(minHeight: 50)
                            .background(choiceBackground(letter: letter, q: q))
                            .foregroundColor(choiceForeground(letter: letter, q: q))
                            .cornerRadius(10)
                        }
                        .disabled(showingAnswer)

                        Button { translatingChoice = letter } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "character.book.closed")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Translate")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .frame(width: geo.size.width * 0.25 - 8)
                            .frame(minHeight: 50)
                            .background(Color.teal.opacity(0.15))
                            .foregroundColor(.teal)
                            .cornerRadius(10)
                        }
                        .translationPresentation(
                            isPresented: Binding(
                                get: { translatingChoice == letter },
                                set: { if !$0 { translatingChoice = nil } }
                            ),
                            text: choiceText
                        )
                    }
                }
                .frame(minHeight: 50)
            }
        }
        .padding(.horizontal)
    }

    private var nextButton: some View {
        Button(action: advanceQuestion) {
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

    // MARK: - Actions

    private func advanceQuestion() {
        showingAnswer     = false
        hasCopied         = false
        grammarRuleText   = ""
        moreText          = ""
        translatingChoice = nil
        lastAnswerCorrect = nil
        manager.nextQuestion()
    }

    // MARK: - Grammar (cached)

    private func loadGrammarRule(for ref: String) {
        fetchGrammarIfNeeded(for: ref)
        grammarRuleText = grammarCache[ref]?.rule ?? "No rule found for \(ref)."
    }

    private func loadMore(for ref: String) {
        fetchGrammarIfNeeded(for: ref)
        moreText = grammarCache[ref]?.more ?? ""
    }

    private func fetchGrammarIfNeeded(for ref: String) {
        guard grammarCache[ref] == nil else { return }
        guard !ref.isEmpty else {
            grammarCache[ref] = (rule: "No grammar rule linked to this question.", more: "")
            return
        }
        guard
            let path    = Bundle.main.path(forResource: "grammar_rules", ofType: "csv"),
            let content = try? String(contentsOfFile: path, encoding: .utf8)
        else {
            grammarCache[ref] = (rule: "Grammar file not found.", more: "")
            return
        }
        let rows = CSVParser.parseRows(content).dropFirst()
        for cols in rows {
            guard cols.count >= 4 else { continue }
            if cols[2].trimmed == ref.trimmed {
                let rule = cols[3].trimmed
                let more = cols.count >= 5 ? cols[4].trimmed : ""
                grammarCache[ref] = (rule: rule, more: more)
                return
            }
        }
        grammarCache[ref] = (rule: "No rule found for \(ref).", more: "")
    }

    // MARK: - Strikethrough Renderer

    @ViewBuilder
    private func styledText(_ raw: String, font: Font) -> some View {
        let parts = raw.components(separatedBy: "~~")
        if parts.count <= 1 {
            Text(raw).font(font)
        } else {
            Text(makeAttributedString(raw)).font(font)
        }
    }

    private func makeAttributedString(_ raw: String) -> AttributedString {
        let parts = raw.components(separatedBy: "~~")
        var result = AttributedString()
        for (index, segment) in parts.enumerated() {
            var chunk = AttributedString(segment)
            if index % 2 == 1 { chunk.strikethroughStyle = .single }
            result.append(chunk)
        }
        return result
    }

    // MARK: - Choice Colours

    private func choiceBackground(letter: String, q: Question) -> Color {
        guard showingAnswer else { return Color.blue.opacity(0.1) }
        return letter == q.answer ? .green.opacity(0.2) : Color.gray.opacity(0.1)
    }

    private func choiceForeground(letter: String, q: Question) -> Color {
        guard showingAnswer else { return .primary }
        return letter == q.answer ? .green : .secondary
    }
}
