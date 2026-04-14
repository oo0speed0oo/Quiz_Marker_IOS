import Foundation

// MARK: - Generated Question Model

struct GeneratedQuestion: Codable, Identifiable {
    let id = UUID()
    let questionText:  String
    let choiceA:       String
    let choiceB:       String
    let choiceC:       String
    let choiceD:       String
    let correctAnswer: String   // "A", "B", "C", or "D"
    let explanation:   String

    enum CodingKeys: String, CodingKey {
        case questionText  = "question"
        case choiceA       = "choice_a"
        case choiceB       = "choice_b"
        case choiceC       = "choice_c"
        case choiceD       = "choice_d"
        case correctAnswer = "correct_answer"
        case explanation
    }
}

// MARK: - Errors

enum ClaudeServiceError: LocalizedError {
    case missingAPIKey
    case httpError(Int)
    case noContent
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:       return "Enter your Anthropic API key first."
        case .httpError(let code): return "API error (HTTP \(code)). Check your API key."
        case .noContent:           return "Claude returned an empty response."
        case .parseError(let msg): return "Could not parse questions: \(msg)"
        }
    }
}

// MARK: - Service

enum ClaudeService {

    static let apiKeyDefaultsKey = "anthropic_api_key"

    static var apiKey: String {
        get { UserDefaults.standard.string(forKey: apiKeyDefaultsKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyDefaultsKey) }
    }

    static var hasAPIKey: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Calls the Anthropic API and returns multiple-choice questions generated from `noteText`.
    static func generateQuestions(from noteText: String, count: Int = 5) async throws -> [GeneratedQuestion] {
        guard hasAPIKey else { throw ClaudeServiceError.missingAPIKey }

        let prompt = """
        You are a quiz-question generator. Based on the notes below, create exactly \(count) multiple-choice questions to help the user study the material.

        NOTES:
        \(noteText)

        Return ONLY a valid JSON array — no markdown fences, no extra text — using this exact schema:
        [
          {
            "question": "...",
            "choice_a": "...",
            "choice_b": "...",
            "choice_c": "...",
            "choice_d": "...",
            "correct_answer": "A",
            "explanation": "Brief explanation of why the answer is correct."
          }
        ]

        Rules:
        - correct_answer must be exactly one of: A, B, C, D
        - All four choices must be plausible
        - Questions should test understanding, not just recall
        - Output only the JSON array, nothing else
        """

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 2048,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json",    forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey,                forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",          forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ClaudeServiceError.httpError(http.statusCode)
        }

        // Unwrap Anthropic response envelope
        struct AnthropicResponse: Decodable {
            struct Content: Decodable { let text: String }
            let content: [Content]
        }

        let envelope = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        guard let rawText = envelope.content.first?.text else {
            throw ClaudeServiceError.noContent
        }

        let jsonString = extractJSONArray(from: rawText)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ClaudeServiceError.parseError("UTF-8 encoding failed")
        }

        do {
            return try JSONDecoder().decode([GeneratedQuestion].self, from: jsonData)
        } catch {
            throw ClaudeServiceError.parseError(error.localizedDescription)
        }
    }

    // Strip any markdown fences Claude might have included despite instructions.
    private static func extractJSONArray(from text: String) -> String {
        // Try ```json ... ```
        if let s = text.range(of: "```json\n")?.upperBound,
           let e = text.range(of: "\n```", range: s..<text.endIndex)?.lowerBound {
            return String(text[s..<e])
        }
        // Try ``` ... ```
        if let s = text.range(of: "```\n")?.upperBound,
           let e = text.range(of: "\n```", range: s..<text.endIndex)?.lowerBound {
            return String(text[s..<e])
        }
        // Fall back to finding the first [ … last ]
        if let s = text.firstIndex(of: "["),
           let e = text.lastIndex(of: "]") {
            return String(text[s...e])
        }
        return text
    }
}
