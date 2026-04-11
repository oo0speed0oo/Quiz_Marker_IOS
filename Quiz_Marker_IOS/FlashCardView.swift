import SwiftUI

// MARK: - File Select

private let flashcardHiddenFiles: Set<String> = ["grammar_rules.csv", "quiz_scores.csv"]

struct FlashcardFileSelectView: View {
    @Binding var path: NavigationPath
    let store: QuizStore
    @State private var files: [String] = []

    var body: some View {
        List(files, id: \.self) { file in
            Button(displayName(for: file)) {
                path.append(QuizRoute.flashcardUnitSelection(file: file))
            }
            .foregroundColor(.primary)
        }
        .navigationTitle("Flashcards")
        .onAppear(perform: loadFiles)
    }

    private func loadFiles() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "csv", subdirectory: nil) else { return }
        files = urls.map { $0.lastPathComponent }
            .filter { !flashcardHiddenFiles.contains($0) }
            .sorted()
    }

    private func displayName(for file: String) -> String {
        file.replacingOccurrences(of: ".csv", with: "").capitalized
    }
}

// MARK: - Unit Select (Flashcard)

struct FlashcardUnitSelectionView: View {
    @Binding var path: NavigationPath
    let file: String
    let store: QuizStore

    @State private var units:         [String]    = []
    @State private var selectedUnits: Set<String> = []
    @State private var isLoading = true

