import SwiftUI

struct NotesListView: View {
    let store: QuizStore

    @State private var showingNewNote  = false
    @State private var editingNote:    Note? = nil

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        Group {
            if store.notes.isEmpty {
                emptyState
            } else {
                notesList
            }
        }
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingNewNote = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingNewNote) {
            NoteEditorView(store: store, note: nil)
        }
        .sheet(item: $editingNote) { note in
            NoteEditorView(store: store, note: note)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "note.text")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("No notes yet")
                .font(.title3.bold())
            Text("Tap the pencil icon to write your first note.\nYou can then generate quiz questions from it.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Notes List

    private var notesList: some View {
        List {
            ForEach(store.notes) { note in
                Button {
                    editingNote = note
                } label: {
                    noteRow(note)
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                indexSet.forEach { store.deleteNote(id: store.notes[$0].id) }
            }
        }
    }

    private func noteRow(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(.headline)
                .lineLimit(1)

            if !note.body.isEmpty {
                Text(note.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Text(Self.dateFormatter.string(from: note.updatedAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
