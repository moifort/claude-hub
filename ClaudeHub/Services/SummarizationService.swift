import Foundation
import FoundationModels

enum SummarizationService {
    static func summarize(prompt: String) async -> String {
        do {
            let session = LanguageModelSession {
                """
                Summarize the following task description in one short sentence (max 80 characters). \
                Use the same language as the input. Output only the summary, nothing else.
                """
            }
            let response = try await session.respond(to: prompt)
            let summary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return summary.isEmpty ? heuristicTitle(from: prompt) : String(summary.prefix(100))
        } catch {
            return heuristicTitle(from: prompt)
        }
    }

    static func heuristicTitle(from prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if let dotIndex = trimmed.firstIndex(of: "."), dotIndex < trimmed.index(trimmed.startIndex, offsetBy: min(80, trimmed.count)) {
            return String(trimmed[...dotIndex])
        }
        if let newlineIndex = trimmed.firstIndex(of: "\n"), newlineIndex < trimmed.index(trimmed.startIndex, offsetBy: min(80, trimmed.count)) {
            return String(trimmed[..<newlineIndex])
        }
        return String(trimmed.prefix(80))
    }
}
