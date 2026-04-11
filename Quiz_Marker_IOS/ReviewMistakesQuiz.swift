import SwiftUI
import Translation

/// A self-contained quiz that works through the user's saved wrong answers.
/// - Answer correctly  → question is removed from the mistakes list forever
/// - Answer wrongly    → question stays (will appear again next review session)
struct ReviewMistakesQuizView: View {
    @Binding var path: NavigationPath
    let store: QuizStore

    // Working copy of the queue — pulled from store on appear
    @State private var queue:         [PersistedWrongAnswer] = []
    @State private var currentIndex   = 0
    @State private var showingAnswer  = false
    @State private var sessionCorrect = 0
    @State private var sessionTotal   = 0
    @State private var isFinished     = false

    // Translation / copy helpers
    @State private var showTranslation:   Bool    = false
    @State private var hasCopied:         Bool    = false
    @State private var translatingChoice: String? = nil
    @State private var isBookmarked:      Bool    = false

    private var current: PersistedWrongAnswer? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var body: some View {
        Group {
            if isFinished || queue.isEmpty {
                finishedView
            } else if let q = current {
                questionView(for: q)
            }
        }
        .onAppear(perform: loadQueue)
        .navigationTitle("Review Mistakes")
        .navigationBarBackButtonHidden(isFinished)
    }

    // MARK: - Load

    private func loadQueue() {
        queue        = store.wrongAnswers.shuffled()
        sessionTotal = queue.count
    }

    // MARK: - Finished Screen

    private var finishedView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: sessionCorrect == sessionTotal ? "star.fill" : "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(sessionCorrect == sessionTotal ? .yellow : .green)

            Text("Review Complete!")
                .font(.largeTitle.bold())

            VStack(spacing: 6) {
                Text("\(sessionCorrect) cleared  ·  \(sessionTotal - sessionCorrect) remaining")
                    .font(.title3)
                    .foregroundColor(.secondary)

                if store.wrongAnswers.isEmpty {
                    Text("🎉 Mistake list is empty!")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal)

            Spacer()

            Button {
                path.removeLast(path.count)
            } label: {
                Text("Return to Menu")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Question View

    @ViewBuilder
    private func questionView(for w: PersistedWrongAnswer) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                progressHeader(w: w)
                metaHeader(w: w)
                questionTextBlock(w: w)
                choicesBlock(for: w)
                if showingAnswer { nextButton(for: w) }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Progress Header

    private func progressHeader(w: PersistedWrongAnswer) -> some View {
        HStack {
            Text("Question \(currentIndex + 1) of \(queue.count)")
            Spacer()
            if sessionCorrect > 0 {
                Label("\(sessionCorrect) cleared", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption.bold())
            }
            Text("Remaining: \(queue.count - currentIndex - 1)")
        }
        .font(.caption.bold())
        .foregroundColor(.secondary)
        .padding(.horizontal)
    }

    // MARK: - Meta Header  (blue band, same as QuizView)

    private func metaHeader(w: PersistedWrongAnswer) -> some View {
        HStack {
            if !w.quizName.isEmpty {
                Label(w.quizName, systemImage: "book.closed")
                    .lineLimit(1)
            }
            Spacer()
            if !w.unit.isEmpty    { Text("Unit \(w.unit)") }
            if !w.chapter.isEmpty { Text("Ch. \(w.chapter)") }
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    // MARK: - Question Text Block

    private func questionTextBlock(w: PersistedWrongAnswer) -> some View {
        VStack(spacing: 10) {
            Text(w.questionText)
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
                .translationPresentation(isPresented: $showTranslation, text: w.questionText)

                Button {
                    UIPasteboard.general.string = w.questionText
                    hasCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { hasCopied = false }
                } label: {
                    Label(hasCopied ? "Copied!" : "Copy",
                          systemImage: hasCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.caption.bold())
                        .foregroundColor(hasCopied ? .green : .blue)
                }

                Button {
                    store.toggleBookmark(
                        quizName:       w.quizName,
                        chapter:        w.chapter,
                        unit:           w.unit,
                        questionNumber: w.questionNumber,
                        questionText:   w.questionText,
                        choiceA:        w.choiceA,
                        choiceB:        w.choiceB,
                        choiceC:        w.choiceC,
                        choiceD:        w.choiceD,
                        correctAnswer:  w.correctAnswer
                    )
                    isBookmarked = store.isBookmarked(questionNumber: w.questionNumber, quizName: w.quizName)
                } label: {
                    Label(isBookmarked ? "Bookmarked" : "Bookmark",
                          systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.caption.bold())
                        .foregroundColor(isBookmarked ? .yellow : .blue)
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            isBookmarked = store.isBookmarked(questionNumber: w.questionNumber, quizName: w.quizName)
        }
    }

    // MARK: - Choices Block  (no GeometryReader — text wraps, buttons grow)

    private func choicesBlock(for w: PersistedWrongAnswer) -> some View {
        let choices = ["A": w.choiceA, "B": w.choiceB, "C": w.choiceC, "D": w.choiceD]

        return VStack(spacing: 10) {
            ForEach(["A", "B", "C", "D"], id: \.self) { letter in
                let text      = choices[letter] ?? ""
                let isCorrect = letter == w.correctAnswer

                HStack(spacing: 8) {
                    Button {
                        guard !showingAnswer else { return }
                        handleAnswer(letter: letter, for: w)
                        withAnimation { showingAnswer = true }
                    } label: {
                        HStack(alignment: .top) {
                            Text("\(letter): \(text)")
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 4)
                            if showingAnswer {
                                Image(systemName: isCorrect
                                      ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .padding(.top, 2)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(choiceBG(letter: letter, correct: w.correctAnswer))
                        .foregroundColor(choiceFG(letter: letter, correct: w.correctAnswer))
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
                        .frame(width: 72)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.teal.opacity(0.15))
                        .foregroundColor(.teal)
                        .cornerRadius(10)
                    }
                    .translationPresentation(
                        isPresented: Binding(
                            get: { translatingChoice == letter },
                            set: { if !$0 { translatingChoice = nil } }
                        ),
                        text: text
                    )
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Next Button

    private func nextButton(for w: PersistedWrongAnswer) -> some View {
        let isLast = currentIndex + 1 >= queue.count
        return Button(action: advance) {
            Text(isLast ? "See Results" : "Next Question")
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

    // MARK: - Logic

    private func handleAnswer(letter: String, for w: PersistedWrongAnswer) {
        if letter == w.correctAnswer {
            sessionCorrect += 1
            store.removeWrongAnswer(id: w.id)
        }
    }

    private func advance() {
        showingAnswer     = false
        hasCopied         = false
        translatingChoice = nil
        isBookmarked      = false

        if currentIndex + 1 >= queue.count {
            isFinished = true
        } else {
            currentIndex += 1
        }
    }

    // MARK: - Colours

    private func choiceBG(letter: String, correct: String) -> Color {
        guard showingAnswer else { return Color.blue.opacity(0.1) }
        return letter == correct ? .green.opacity(0.2) : Color.gray.opacity(0.1)
    }

    private func choiceFG(letter: String, correct: String) -> Color {
        guard showingAnswer else { return .primary }
        return letter == correct ? .green : .secondary
    }
}
