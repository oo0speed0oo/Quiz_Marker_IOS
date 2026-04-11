import SwiftUI

struct BookmarksView: View {
    let store: QuizStore

    @State private var selectedQuiz:    String    = "All"
    @State private var expandedCards:   Set<UUID> = []
    @State private var showingClearConfirm = false

    private var quizNames: [String] {
        let names = Set(store.bookmarks.map { $0.quizName }).sorted()
        return ["All"] + names
    }

    private var filtered: [PersistedBookmark] {
        guard selectedQuiz != "All" else { return store.bookmarks }
        return store.bookmarks.filter { $0.quizName == selectedQuiz }
    }

    private var byChapter: [(chapter: String, items: [PersistedBookmark])] {
        var dict: [String: [PersistedBookmark]] = [:]
        for b in filtered { dict[b.chapter, default: []].append(b) }
        return dict.map { (chapter: $0.key, items: $0.value) }
            .sorted { (Int($0.chapter) ?? 0) < (Int($1.chapter) ?? 0) }
    }

    var body: some View {
        Group {
            if store.bookmarks.isEmpty {
                emptyState(icon: "bookmark",
                           message: "No bookmarks yet.\nTap the Bookmark button on any question to save it here.")
            } else {
                VStack(spacing: 0) {
                    // Quiz filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quizNames, id: \.self) { name in
                                Button(name) { selectedQuiz = name }
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedQuiz == name ? Color.yellow : Color.yellow.opacity(0.15))
                                    .foregroundColor(selectedQuiz == name ? .black : .primary)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }

                    Divider()

                    if filtered.isEmpty {
                        Spacer()
                        Text("No bookmarks for this quiz.")
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    } else {
                        List {
                            ForEach(byChapter, id: \.chapter) { group in
                                Section {
                                    ForEach(group.items) { b in
                                        bookmarkCard(b)
                                    }
                                } header: {
                                    HStack {
                                        Text("Chapter \(group.chapter)")
                                            .font(.subheadline.bold())
                                        Spacer()
                                        Text("\(group.items.count) bookmark\(group.items.count == 1 ? "" : "s")")
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
        .navigationTitle("Bookmarks")
        .toolbar {
            if !store.bookmarks.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") { showingClearConfirm = true }
                        .foregroundColor(.red)
                }
            }
        }
        .confirmationDialog(
            "Clear all bookmarks?",
            isPresented: $showingClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) { store.clearBookmarks() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    // MARK: - Bookmark Card

    @ViewBuilder
    private func bookmarkCard(_ b: PersistedBookmark) -> some View {
        let isExpanded = expandedCards.contains(b.id)

        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded { expandedCards.remove(b.id) }
                    else          { expandedCards.insert(b.id) }
                }
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 15))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(b.questionText)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(isExpanded ? nil : 2)

                        Text("Answer: \(b.correctAnswer)")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        // Remove bookmark button
                        Button {
                            store.removeBookmark(id: b.id)
                        } label: {
                            Image(systemName: "bookmark.slash")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(["A", "B", "C", "D"], id: \.self) { letter in
                        let text      = choiceText(letter, b)
                        let isCorrect = letter == b.correctAnswer
                        HStack(spacing: 6) {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isCorrect ? .green : .secondary)
                                .font(.system(size: 13))
                            Text("\(letter): \(text)")
                                .font(.caption)
                                .foregroundColor(isCorrect ? .green : .primary)
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

    private func choiceText(_ letter: String, _ b: PersistedBookmark) -> String {
        switch letter {
        case "A": return b.choiceA
        case "B": return b.choiceB
        case "C": return b.choiceC
        case "D": return b.choiceD
        default:  return ""
        }
    }
}
