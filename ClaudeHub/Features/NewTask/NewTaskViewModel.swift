import Foundation
import SwiftData

@Observable @MainActor
final class NewTaskViewModel {
    var prompt = ""
    var isDecomposing = false
    var subtaskCount: Int?
    var errorMessage: String?

    var canSubmit: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDecomposing
    }

    func decompose(for project: Project, in context: ModelContext) async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        isDecomposing = true
        errorMessage = nil
        subtaskCount = nil

        do {
            let decomposed = try await CLIService.decomposeTask(
                prompt: trimmedPrompt,
                projectPath: project.path
            )
            createTasks(from: decomposed, parentPrompt: trimmedPrompt, project: project, in: context)
            subtaskCount = decomposed.count
        } catch {
            // Fallback: create a single task with the original prompt
            let slug = TaskItem.generateSlug(from: trimmedPrompt.prefix(50).description)
            let task = TaskItem(
                title: String(trimmedPrompt.prefix(80)),
                prompt: trimmedPrompt,
                slug: slug,
                project: project
            )
            context.insert(task)
            subtaskCount = 1
            errorMessage = "Decomposition failed — created single task"
        }

        isDecomposing = false
    }

    func reset() {
        prompt = ""
        isDecomposing = false
        subtaskCount = nil
        errorMessage = nil
    }

    private func createTasks(
        from decomposed: [DecomposedTask],
        parentPrompt: String,
        project: Project,
        in context: ModelContext
    ) {
        let parentTitle = String(parentPrompt.prefix(80))

        for item in decomposed {
            let slug = TaskItem.generateSlug(from: item.title)
            let task = TaskItem(
                title: item.title,
                prompt: item.prompt,
                slug: slug,
                parentTaskTitle: parentTitle,
                project: project
            )
            context.insert(task)
        }
    }
}
