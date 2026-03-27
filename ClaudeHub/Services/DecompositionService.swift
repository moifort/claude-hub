import Foundation
import FoundationModels

@Generable(description: "A subtask that can be executed independently in an isolated git worktree")
struct SubtaskDescriptor {
    @Guide(description: "Short title for display, max 60 characters")
    var title: String

    @Guide(description: "One-sentence summary of what this subtask accomplishes")
    var summary: String

    @Guide(description: "Detailed, self-contained prompt for Claude Code with specific files, patterns, and acceptance criteria")
    var prompt: String
}

@Generable(description: "Result of analyzing whether a task should be decomposed into independent parallel subtasks")
struct DecompositionResult {
    @Guide(description: "True if the task benefits from being split into independent parallel subtasks, false for simple or tightly-coupled tasks")
    var shouldDecompose: Bool

    @Guide(description: "The list of subtasks. Contains exactly 1 item when shouldDecompose is false")
    var subtasks: [SubtaskDescriptor]
}

enum DecompositionService {
    static func decompose(prompt: String) async -> DecompositionResult {
        do {
            let session = LanguageModelSession {
                """
                You are a task planner for a coding project. Decide if the task should be split \
                into independent subtasks that can run in parallel in isolated git worktrees. \
                Set shouldDecompose to false for simple, single-concern tasks. \
                Each subtask prompt must be fully self-contained with specific instructions.
                """
            }
            let response = try await session.respond(to: prompt, generating: DecompositionResult.self)
            let result = response.content
            guard !result.subtasks.isEmpty else {
                return await fallbackSingle(prompt: prompt)
            }
            return result
        } catch {
            return await fallbackSingle(prompt: prompt)
        }
    }

    private static func fallbackSingle(prompt: String) async -> DecompositionResult {
        let title = await SummarizationService.summarize(prompt: prompt)
        return DecompositionResult(
            shouldDecompose: false,
            subtasks: [SubtaskDescriptor(title: title, summary: title, prompt: prompt)]
        )
    }
}
