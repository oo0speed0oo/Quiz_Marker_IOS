import SwiftUI

struct GrammarRulesView: View {
    @State private var chapters:         [GrammarChapter] = []
    @State private var isLoading         = true
    @State private var expandedChapters: Set<String> = []

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading rules…")
            } else if chapters.isEmpty {
                emptyState(icon: "book.closed", message: "No grammar rules found.\nMake sure grammar_rules.csv is in your project.")
            } else {
                List(chapters) { chapter in
                    chapterRow(chapter)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Grammar Rules")
        .onAppear(perform: loadRules)
    }

    // MARK: - Chapter Row

    @ViewBuilder
    private func chapterRow(_ chapter: GrammarChapter) -> some View {
        let isExpanded = expandedChapters.contains(chapter.number)

        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedChapters.remove(chapter.number)
                    } else {
                        expandedChapters.insert(chapter.number)
                    }
                }
            } label: {
                HStack {
                    Text("Chapter \(chapter.number)")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    styledText(chapter.rule, font: .system(size: 14, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)

                    if !chapter.more.isEmpty {
                        styledText(chapter.more, font: .system(size: 13, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.purple.opacity(0.08))
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Load

    private func loadRules() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loaded = parseGrammarRules()
            DispatchQueue.main.async {
                chapters  = loaded
                isLoading = false
            }
        }
    }

    private func parseGrammarRules() -> [GrammarChapter] {
        guard
            let path    = Bundle.main.path(forResource: "grammar_rules", ofType: "csv"),
            let content = try? String(contentsOfFile: path, encoding: .utf8)
        else { return [] }

        let rows = CSVParser.parseRows(content).dropFirst()

        var seen:   Set<String>      = []
        var result: [GrammarChapter] = []

        for cols in rows {
            guard cols.count >= 3 else { continue }
            let chapterNum = cols[1].trimmed
            let rule       = cols[2].trimmed
            let more       = cols.count >= 4 ? cols[3].trimmed : ""

            guard !chapterNum.isEmpty, !rule.isEmpty else { continue }
            guard !seen.contains(chapterNum) else { continue }  // one entry per chapter
            seen.insert(chapterNum)

            result.append(GrammarChapter(number: chapterNum, rule: rule, more: more))
        }

        // Sort numerically so 2 comes before 10
        return result.sorted {
            (Int($0.number) ?? 0) < (Int($1.number) ?? 0)
        }
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
}

// MARK: - Model

struct GrammarChapter: Identifiable {
    let id     = UUID()
    let number: String
    let rule:   String
    let more:   String
}
