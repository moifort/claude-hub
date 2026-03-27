import Foundation
import FoundationModels

@Generable
struct TaskSplitResult {
    @Guide(description: "Each individual task extracted from the input. If the input is a single task with line breaks, return it as one element.")
    var tasks: [String]
}

enum SummarizationService {

    static func splitTasks(from prompt: String) async -> [String] {
        guard prompt.contains("\n") else { return [prompt] }

        do {
            let session = LanguageModelSession {
                """
                Analyze the following text and determine if it contains multiple separate tasks or requests. \
                If it contains multiple distinct tasks separated by line breaks, split them into individual tasks. \
                If it is a single task that happens to span multiple lines, return it as one element. \
                Preserve the original language and wording of each task.
                """
            }
            let response = try await session.respond(to: prompt, generating: TaskSplitResult.self)
            let tasks = response.content.tasks
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return tasks.isEmpty ? [prompt] : tasks
        } catch {
            return [prompt]
        }
    }
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
