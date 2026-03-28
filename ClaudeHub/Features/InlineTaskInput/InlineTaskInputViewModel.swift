import Foundation
import SwiftData

@Observable @MainActor
final class InlineTaskInputViewModel {
    var prompt = ""
    private(set) var isSummarizing = false
    private(set) var errorMessage: String?
    private(set) var lastConfirmationMessage: String?

    var canSubmit: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSummarizing
    }

    func clearConfirmation() {
        lastConfirmationMessage = nil
    }

    func submit(
        project: Project,
        context: ModelContext,
        sessionManager: TerminalSessionManager,
        taskViewModel: TaskListViewModel,
        useFoundationSplit: Bool
    ) async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = nil
        isSummarizing = true

        let taskPrompts = useFoundationSplit
            ? await SummarizationService.splitTasks(from: trimmed)
            : [trimmed]

        var createdTasks: [TaskItem] = []
        for taskPrompt in taskPrompts {
            let title: String
            if taskPrompt.count <= 250 {
                title = taskPrompt
            } else {
                title = await SummarizationService.summarize(prompt: taskPrompt)
            }
            let slug = TaskItem.generateSlug(from: title)
            let task = TaskItem(
                title: title,
                prompt: taskPrompt,
                slug: slug,
                project: project
            )
            context.insert(task)
            createdTasks.append(task)
        }
        try? context.save()

        isSummarizing = false
        prompt = ""
        errorMessage = nil

        if createdTasks.count == 1, let task = createdTasks.first {
            lastConfirmationMessage = "Task created: \(task.title)"
        } else {
            lastConfirmationMessage = "\(createdTasks.count) tasks created"
        }

        for task in createdTasks {
            taskViewModel.launchTask(task, sessionManager: sessionManager)
        }
    }
}
