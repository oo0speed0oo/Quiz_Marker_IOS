import SwiftUI

struct NoteEditorView: View {
    let store: QuizStore
    let note:  Note?   // nil = new note

    @Environment(\.dismiss) private var dismiss

    @State private var title:       String = ""
    @State private var noteBody:    String = ""

    // API key prompt
    @State private var showAPIKeySheet    = false
    @State private var apiKeyInput:       String = ""

    // Question generation
    @State private var questionCount:     Int    = 5
    @State private var isGenerating:      Bool   = false
    @State private var generationError:   String?
    @State private var generatedQuestions: [GeneratedQuestion] = []
    @State private var showQuiz:          Bool   = false

    private var isNewNote: Bool { note == nil }
    private var hasContent: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty || !noteBody.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title field
                TextField("Title", text: $title)
                    .font(.title2.bold())
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                Divider()

                // Body
                TextEditor(text: $noteBody)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)

                Divider()

                generateBar
            }
            .navigationTitle(isNewNote ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { saveAndDismiss() }
                }
            }
            .onAppear { loadNote() }
            .sheet(isPresented: $showAPIKeySheet) {
                apiKeySheet
            }
            .sheet(isPresented: $showQuiz) {
                NoteQuizView(questions: generatedQuestions)
            }
        }
    }

    // MARK: - Generate Bar

    private var generateBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Question count picker
                HStack(spacing: 6) {
                    Text("Questions:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("", selection: $questionCount) {
                        ForEach([3, 5, 8, 10], id: \.self) { Text("\($0)") }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                Spacer()

                // Generate button
                Button {
                    handleGenerate()
                } label: {
                    if isGenerating {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating…")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(10)
                    } else {
                        Label("Generate Quiz", systemImage: "sparkles")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(isGenerating || !hasContent)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            if let err = generationError {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - API Key Sheet

    private var apiKeySheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("To generate quiz questions, enter your Anthropic API key. It's stored only on your device.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                SecureField("sk-ant-…", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Text("Get your API key at console.anthropic.com")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showAPIKeySheet = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        ClaudeService.apiKey = apiKeyInput.trimmingCharacters(in: .whitespaces)
                        showAPIKeySheet = false
                        // Retry generation now that we have a key
                        Task { await generate() }
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func loadNote() {
        guard let n = note else { return }
        title    = n.title
        noteBody = n.body
    }

    private func saveAndDismiss() {
        let t = title.trimmingCharacters(in: .whitespaces)
        let b = noteBody.trimmingCharacters(in: .whitespaces)
        if t.isEmpty && b.isEmpty {
            dismiss()
            return
        }
        if let existing = note {
            store.updateNote(id: existing.id, title: t, body: b)
        } else {
            store.addNote(title: t, body: b)
        }
        dismiss()
    }

    private func handleGenerate() {
        guard hasContent else { return }
        if !ClaudeService.hasAPIKey {
            apiKeyInput = ClaudeService.apiKey
            showAPIKeySheet = true
            return
        }
        Task { await generate() }
    }

    private func generate() async {
        guard hasContent else { return }
        isGenerating    = true
        generationError = nil

        // Auto-save before generating so the note isn't lost
        let t = title.trimmingCharacters(in: .whitespaces)
        let b = noteBody.trimmingCharacters(in: .whitespaces)
        let noteText = [t, b].filter { !$0.isEmpty }.joined(separator: "\n\n")

        if !t.isEmpty || !b.isEmpty {
            if let existing = note {
                store.updateNote(id: existing.id, title: t, body: b)
            } else {
                store.addNote(title: t.isEmpty ? "Untitled" : t, body: b)
            }
        }

        do {
            let questions = try await ClaudeService.generateQuestions(from: noteText, count: questionCount)
            generatedQuestions = questions
            showQuiz = true
        } catch {
            generationError = error.localizedDescription
        }

        isGenerating = false
    }
}
