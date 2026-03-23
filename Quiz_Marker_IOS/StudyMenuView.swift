import SwiftUI

// Files that exist only for internal app use — never shown to the user.
private let hiddenFiles: Set<String> = ["grammar_rules.csv", "quiz_scores.csv"]

struct StudyMenuView: View {
    @Binding var path: NavigationPath
    let store: QuizStore
    let manager: QuizManager

    @State private var quizFiles: [String] = []

    var body: some View {
        List {
            // ── Review Mistakes entry (only shown when there are saved mistakes) ──
            if !store.wrongAnswers.isEmpty {
                Button {
                    path.append(QuizRoute.reviewMistakes)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Review Mistakes")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(store.wrongAnswers.count) question\(store.wrongAnswers.count == 1 ? "" : "s") to clear")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        // Red badge count
                        Text("\(store.wrongAnswers.count)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.vertical, 4)
                }
            }

            // ── Normal quiz files ──
            ForEach(quizFiles, id: \.self) { file in
                Button(displayName(for: file)) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let hasUnits = !(QuizDataService(file: file)?.allUnits.isEmpty ?? true)
                        DispatchQueue.main.async {
                            if hasUnits {
                                path.append(QuizRoute.unitSelection(file: file))
                            } else {
                                path.append(QuizRoute.chapterSelection(file: file, units: []))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Quiz")
        .onAppear(perform: loadFiles)
    }

    // MARK: - Helpers

    private func loadFiles() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "csv", subdirectory: nil) else { return }
        quizFiles = urls
            .map { $0.lastPathComponent }
            .filter { !hiddenFiles.contains($0) }
            .sorted()
    }

    private func displayName(for file: String) -> String {
        file.replacingOccurrences(of: ".csv", with: "").capitalized
    }
}
