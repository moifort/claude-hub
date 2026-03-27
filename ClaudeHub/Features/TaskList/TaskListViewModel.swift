import Foundation
import SwiftData

@Observable @MainActor
final class TaskListViewModel {
    private var archiveTimers: [PersistentIdentifier: Task<Void, Never>] = [:]

    func launchTask(_ task: TaskItem, sessionManager: TerminalSessionManager) async {
        guard task.taskStatus == .pending, let project = task.project else { return }

        let worktreeDir: String
        do {
            worktreeDir = try await GitService.createWorktree(repoPath: project.path, slug: task.slug)
        } catch {
            // Fallback: run in project directory
            worktreeDir = project.path
        }

        guard let claudePath = CLIService.claudePath() else {
            task.taskStatus = .running
            return
        }

        let systemPrompt = CLIService.buildTaskSystemPrompt(projectPath: project.path, slug: task.slug)

        // Inherit current environment for PATH, etc.
        let env = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }

        sessionManager.registerSession(
            for: task.persistentModelID,
            executable: claudePath,
            arguments: ["--system-prompt", systemPrompt, task.prompt],
            workingDirectory: worktreeDir,
            environment: env
        )

        task.taskStatus = .running
    }

    func completeTask(_ task: TaskItem) {
        task.taskStatus = .completed
        task.completedAt = .now
        startAutoArchive(for: task)
    }

    func pinTask(_ task: TaskItem) {
        task.isPinned.toggle()
        if task.isPinned {
            cancelAutoArchive(for: task)
        } else if task.taskStatus == .completed {
            startAutoArchive(for: task)
        }
    }

    func archiveTask(_ task: TaskItem) {
        task.taskStatus = .archived
        task.archivedAt = .now
        cancelAutoArchive(for: task)

        if let project = task.project {
            Task {
                try? await GitService.removeWorktree(repoPath: project.path, slug: task.slug)
            }
        }
    }

    func launchAllPending(for project: Project, sessionManager: TerminalSessionManager) async {
        let pendingTasks = project.tasks.filter { $0.taskStatus == .pending }
        for task in pendingTasks {
            await launchTask(task, sessionManager: sessionManager)
        }
    }

    func cancelAllTimers() {
        for timer in archiveTimers.values { timer.cancel() }
        archiveTimers.removeAll()
    }

    private func startAutoArchive(for task: TaskItem) {
        let id = task.persistentModelID
        cancelAutoArchive(for: task)

        archiveTimers[id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Constants.archiveDelay))
            guard !Task.isCancelled else { return }
            guard !task.isPinned, task.taskStatus == .completed else { return }
            self?.archiveTask(task)
        }
    }

    private func cancelAutoArchive(for task: TaskItem) {
        let id = task.persistentModelID
        archiveTimers[id]?.cancel()
        archiveTimers[id] = nil
    }
}
