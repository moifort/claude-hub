import Foundation
import SwiftData

@Observable @MainActor
final class InlineTaskInputViewModel {
    var prompt = ""
    private(set) var isDecomposing = false
    private(set) var subtaskCount: Int?
    private(set) var errorMessage: String?

    var canSubmit: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDecomposing
    }

    func submit(
        project: Project,
        context: ModelContext,
        sessionManager: TerminalSessionManager,
        taskViewModel: TaskListViewModel,
        appModel: AppModel
    ) async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isDecomposing = true
        errorMessage = nil
        subtaskCount = nil

        let tasks: [TaskItem]
        do {
            let decomposed = try await CLIService.decomposeTask(
                prompt: trimmed,
                projectPath: project.path
            )
            tasks = decomposed.map { item in
                let slug = TaskItem.generateSlug(from: item.title)
                let task = TaskItem(
                    title: item.title,
                    prompt: item.prompt,
                    slug: slug,
                    summary: item.summary,
                    parentTaskTitle: String(trimmed.prefix(80)),
                    project: project
                )
                context.insert(task)
                return task
            }
            subtaskCount = decomposed.count
        } catch {
            let slug = TaskItem.generateSlug(from: String(trimmed.prefix(50)))
            let task = TaskItem(
                title: String(trimmed.prefix(80)),
                prompt: trimmed,
                slug: slug,
                project: project
            )
            context.insert(task)
            tasks = [task]
            subtaskCount = 1
            errorMessage = error.localizedDescription
        }

        isDecomposing = false

        for task in tasks {
            await taskViewModel.launchTask(task, sessionManager: sessionManager)
        }

        if let first = tasks.first {
            appModel.selectedItemID = first.persistentModelID
        }

        prompt = ""
        subtaskCount = nil
        errorMessage = nil
    }
}
