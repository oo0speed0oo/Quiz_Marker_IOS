import SwiftUI

/// Self-contained quiz for AI-generated questions from a note.
/// No persistence — just a quick practice session.
struct NoteQuizView: View {
    let questions: [GeneratedQuestion]

    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex    = 0
    @State private var selectedAnswer: String?   = nil
    @State private var showingAnswer   = false
    @State private var score           = 0
    @State private var isFinished      = false

    private var current: GeneratedQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        NavigationStack {
            Group {
                if isFinished {
                    finishedView
                } else if let q = current {
                    questionView(for: q)
                }
            }
            .navigationTitle("Note Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isFinished {
                        Button("Quit") { dismiss() }
                    }
                }
            }
        }
    }

    // MARK: - Question View

    private func questionView(for q: GeneratedQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Progress
                progressBar

                // Question text
                Text(q.questionText)
                    .font(.title3.bold())
                    .padding(.horizontal)

                // Choices
                VStack(spacing: 10) {
                    choiceButton("A", text: q.choiceA, question: q)
                    choiceButton("B", text: q.choiceB, question: q)
                    choiceButton("C", text: q.choiceC, question: q)
                    choiceButton("D", text: q.choiceD, question: q)
                }
                .padding(.horizontal)

                // Explanation (shown after answering)
                if showingAnswer {
                    explanationCard(for: q)
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Next / Finish button
                if showingAnswer {
                    Button {
                        advance()
                    } label: {
                        Text(currentIndex + 1 < questions.count ? "Next Question" : "See Results")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 12)
        }
        .animation(.easeInOut(duration: 0.25), value: showingAnswer)
    }

    // MARK: - Choice Button

    private func choiceButton(_ letter: String, text: String, question: GeneratedQuestion) -> some View {
        let isSelected = selectedAnswer == letter
        let isCorrect  = question.correctAnswer.uppercased() == letter
        let revealed   = showingAnswer

        var bg: Color {
            if !revealed { return isSelected ? Color.accentColor.opacity(0.15) : Color(uiColor: .secondarySystemBackground) }
            if isCorrect { return Color.green.opacity(0.18) }
            if isSelected && !isCorrect { return Color.red.opacity(0.18) }
            return Color(uiColor: .secondarySystemBackground)
        }

        var borderColor: Color {
            if !revealed { return isSelected ? Color.accentColor : Color.clear }
            if isCorrect { return .green }
            if isSelected && !isCorrect { return .red }
            return .clear
        }

        return Button {
            guard !revealed else { return }
            selectedAnswer = letter
            showingAnswer  = true
            if letter == question.correctAnswer.uppercased() { score += 1 }
        } label: {
            HStack(spacing: 12) {
                Text(letter)
                    .font(.headline)
                    .frame(width: 28, height: 28)
                    .background(isSelected || (revealed && isCorrect) ? Color.accentColor : Color(uiColor: .systemGray4))
                    .foregroundColor(.white)
                    .clipShape(Circle())

                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)

                Spacer()

                if revealed {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    }
                }
            }
            .padding(12)
            .background(bg)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1.5))
            .cornerRadius(10)
        }
        .disabled(revealed)
    }

    // MARK: - Explanation Card

    private func explanationCard(for q: GeneratedQuestion) -> some View {
        let correct = selectedAnswer == q.correctAnswer.uppercased()
        return VStack(alignment: .leading, spacing: 8) {
            Label(correct ? "Correct!" : "Incorrect", systemImage: correct ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.headline)
                .foregroundColor(correct ? .green : .red)

            if !q.explanation.isEmpty {
                Text(q.explanation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(questions.count, 1)), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal)

            Text("Question \(currentIndex + 1) of \(questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Finished View

    private var finishedView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: score == questions.count ? "star.fill" : "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(score == questions.count ? .yellow : .accentColor)

            VStack(spacing: 8) {
                Text("Quiz Complete!")
                    .font(.title.bold())
                Text("\(score) / \(questions.count) correct")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            scoreLabel

            Button("Done") { dismiss() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }

    private var scoreLabel: some View {
        let pct = questions.isEmpty ? 0 : Int(Double(score) / Double(questions.count) * 100)
        let (label, color): (String, Color) = {
            switch pct {
            case 90...100: return ("Excellent", .green)
            case 70..<90:  return ("Good",      .blue)
            case 50..<70:  return ("OK",         .orange)
            default:       return ("Keep studying", .red)
            }
        }()
        return Text("\(pct)% — \(label)")
            .font(.headline)
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.12))
            .cornerRadius(10)
    }

    // MARK: - Navigation

    private func advance() {
        selectedAnswer = nil
        showingAnswer  = false
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            isFinished = true
        }
    }
}
