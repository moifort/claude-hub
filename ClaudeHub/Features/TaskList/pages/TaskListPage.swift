import SwiftUI
import SwiftData

struct TaskListPage: View {
    @Environment(AppModel.self) private var appModel
    @Environment(TerminalSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    let project: Project

    @State private var viewModel = TaskListViewModel()
    @State private var showNewTaskSheet = false

    private var projectTasks: [TaskItem] {
        allTasks.filter { $0.project?.persistentModelID == project.persistentModelID && $0.taskStatus != .archived }
    }

    var body: some View {
        TaskListContent(
            tasks: projectTasks.map { task in
                .init(
                    id: task.persistentModelID,
                    title: task.title,
                    status: task.taskStatus,
                    isPinned: task.isPinned,
                    completedAt: task.completedAt
                )
            },
            selectedTaskID: appModel.selectedTaskID,
            onSelect: { id in
                appModel.selectedTaskID = id
                appModel.showInspector = true
            },
            onPin: { id in
                guard let task = projectTasks.first(where: { $0.persistentModelID == id }) else { return }
                viewModel.pinTask(task)
            },
            onLaunch: { id in
                guard let task = projectTasks.first(where: { $0.persistentModelID == id }) else { return }
                Task { await viewModel.launchTask(task, sessionManager: sessionManager) }
            }
        )
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 8) {
                    if projectTasks.contains(where: { $0.taskStatus == .pending }) {
                        Button {
                            Task {
                                await viewModel.launchAllPending(for: project, sessionManager: sessionManager)
                            }
                        } label: {
                            Label("Launch All", systemImage: "play.fill")
                        }
                    }

                    Button {
                        showNewTaskSheet = true
                    } label: {
                        Label("New Task", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
        }
        .sheet(isPresented: $showNewTaskSheet) {
            NewTaskSheet(project: project)
        }
    }
}

#Preview {
    @Previewable @State var appModel = AppModel()
    @Previewable @State var sessionManager = TerminalSessionManager()

    NavigationSplitView {
        Text("Sidebar")
    } detail: {
        TaskListPage(project: Project(name: "my-project", path: "/tmp/my-project"))
            .environment(appModel)
            .environment(sessionManager)
    }
    .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
    .frame(width: 800, height: 500)
}
