import SwiftUI

struct QuestionCountView: View {
    @Binding var path: NavigationPath
    let file: String
    let units: [String]
    let chapters: [String]

    @State private var totalAvailable: Int? = nil
    @State private var selectedAmount = 1
    @State private var amountString = "1"
    @FocusState private var isInputActive: Bool

    var body: some View {
        VStack(spacing: 30) {
            Text("How many questions?")
                .font(.headline)

            stateView

            Button("Start Quiz") {
                path.append(QuizRoute.activeQuiz(
                    file: file, units: units, chapters: chapters, limit: selectedAmount
                ))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedAmount < 1 || totalAvailable == nil || totalAvailable == 0)
        }
        .navigationTitle("Questions")
        .onAppear(perform: countQuestions)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { commitTextField(); isInputActive = false }
            }
        }
    }

    // MARK: - State Views

    @ViewBuilder
    private var stateView: some View {
        switch totalAvailable {
        case nil:
            VStack(spacing: 8) {
                ProgressView()
                Text("Counting matching questions…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case 0:
            Text("No questions found for the selected filters.")
                .font(.subheadline)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

        default:
            let total = totalAvailable!
            VStack(spacing: 16) {
                Text("\(total) questions available")
                    .font(.subheadline)
                    .foregroundColor(.green)

                // Stepper — always works, no keyboard needed
                Stepper(value: $selectedAmount, in: 1...total) {
                    Text("\(selectedAmount) questions")
                        .font(.title2.bold())
                }
                .padding(.horizontal, 40)
                .onChange(of: selectedAmount) { _, newValue in
                    // Keep text field in sync when stepper changes
                    amountString = "\(newValue)"
                }

                // Text field — lets you type a specific number directly
                HStack {
                    Text("Or type:")
                        .foregroundColor(.secondary)
                    TextField("", text: $amountString)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .frame(width: 80)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .focused($isInputActive)
                        // Only commit when the user finishes typing (focus lost),
                        // NOT on every keystroke — this prevents the rewrite loop.
                        .onSubmit { commitTextField() }
                }
                .font(.title3)
            }
        }
    }

    // MARK: - Logic

    /// Called when the user dismisses the keyboard or submits.
    /// Updates selectedAmount from whatever is in amountString.
    /// Does NOT rewrite amountString — that was the loop.
    private func commitTextField() {
        guard let total = totalAvailable else { return }
        let digits = amountString.filter { $0.isNumber }
        if let entered = Int(digits), entered >= 1 {
            selectedAmount = min(entered, total)
        } else {
            selectedAmount = max(1, min(selectedAmount, total))
        }
        amountString = "\(selectedAmount)"
    }

    private func countQuestions() {
        DispatchQueue.global(qos: .userInitiated).async {
            let count = QuizDataService(file: file)?.questionCount(units: units, chapters: chapters) ?? 0
            DispatchQueue.main.async {
                totalAvailable = count
                selectedAmount = min(selectedAmount, count)
                amountString   = "\(selectedAmount)"
            }
        }
    }
}