    var allSelected: Bool { selectedUnits.count == units.count }

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                Spacer()
                ProgressView("Searching for units…")
                Spacer()
            } else if units.isEmpty {
                Spacer()
                Text("This file has no unit structure.")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                HStack {
                    Spacer()
                    Button(allSelected ? "Deselect All" : "Select All") {
                        selectedUnits = allSelected ? [] : Set(units)
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                }

                List(units, id: \.self) { unit in
                    Button {
                        if selectedUnits.contains(unit) { selectedUnits.remove(unit) }
                        else { selectedUnits.insert(unit) }
                    } label: {
                        HStack {
                            Image(systemName: selectedUnits.contains(unit)
                                  ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedUnits.contains(unit) ? .blue : .secondary)
                                .font(.system(size: 20))
                            Text("Unit \(unit)").foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                let sorted = Array(selectedUnits).sorted()
                path.append(QuizRoute.flashcardChapterSelection(file: file, units: sorted))
            } label: {
                Text("Continue to Chapters")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedUnits.isEmpty && !units.isEmpty ? Color.gray : Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedUnits.isEmpty && !units.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Select Units")
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                let found = QuizDataService(file: file)?.allUnits ?? []
                DispatchQueue.main.async {
                    isLoading = false
                    units     = found
                }
            }
        }
    }
}

// MARK: - Chapter Select (Flashcard)

struct FlashcardChapterSelectionView: View {
    @Binding var path: NavigationPath
    let file: String
    let units: [String]
    let store: QuizStore

    @State private var chapters:         [String]    = []
    @State private var selectedChapters: Set<String> = []
    @State private var isLoading = true

    var allSelected: Bool { selectedChapters.count == chapters.count }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                Spacer()
                ProgressView("Searching for chapters…")
                Spacer()
            } else {
                HStack {
                    Spacer()
                    Button(allSelected ? "Deselect All" : "Select All") {
                        selectedChapters = allSelected ? [] : Set(chapters)
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                }

                List(chapters, id: \.self) { chapter in
                    Button {
                        if selectedChapters.contains(chapter) { selectedChapters.remove(chapter) }
                        else { selectedChapters.insert(chapter) }
                    } label: {
                        HStack {
                            Image(systemName: selectedChapters.contains(chapter)
                                  ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedChapters.contains(chapter) ? .indigo : .secondary)
                                .font(.system(size: 20))

                            Text("Chapter \(chapter)").foregroundColor(.primary)

                            Spacer()

                            if let progress = store.flashcardProgress(fileName: file, chapter: chapter) {
                                VStack(alignment: .trailing, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 11))
                                        Text("Done ×\(progress.reviewCount)")
                                            .font(.caption.bold())
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green)
                                    .cornerRadius(10)

                                    Text(dateFormatter.string(from: progress.lastReviewed))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                let sorted = Array(selectedChapters).sorted {
                    $0.localizedStandardCompare($1) == .orderedAscending
                }
                path.append(QuizRoute.flashcards(file: file, units: units, chapters: sorted))
            } label: {
                Text("Start Flashcards")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedChapters.isEmpty ? Color.gray : Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedChapters.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Select Chapters")
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                let found = QuizDataService(file: file)?.chapters(inUnits: units) ?? []
                DispatchQueue.main.async {
                    isLoading = false
                    chapters  = found
                }
            }
        }
    }
}

// MARK: - Flashcard Viewer

struct FlashcardView: View {
    let file:     String
    let units:    [String]
    let chapters: [String]
    let store:    QuizStore

    @State private var cards:          [Question] = []
    @State private var index           = 0
    @State private var isFlipped       = false
    @State private var isShuffled      = true
    @State private var isLoading       = true
    @State private var showingComplete = false
    @State private var showingSummary  = false

    // Per-session tracking
    @State private var gotItIDs:       Set<UUID> = []   // cards marked "Got it"
    @State private var stillLearningCards: [Question] = []  // cards marked "Still learning"

    private var current: Question? {
        guard !cards.isEmpty, index < cards.count else { return nil }
        return cards[index]
    }

    private var fileName: String {
        file.replacingOccurrences(of: ".csv", with: "").capitalized
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView("Loading cards…")
                Spacer()
            } else if cards.isEmpty {
                Spacer()
                Text("No cards found for the selected filters.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else if showingSummary {
                summaryView
            } else if let card = current {
                progressBar
                completionBanner
                Spacer()
                flashcard(for: card)
                    .padding(.horizontal, 20)
                Spacer()

                // Always show rating buttons — no need to flip first
                knowButtons(for: card)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                navButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShuffled.toggle()
                    cards     = isShuffled ? cards.shuffled() : cards
                    index     = 0
                    isFlipped = false
                } label: {
                    Image(systemName: isShuffled ? "shuffle.circle.fill" : "shuffle.circle")
                        .foregroundColor(.indigo)
                }
            }
        }
        .onAppear(perform: loadCards)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color.indigo)
                        .frame(
                            width: cards.isEmpty ? 0 :
                                geo.size.width * CGFloat(index + 1) / CGFloat(cards.count),
                            height: 6
                        )
                        .animation(.easeInOut, value: index)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)

            // Show live session tally in the progress line
            HStack {
                Text("\(index + 1) of \(cards.count)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
                if !gotItIDs.isEmpty || !stillLearningCards.isEmpty {
                    HStack(spacing: 10) {
                        Label("\(gotItIDs.count)", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("\(stillLearningCards.count)", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .font(.caption.bold())
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }

    // MARK: - Completion Banner

    @ViewBuilder
    private var completionBanner: some View {
        if showingComplete {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Deck complete! Saved to your progress.")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.green.opacity(0.12))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
    }

    // MARK: - Flashcard

    @ViewBuilder
    private func flashcard(for card: Question) -> some View {
        ZStack {
            cardFace(
                content:    card.text,
                label:      "Question",
                labelColor: .indigo,
                bgColor:    Color(.systemBackground),
                hint:       "Tap to reveal answer"
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 90 : 0), axis: (x: 0, y: 1, z: 0))

            cardFace(
                content:    "\(card.answer):  \(card.option(for: card.answer))",
                label:      "Answer",
                labelColor: .green,
                bgColor:    Color.green.opacity(0.04),
                hint:       "Swipe left for next · Swipe right for back"
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -90), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) { isFlipped.toggle() }
        }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.width < -80     { advance() }
                else if value.translation.width > 80 { goBack() }
            }
        )
    }

    private func cardFace(content: String, label: String,
                          labelColor: Color, bgColor: Color, hint: String) -> some View {
        VStack(spacing: 16) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(labelColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(labelColor.opacity(0.12))
                .cornerRadius(20)

            Spacer()

            Text(content)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)

            Spacer()

            Text(hint)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 260)
        .background(bgColor)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(labelColor.opacity(0.18), lineWidth: 1.5)
        )
    }

    // MARK: - Know / Don't Know Buttons

    private func knowButtons(for card: Question) -> some View {
        HStack(spacing: 12) {
            // Still learning
            Button {
                markStillLearning(card)
                advance()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Still Learning")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.red.opacity(0.12))
                .foregroundColor(.red)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }

            // Got it
            Button {
                markGotIt(card)
                advance()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Got It!")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.green.opacity(0.12))
                .foregroundColor(.green)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Nav Buttons (Back / Next — no rating)

    private var navButtons: some View {
        HStack(spacing: 16) {
            Button(action: goBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.secondary.opacity(0.12))
                .foregroundColor(.primary)
                .cornerRadius(14)
            }
            .disabled(index == 0)

            Button(action: advance) {
                HStack(spacing: 6) {
                    Text(index + 1 < cards.count ? "Skip" : "Finish")
                    Image(systemName: index + 1 < cards.count
                          ? "chevron.right" : "flag.checkered")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.indigo)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
        }
    }

    // MARK: - Session Summary

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                Image(systemName: stillLearningCards.isEmpty ? "star.fill" : "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(stillLearningCards.isEmpty ? .yellow : .indigo)

                Text("Session Complete!")
                    .font(.largeTitle.bold())

                // Score row
                HStack(spacing: 16) {
                    summaryPill(count: gotItIDs.count,
                                label: "Got It",
                                icon: "checkmark.circle.fill",
                                color: .green)
                    summaryPill(count: stillLearningCards.count,
                                label: "Still Learning",
                                icon: "xmark.circle.fill",
                                color: .red)
                }
                .padding(.horizontal)

                // Still learning list
                if !stillLearningCards.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Saved to Review Mistakes", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        .padding(.horizontal)

                        ForEach(stillLearningCards) { card in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 13))
                                    .padding(.top, 2)
                                Text(card.text)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.06))
                    .cornerRadius(14)
                    .padding(.horizontal)
                } else {
                    Label("Perfect — you knew every card!", systemImage: "star.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.yellow)
                }

                // Drill still-learning cards button
                if !stillLearningCards.isEmpty {
                    Button {
                        drillStillLearning()
                    } label: {
                        Label("Drill Still Learning Cards", systemImage: "arrow.clockwise")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                // Restart full deck
                Button {
                    restartDeck()
                } label: {
                    Label("Restart Full Deck", systemImage: "arrow.counterclockwise")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private func summaryPill(count: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .cornerRadius(14)
    }

    // MARK: - Actions

    private func markGotIt(_ card: Question) {
        gotItIDs.insert(card.id)
        // Remove from still-learning if they previously marked it wrong
        stillLearningCards.removeAll { $0.id == card.id }
    }

    private func markStillLearning(_ card: Question) {
        // Only add once per session
        if !stillLearningCards.contains(where: { $0.id == card.id }) {
            stillLearningCards.append(card)
        }
        gotItIDs.remove(card.id)
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if index + 1 < cards.count {
                index    += 1
                isFlipped = false
            } else {
                finishDeck()
            }
        }
    }

    private func finishDeck() {
        // Mark chapters complete in store
        for chapter in chapters {
            store.markFlashcardChapterComplete(fileName: file, chapter: chapter)
        }
        // Save "still learning" cards to Review Mistakes
        saveStillLearningToMistakes()
        withAnimation { showingSummary = true }
    }

    private func saveStillLearningToMistakes() {
        guard !stillLearningCards.isEmpty else { return }
        let mistakes = stillLearningCards.map { q in
            WrongAnswer(question: q, chosen: "?")
        }
        store.saveWrongAnswers(mistakes, quizName: fileName)
    }

    private func goBack() {
        guard index > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            index          -= 1
            isFlipped       = false
            showingComplete = false
        }
    }

    private func restartDeck() {
        gotItIDs           = []
        stillLearningCards = []
        index              = 0
        isFlipped          = false
        showingSummary     = false
        showingComplete    = false
        if isShuffled { cards = cards.shuffled() }
    }

    private func drillStillLearning() {
        let drill          = stillLearningCards
        gotItIDs           = []
        stillLearningCards = []
        cards              = drill.shuffled()
        index              = 0
        isFlipped          = false
        showingSummary     = false
        showingComplete    = false
    }

    // MARK: - Load

    private func loadCards() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loaded = QuizDataService(file: file)?
                .questions(units: units, chapters: chapters, limit: 0) ?? []
            DispatchQueue.main.async {
                cards     = isShuffled ? loaded.shuffled() : loaded
                isLoading = false
            }
        }
    }
}
