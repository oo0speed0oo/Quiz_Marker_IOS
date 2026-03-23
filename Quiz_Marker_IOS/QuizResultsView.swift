import SwiftUI

struct QuizResultsView: View {
    let score:        Int
    let total:        Int
    let wrongAnswers: [WrongAnswer]   // ← NEW: session mistakes
    let onReturnToMenu: () -> Void

    @State private var showingReview = false

    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((Double(score) / Double(total)) * 100)
    }

    private var grade: (label: String, color: Color) {
        switch percentage {
        case 90...: return ("Excellent", .green)
        case 70...: return ("Good",      .blue)
        case 50...: return ("Pass",      .orange)
        default:    return ("Try Again", .red)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // ── Grade badge ──
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundColor(grade.color)

                Text("Quiz Complete")
                    .font(.largeTitle.bold())

                VStack(spacing: 8) {
                    Text("\(score) / \(total)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(grade.color)

                    Text("\(percentage)%  ·  \(grade.label)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(grade.color.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)

                // ── Wrong answers section ──
                if !wrongAnswers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("\(wrongAnswers.count) question\(wrongAnswers.count == 1 ? "" : "s") to review",
                                  systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Spacer()
                            Button(showingReview ? "Hide" : "Show") {
                                withAnimation { showingReview.toggle() }
                            }
                            .font(.subheadline.bold())
                        }
                        .padding(.horizontal)

                        if showingReview {
                            ForEach(wrongAnswers) { w in
                                WrongAnswerCard(wrong: w)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.06))
                    .cornerRadius(14)
                    .padding(.horizontal)
                } else {
                    Label("Perfect score — no mistakes!", systemImage: "star.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.yellow)
                }

                // ── Return button ──
                Button(action: onReturnToMenu) {
                    Text("Return to Menu")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Results")
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Wrong Answer Card

struct WrongAnswerCard: View {
    let wrong: WrongAnswer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Chapter / unit label
            HStack(spacing: 6) {
                if !wrong.question.chapter.isEmpty {
                    Text("Ch. \(wrong.question.chapter)")
                        .font(.caption.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(5)
                }
                if !wrong.question.unit.isEmpty {
                    Text("Unit \(wrong.question.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("#\(wrong.question.number)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Question text
            Text(wrong.question.text)
                .font(.subheadline.bold())
                .fixedSize(horizontal: false, vertical: true)

            // All four choices
            VStack(alignment: .leading, spacing: 4) {
                ForEach(["A", "B", "C", "D"], id: \.self) { letter in
                    let text   = wrong.question.option(for: letter)
                    let isCorrect = letter == wrong.question.answer
                    let isChosen  = letter == wrong.chosen

                    HStack(spacing: 6) {
                        Image(systemName: isCorrect
                              ? "checkmark.circle.fill"
                              : (isChosen ? "xmark.circle.fill" : "circle"))
                            .foregroundColor(isCorrect ? .green : (isChosen ? .red : .secondary))
                            .font(.system(size: 14))

                        Text("\(letter): \(text)")
                            .font(.caption)
                            .foregroundColor(isCorrect ? .green : (isChosen ? .red : .primary))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.18), lineWidth: 1)
        )
    }
}
