import Foundation
import SwiftData

@Observable @MainActor
final class TaskListViewModel {
    var onSessionRemoved: ((String) -> Void)?
    var modelContext: ModelContext?
    var appModel: AppModel?

    private var archiveTimers: [PersistentIdentifier: Task<Void, Never>] = [:]

    func launchTask(_ task: TaskItem, sessionManager: TerminalSessionManager, containerSize: CGSize = .zero) {
        guard task.taskStatus == .pending, let project = task.project else { return }
        guard let claudePath = CLIService.claudePath() else { return }

        let customPrompt = UserDefaults.standard.string(forKey: "taskSystemPrompt")
        let systemPrompt = CLIService.buildTaskSystemPrompt(projectPath: project.path, slug: task.slug, customPrompt: customPrompt)
        let env = CLIService.enrichedEnvironment().map { "\($0.key)=\($0.value)" }

        let skipPermissions = UserDefaults.standard.object(forKey: "skipPermissions") as? Bool ?? true
        var arguments = [String]()
        if skipPermissions {
            arguments.append("--allow-dangerously-skip-permissions")
        }
        arguments.append(contentsOf: ["--permission-mode", "plan", "--system-prompt", systemPrompt, task.prompt])

        let initialSize = containerSize.width > 1 ? containerSize : CGSize(width: 600, height: 400)

        sessionManager.launchSession(
            for: task.slug,
            executable: claudePath,
            arguments: arguments,
            workingDirectory: project.path,
            environment: env,
            initialSize: initialSize,
            onProcessTerminated: { [weak self] exitCode in
                if exitCode == 0 {
                    self?.completeTask(task, sessionManager: sessionManager)
                } else {
                    self?.deleteTerminatedTask(task, sessionManager: sessionManager)
                }
            }
        )

        task.taskStatus = .running
    }

    func completeTask(_ task: TaskItem, sessionManager: TerminalSessionManager) {
        guard task.taskStatus == .running || task.taskStatus == .waiting || task.taskStatus == .planReady else { return }
        task.taskStatus = .completed
        task.completedAt = .now
        startAutoArchive(for: task, sessionManager: sessionManager)
    }

    func pinTask(_ task: TaskItem, sessionManager: TerminalSessionManager) {
        task.isPinned.toggle()
        if task.isPinned {
            cancelAutoArchive(for: task)
        } else if task.taskStatus == .completed {
            startAutoArchive(for: task, sessionManager: sessionManager)
        }
    }

    func archiveTask(_ task: TaskItem, sessionManager: TerminalSessionManager) {
        task.taskStatus = .archived
        task.archivedAt = .now
        cancelAutoArchive(for: task)
        sessionManager.removeSession(for: task.slug)
        onSessionRemoved?(task.slug)
    }

    func deleteTerminatedTask(_ task: TaskItem, sessionManager: TerminalSessionManager) {
        guard task.modelContext != nil else { return }
        let taskID = task.persistentModelID
        let projectID = task.project?.persistentModelID
        sessionManager.removeSession(for: task.slug)
        onSessionRemoved?(task.slug)
        if appModel?.selectedItemID == taskID {
            appModel?.selectedItemID = projectID
        }
        modelContext?.delete(task)
    }

    func launchAllPending(for project: Project, sessionManager: TerminalSessionManager, containerSize: CGSize = .zero) {
        let pendingTasks = project.tasks.filter { $0.taskStatus == .pending }
        for task in pendingTasks {
            launchTask(task, sessionManager: sessionManager, containerSize: containerSize)
        }
    }

    func cancelAllTimers() {
        for timer in archiveTimers.values { timer.cancel() }
        archiveTimers.removeAll()
    }

    private func startAutoArchive(for task: TaskItem, sessionManager: TerminalSessionManager) {
        let id = task.persistentModelID
        cancelAutoArchive(for: task)

        archiveTimers[id] = Task { [weak self] in
            let delay = UserDefaults.standard.object(forKey: "archiveDelayMinutes") as? Double ?? 5.0
            try? await Task.sleep(for: .seconds(delay * 60))
            guard !Task.isCancelled else { return }
            guard !task.isPinned, task.taskStatus == .completed else { return }
            self?.archiveTask(task, sessionManager: sessionManager)
        }
    }

    private func cancelAutoArchive(for task: TaskItem) {
        let id = task.persistentModelID
        archiveTimers[id]?.cancel()
        archiveTimers[id] = nil
    }
}
