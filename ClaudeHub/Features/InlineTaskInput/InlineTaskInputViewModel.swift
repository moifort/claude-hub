import Foundation
import SwiftData

@Observable @MainActor
final class InlineTaskInputViewModel {
    var prompt = ""
    private(set) var isSummarizing = false
    private(set) var errorMessage: String?

    var canSubmit: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSummarizing
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

        isSummarizing = true
        errorMessage = nil

        let title = await SummarizationService.summarize(prompt: trimmed)
        let slug = TaskItem.generateSlug(from: title)
        let task = TaskItem(
            title: title,
            prompt: trimmed,
            slug: slug,
            project: project
        )
        context.insert(task)

        isSummarizing = false

        await taskViewModel.launchTask(task, sessionManager: sessionManager)
        appModel.selectedItemID = task.persistentModelID

        prompt = ""
        errorMessage = nil
    }
}
