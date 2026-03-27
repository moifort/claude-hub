import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(TerminalSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]
    @Query private var allProjects: [Project]

    @State private var viewModel = TaskListViewModel()

    private var selectedTask: TaskItem? {
        guard let id = appModel.selectedItemID else { return nil }
        return allTasks.first { $0.persistentModelID == id }
    }

    private var selectedProject: Project? {
        guard let id = appModel.selectedItemID else { return nil }
        return allProjects.first { $0.persistentModelID == id }
    }

    private var currentProject: Project? {
        selectedProject ?? selectedTask?.project
    }

    var body: some View {
        NavigationSplitView {
            SidebarPage()
        } detail: {
            HSplitView {
                if let task = selectedTask {
                    detailView(for: task)
                } else if let project = selectedProject {
                    InlineTaskInputPage(project: project)
                } else {
                    ContentUnavailableView(
                        "Select a Project",
                        systemImage: "folder",
                        description: Text("Add a project from the sidebar to get started.")
                    )
                }

                if appModel.showGitTree, let project = currentProject {
                    GitTreePanel(repoPath: project.path, projectName: project.name)
                        .frame(minWidth: 300, idealWidth: 380)
                }
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
                            appModel.selectedItemID = project.persistentModelID
                        } label: {
                            Label("New Task", systemImage: "plus")
                        }
                        .keyboardShortcut("n", modifiers: .command)
                    }
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    appModel.showGitTree.toggle()
                } label: {
                    Label(
                        "Git Tree",
                        systemImage: "point.3.connected.trianglepath.dotted"
                    )
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
