import SwiftUI
import SwiftData

struct TerminalInspectorPage: View {
    @Environment(AppModel.self) private var appModel
    @Environment(TerminalSessionManager.self) private var sessionManager
    @Query private var allTasks: [TaskItem]

    private var selectedTask: TaskItem? {
        guard let id = appModel.selectedItemID else { return nil }
        return allTasks.first { $0.persistentModelID == id }
    }

    var body: some View {
        if let task = selectedTask,
           let session = sessionManager.session(for: task.slug) {
            TerminalContainer(
                taskSlug: task.slug,
                taskTitle: task.title,
                status: task.taskStatus,
                projectName: task.project?.name ?? "Unknown",
                executable: session.executable,
                arguments: session.arguments,
                workingDirectory: session.workingDirectory,
                environment: session.environment,
                onProcessTerminated: { _ in
                    task.taskStatus = .completed
                    task.completedAt = .now
                }
            )
        } else if let task = selectedTask {
            VStack(spacing: 12) {
                TerminalHeader(
                    taskTitle: task.title,
                    status: task.taskStatus,
                    projectName: task.project?.name ?? "Unknown"
                )
                Spacer()
                ContentUnavailableView(
                    "Terminal Not Started",
                    systemImage: "terminal",
                    description: Text("Launch the task to start a terminal session.")
                )
                Spacer()
            }
        } else {
            ContentUnavailableView(
                "No Task Selected",
                systemImage: "terminal",
                description: Text("Select a task to view its terminal.")
            )
        }
    }
}

#Preview {
    @Previewable @State var appModel = AppModel()
    @Previewable @State var sessionManager = TerminalSessionManager()

    TerminalInspectorPage()
        .environment(appModel)
        .environment(sessionManager)
        .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
        .frame(width: 500, height: 400)
}
