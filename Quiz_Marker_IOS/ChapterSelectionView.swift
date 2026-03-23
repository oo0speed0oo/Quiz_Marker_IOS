import SwiftUI

struct ChapterSelectionView: View {
    @Binding var path: NavigationPath
    let file: String
    let units: [String]
    let store: QuizStore   // ← NEW: needed for wrong-answer badges

    @State private var chapters: [String] = []
    @State private var selectedChapters: Set<String> = []
    @State private var isLoading = true

    var allSelected: Bool { selectedChapters.count == chapters.count }

    private var quizName: String {
        file.replacingOccurrences(of: ".csv", with: "").capitalized
    }

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                Spacer()
                ProgressView("Searching for chapters…")
                Spacer()
            } else {
                selectAllButton
                chapterList
            }

            continueButton
        }
        .navigationTitle("Select Chapters")
        .onAppear(perform: loadChapters)
    }

    // MARK: - Subviews

    private var selectAllButton: some View {
        HStack {
            Spacer()
            Button(allSelected ? "Deselect All" : "Select All") {
                selectedChapters = allSelected ? [] : Set(chapters)
            }
            .font(.subheadline)
            .padding(.horizontal)
        }
    }

    private var chapterList: some View {
        List(chapters, id: \.self) { chapter in
            Button {
                if selectedChapters.contains(chapter) {
                    selectedChapters.remove(chapter)
                } else {
                    selectedChapters.insert(chapter)
                }
            } label: {
                HStack {
                    Image(systemName: selectedChapters.contains(chapter) ? "checkmark.square.fill" : "square")
                        .foregroundColor(selectedChapters.contains(chapter) ? .blue : .secondary)
                        .font(.system(size: 20))

                    Text("Chapter \(chapter)")
                        .foregroundColor(.primary)

                    Spacer()

                    // ── Wrong answer badge ──
                    let wrongCount = store.wrongCount(for: chapter, quizName: quizName)
                    if wrongCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                            Text("\(wrongCount)")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(10)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var continueButton: some View {
        Button {
            let sorted = Array(selectedChapters).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            path.append(QuizRoute.questionCount(file: file, units: units, chapters: sorted))
        } label: {
            Text("Continue")
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedChapters.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(selectedChapters.isEmpty)
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Data

    private func loadChapters() {
        DispatchQueue.global(qos: .userInitiated).async {
            let found = QuizDataService(file: file)?.chapters(inUnits: units) ?? []
            DispatchQueue.main.async {
                isLoading = false
                if found.isEmpty {
                    path.append(QuizRoute.questionCount(file: file, units: units, chapters: []))
                } else {
                    chapters = found
                }
            }
        }
    }
}
