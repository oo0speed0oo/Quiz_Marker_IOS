import SwiftUI

struct MainMenuView: View {
    @State private var store   = QuizStore()
    @State private var path    = NavigationPath()
    @State private var manager = QuizManager()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(destination: StudyMenuView(path: $path, store: store, manager: manager)) {
                    Label("Study", systemImage: "book.fill")
                        .font(.title3.bold())
                        .padding(.vertical, 6)
                }

                NavigationLink(destination: FlashcardFileSelectView(path: $path, store: store)) {
                    Label("Flashcards", systemImage: "rectangle.stack.fill")
                        .font(.title3.bold())
                        .padding(.vertical, 6)
                }

                NavigationLink(destination: ScoresView(store: store)) {
                    Label("View Scores", systemImage: "chart.bar.fill")
                        .font(.title3.bold())
                        .padding(.vertical, 6)
                }

                NavigationLink(destination: StudyTimesView(store: store)) {
                    Label("View Study Times", systemImage: "clock.fill")
                        .font(.title3.bold())
                        .padding(.vertical, 6)
                }

                NavigationLink(destination: GrammarRulesView()) {
                    Label("Rules", systemImage: "text.book.closed.fill")
                        .font(.title3.bold())
                        .padding(.vertical, 6)
                }

                NavigationLink(destination: NotesListView(store: store)) {
                    HStack {
                        Label("Notes", systemImage: "note.text")
                            .font(.title3.bold())
                            .padding(.vertical, 6)

                        Spacer()

                        if !store.notes.isEmpty {
                            Text("\(store.notes.count)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.indigo)
                                .cornerRadius(10)
                        }
                    }
                }

                NavigationLink(destination: BookmarksView(store: store)) {
                    HStack {
                        Label("Bookmarks", systemImage: "bookmark.fill")
                            .font(.title3.bold())
                            .padding(.vertical, 6)

                        Spacer()

                        if !store.bookmarks.isEmpty {
                            Text("\(store.bookmarks.count)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.yellow)
                                .cornerRadius(10)
                        }
                    }
                }
                .foregroundColor(store.bookmarks.isEmpty ? .secondary : .primary)

                // ── NEW: Review mistakes ──
                NavigationLink(destination: WrongAnswersReviewView(store: store)) {
                    HStack {
                        Label("Review Mistakes", systemImage: "exclamationmark.triangle.fill")
                            .font(.title3.bold())
                            .padding(.vertical, 6)

                        Spacer()

                        // Badge showing total saved mistakes
                        if !store.wrongAnswers.isEmpty {
                            Text("\(store.wrongAnswers.count)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                }
                .foregroundColor(store.wrongAnswers.isEmpty ? .secondary : .primary)
            }
            .navigationTitle("Quiz Marker")
            .navigationDestination(for: QuizRoute.self) { route in
                routeDestination(for: route)
            }
        }
    }

    // MARK: - Quiz Route Destinations

    @ViewBuilder
    private func routeDestination(for route: QuizRoute) -> some View {
        switch route {
        case .unitSelection(let f):
            UnitSelectionView(path: $path, file: f)

        case .chapterSelection(let f, let u):
            ChapterSelectionView(path: $path, file: f, units: u, store: store)  // ← store passed in

        case .questionCount(let f, let u, let c):
            QuestionCountView(path: $path, file: f, units: u, chapters: c)

        case .activeQuiz(let f, let u, let c, let l):
            QuizView(
                path: $path,
                manager: manager,
                store: store,
                file: f,
                units: u,
                chapters: c,
                limit: l
            )

        case .reviewMistakes:
            ReviewMistakesQuizView(path: $path, store: store)

        case .flashcardUnitSelection(let f):
            FlashcardUnitSelectionView(path: $path, file: f, store: store)

        case .flashcardChapterSelection(let f, let u):
            FlashcardChapterSelectionView(path: $path, file: f, units: u, store: store)

        case .flashcards(let f, let u, let c):
            FlashcardView(file: f, units: u, chapters: c, store: store)
        }
    }
}
