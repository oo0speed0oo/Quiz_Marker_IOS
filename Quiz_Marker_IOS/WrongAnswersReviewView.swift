import SwiftUI

/// A screen reachable from MainMenuView that lets users browse all previously wrong answers,
/// filtered by quiz and chapter. They can clear the list when they feel confident.
struct WrongAnswersReviewView: View {
    let store: QuizStore

    @State private var selectedQuiz: String = "All"
    @State private var expandedCards: Set<UUID> = []
    @State private var showingClearConfirm = false

    private var quizNames: [String] {
        let names = Set(store.wrongAnswers.map { $0.quizName }).sorted()
        return ["All"] + names
    }

    private var filtered: [PersistedWrongAnswer] {
        guard selectedQuiz != "All" else { return store.wrongAnswers }
        return store.wrongAnswers.filter { $0.quizName == selectedQuiz }
    }

    /// Group filtered answers by chapter
    private var byChapter: [(chapter: String, items: [PersistedWrongAnswer])] {
        var dict: [String: [PersistedWrongAnswer]] = [:]
        for w in filtered {
            dict[w.chapter, default: []].append(w)
        }
        return dict.map { (chapter: $0.key, items: $0.value) }
            .sorted { (Int($0.chapter) ?? 0) < (Int($1.chapter) ?? 0) }
    }

    var body: some View {
        Group {
            if store.wrongAnswers.isEmpty {
                emptyState(icon: "checkmark.seal.fill",
                           message: "No wrong answers saved yet.\nComplete a quiz to start tracking mistakes.")
            } else {
                VStack(spacing: 0) {
                    // ── Quiz picker ──
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quizNames, id: \.self) { name in
                                Button(name) { selectedQuiz = name }
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedQuiz == name ? Color.blue : Color.blue.opacity(0.1))
                                    .foregroundColor(selectedQuiz == name ? .white : .blue)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }

                    Divider()

                    // ── Chapter groups ──
                    if filtered.isEmpty {
                        Spacer()
                        Text("No mistakes for this quiz.")
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    } else {
                        List {
                            ForEach(byChapter, id: \.chapter) { group in
                                Section {
                                    ForEach(group.items) { w in
                                        persistedWrongCard(w)
                                    }
                                } header: {
                                    HStack {
                                        Text("Chapter \(group.chapter)")
                                            .font(.subheadline.bold())
                                        Spacer()
                                        Text("\(group.items.count) mistake\(group.items.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
        }
        .navigationTitle("Review Mistakes")
        .toolbar {
            if !store.wrongAnswers.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") { showingClearConfirm = true }
                        .foregroundColor(.red)
                }
            }
        }
        .confirmationDialog(
            "Clear all saved mistakes?",
            isPresented: $showingClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) { store.clearWrongAnswers() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    // MARK: - Persisted Wrong Answer Card

    @ViewBuilder
    private func persistedWrongCard(_ w: PersistedWrongAnswer) -> some View {
        let isExpanded = expandedCards.contains(w.id)

        VStack(alignment: .leading, spacing: 6) {
            // Header row — always visible
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded { expandedCards.remove(w.id) }
                    else { expandedCards.insert(w.id) }
                }
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.questionText)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(isExpanded ? nil : 2)

                        HStack(spacing: 6) {
                            Text("You: \(w.chosenAnswer)")
                                .foregroundColor(.red)
                            Text("·")
                                .foregroundColor(.secondary)
                            Text("Correct: \(w.correctAnswer)")
                                .foregroundColor(.green)
                        }
                        .font(.caption.bold())
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Expanded choices
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    let choices = ["A": w.choiceA, "B": w.choiceB, "C": w.choiceC, "D": w.choiceD]
                    ForEach(["A", "B", "C", "D"], id: \.self) { letter in
                        let text      = choices[letter] ?? ""
                        let isCorrect = letter == w.correctAnswer
                        let isChosen  = letter == w.chosenAnswer

                        HStack(spacing: 6) {
                            Image(systemName: isCorrect
                                  ? "checkmark.circle.fill"
                                  : (isChosen ? "xmark.circle.fill" : "circle"))
                                .foregroundColor(isCorrect ? .green : (isChosen ? .red : .secondary))
                                .font(.system(size: 13))

                            Text("\(letter): \(text)")
                                .font(.caption)
                                .foregroundColor(isCorrect ? .green : (isChosen ? .red : .primary))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.leading, 24)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}
