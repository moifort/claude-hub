import Foundation
import SwiftData

@Observable @MainActor
final class InlineTaskInputViewModel {
    var prompt = ""
    private(set) var isProcessing = false
    private(set) var activeMode: ProcessingMode = .summarizing
    private(set) var errorMessage: String?

    enum ProcessingMode {
        case summarizing, decomposing
    }

    var canSubmit: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }

    var statusMessage: String? {
        guard isProcessing else { return nil }
        return activeMode == .decomposing ? "Decomposing..." : "Summarizing..."
    }

    func submit(
        project: Project,
        context: ModelContext,
        sessionManager: TerminalSessionManager,
        taskViewModel: TaskListViewModel,
        appModel: AppModel,
        decompositionEnabled: Bool
    ) async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isProcessing = true
        activeMode = decompositionEnabled ? .decomposing : .summarizing
        errorMessage = nil

        let tasks: [TaskItem]

        if decompositionEnabled {
            let result = await DecompositionService.decompose(prompt: trimmed)
            tasks = result.subtasks.map { subtask in
                let slug = TaskItem.generateSlug(from: subtask.title)
                return TaskItem(
                    title: subtask.title,
                    prompt: subtask.prompt,
                    slug: slug,
                    summary: subtask.summary,
                    parentTaskTitle: result.shouldDecompose ? String(trimmed.prefix(80)) : nil,
                    project: project
                )
            }
        } else {
            let title = await SummarizationService.summarize(prompt: trimmed)
            let slug = TaskItem.generateSlug(from: title)
            tasks = [TaskItem(title: title, prompt: trimmed, slug: slug, project: project)]
        }

        for task in tasks {
            context.insert(task)
        }

        isProcessing = false

        for task in tasks {
            await taskViewModel.launchTask(task, sessionManager: sessionManager)
        }

        if let first = tasks.first {
            appModel.selectedItemID = first.persistentModelID
        }

        prompt = ""
        errorMessage = nil
    }
}
