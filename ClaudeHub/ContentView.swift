import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(TerminalSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]

    @State private var viewModel = TaskListViewModel()
    @State private var showNewTaskSheet = false

    private var selectedTask: TaskItem? {
        guard let id = appModel.selectedTaskID else { return nil }
        return allTasks.first { $0.persistentModelID == id }
    }

    var body: some View {
        @Bindable var appModel = appModel

        NavigationSplitView {
            SidebarPage()
        } detail: {
            if let task = selectedTask {
                detailView(for: task)
            } else {
                ContentUnavailableView(
                    "Select a Task",
                    systemImage: "terminal",
                    description: Text("Select a task from the sidebar to view its terminal.")
                )
            }
        }
        .toolbar {
            if let task = selectedTask {
                ToolbarItemGroup(placement: .primaryAction) {
                    if task.taskStatus == .pending {
                        Button {
                            Task { await viewModel.launchTask(task, sessionManager: sessionManager) }
                        } label: {
                            Label("Launch", systemImage: "play.fill")
                        }
                    }

                    if task.taskStatus == .completed {
                        Button {
                            viewModel.pinTask(task)
                        } label: {
                            Label(
                                task.isPinned ? "Unpin" : "Pin",
                                systemImage: task.isPinned ? "pin.slash" : "pin"
                            )
                        }
                    }

                    if let project = task.project {
                        Button {
                            showNewTaskSheet = true
                        } label: {
                            Label("New Task", systemImage: "plus")
                        }
                        .keyboardShortcut("n", modifiers: .command)
                        .sheet(isPresented: $showNewTaskSheet) {
                            NewTaskSheet(project: project)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func detailView(for task: TaskItem) -> some View {
        if let session = sessionManager.session(for: task.persistentModelID) {
            TerminalContainer(
                taskID: task.persistentModelID.hashValue.description,
                taskTitle: task.title,
                status: task.taskStatus,
                projectName: task.project?.name ?? "Unknown",
                executable: session.executable,
                arguments: session.arguments,
                workingDirectory: session.workingDirectory,
                environment: session.environment,
                onProcessTerminated: { _ in
                    viewModel.completeTask(task)
                }
            )
        } else {
            VStack(spacing: 16) {
                TerminalHeader(
                    taskTitle: task.title,
                    status: task.taskStatus,
                    projectName: task.project?.name ?? "Unknown"
                )

                Spacer()

                if task.taskStatus == .pending {
                    ContentUnavailableView {
                        Label("Ready to Launch", systemImage: "play.circle")
                    } description: {
                        Text("Launch this task to start a Claude Code session.")
                    } actions: {
                        Button("Launch") {
                            Task { await viewModel.launchTask(task, sessionManager: sessionManager) }
                        }
                        .buttonStyle(.glassProminent)
                    }
                } else {
                    ContentUnavailableView(
                        task.taskStatus.displayName,
                        systemImage: task.taskStatus.iconName,
                        description: Text("This task is \(task.taskStatus.displayName.lowercased()).")
                    )
                }

                Spacer()
            }
        }
    }
}

#Preview {
    @Previewable @State var appModel = AppModel()
    @Previewable @State var sessionManager = TerminalSessionManager()

    ContentView()
        .environment(appModel)
        .environment(sessionManager)
        .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
        .frame(width: 1000, height: 700)
}
