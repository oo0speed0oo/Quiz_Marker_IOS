import SwiftUI

// MARK: - Scores View

struct ScoresView: View {
    let store: QuizStore

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        Group {
            if store.records.isEmpty {
                emptyState(icon: "chart.bar", message: "No scores yet.\nComplete a quiz to see your results here.")
            } else {
                List(store.records) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(record.quizName)
                                .font(.headline)
                            Spacer()
                            gradeLabel(for: record.percentage)
                        }

                        HStack {
                            Label("\(record.score) / \(record.total)", systemImage: "checkmark.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(record.percentage)%")
                                .font(.subheadline.bold())
                                .foregroundColor(gradeColor(for: record.percentage))
                        }

                        Label(dateFormatter.string(from: record.date), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Scores")
    }

    private func gradeLabel(for pct: Int) -> some View {
        let (text, color) = gradeInfo(for: pct)
        return Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    private func gradeInfo(for pct: Int) -> (String, Color) {
        switch pct {
        case 90...: return ("Excellent", .green)
        case 70...: return ("Good",      .blue)
        case 50...: return ("Pass",      .orange)
        default:    return ("Try Again", .red)
        }
    }

    private func gradeColor(for pct: Int) -> Color { gradeInfo(for: pct).1 }
}

// MARK: - Study Times View

struct StudyTimesView: View {
    let store: QuizStore

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        Group {
            if store.sessions.isEmpty {
                emptyState(icon: "clock", message: "No study sessions yet.\nComplete a quiz to start tracking your time.")
            } else {
                List {
                    // ── Cumulative totals per quiz ──
                    Section("Total Time by Quiz") {
                        ForEach(store.cumulativeTimeByQuiz, id: \.name) { entry in
                            HStack {
                                Text(entry.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(formatDuration(entry.seconds))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.teal)
                            }
                        }
                    }

                    // ── Individual sessions ──
                    Section("Session History") {
                        ForEach(store.sessions) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(session.quizName)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(formatDuration(session.durationSeconds))
                                        .font(.subheadline)
                                        .foregroundColor(.teal)
                                }
                                Label(dateFormatter.string(from: session.date), systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Study Times")
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return String(format: "%ds", s)
    }
}

// MARK: - Shared empty state

@ViewBuilder
func emptyState(icon: String, message: String) -> some View {
    VStack(spacing: 16) {
        Spacer()
        Image(systemName: icon)
            .font(.system(size: 52))
            .foregroundColor(.secondary.opacity(0.4))
        Text(message)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        Spacer()
    }
}
