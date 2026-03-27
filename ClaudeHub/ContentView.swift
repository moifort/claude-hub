import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(TerminalSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]
    @Query private var allProjects: [Project]

    @State private var viewModel = TaskListViewModel()
    @State private var dragStartWidth: CGFloat?
    @State private var pushState: PushState = .idle
    @State private var pushErrorMessage: String?

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
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            HStack(spacing: 0) {
                Group {
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if appModel.showGitTree, let project = currentProject {
                    gitTreeDivider

                    GitTreePanel(repoPath: project.path, projectName: project.name, refreshTrigger: appModel.gitTreeRefreshTrigger)
                        .frame(width: appModel.gitTreeWidth)
                }
            }
        }
        .onAppear {
            if appModel.selectedItemID == nil, let first = allProjects.first {
                appModel.selectedItemID = first.persistentModelID
            }
        }
        .onChange(of: allTasks.map(\.status)) {
            guard let id = appModel.selectedItemID else { return }
            let taskStillVisible = allTasks.contains { $0.persistentModelID == id && $0.taskStatus != .archived }
            let isProject = allProjects.contains { $0.persistentModelID == id }
            if !taskStillVisible && !isProject {
                // Selected task was archived — fall back to its project or first project
                let parentProject = allTasks.first { $0.persistentModelID == id }?.project
                appModel.selectedItemID = parentProject?.persistentModelID ?? allProjects.first?.persistentModelID
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


                }
            }

            ToolbarItem(placement: .automatic) {
                if let project = currentProject {
                    pushButton(repoPath: project.path)
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
        .alert("Push Failed", isPresented: .init(
            get: { pushErrorMessage != nil },
            set: { if !$0 { pushErrorMessage = nil } }
        )) {
            Button("OK") { pushErrorMessage = nil }
        } message: {
            Text(pushErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private func pushButton(repoPath: String) -> some View {
        switch pushState {
        case .idle:
            Button {
                Task { await performPush(repoPath: repoPath) }
            } label: {
                Label("Push", systemImage: "arrow.up")
            }
        case .pushing:
            ProgressView()
                .controlSize(.small)
                .frame(width: Constants.toolbarItemSize, height: Constants.toolbarItemSize)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .frame(width: Constants.toolbarItemSize, height: Constants.toolbarItemSize)
        }
    }

    private func performPush(repoPath: String) async {
        pushState = .pushing
        do {
            try await GitService.pushMain(repoPath: repoPath)
            appModel.gitTreeRefreshTrigger += 1
            pushState = .success
            try? await Task.sleep(for: .seconds(2))
            if pushState == .success { pushState = .idle }
        } catch {
            pushState = .idle
            pushErrorMessage = error.localizedDescription
        }
    }

    private var gitTreeDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 1)
            .padding(.vertical, 4)
            .contentShape(Rectangle().inset(by: -4))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStartWidth == nil {
                            dragStartWidth = appModel.gitTreeWidth
                        }
                        let newWidth = (dragStartWidth ?? appModel.gitTreeWidth) - value.translation.width
                        appModel.gitTreeWidth = max(300, min(newWidth, 600))
                    }
                    .onEnded { _ in
                        dragStartWidth = nil
                    }
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }

    private func reconstructSession(
        for task: TaskItem,
        project: Project
    ) -> TerminalSessionManager.SessionInfo? {
        guard let claudePath = CLIService.claudePath() else { return nil }
        let customPrompt = UserDefaults.standard.string(forKey: "taskSystemPrompt")
        let systemPrompt = CLIService.buildTaskSystemPrompt(projectPath: project.path, slug: task.slug, customPrompt: customPrompt)
        let env = CLIService.enrichedEnvironment().map { "\($0.key)=\($0.value)" }
        let info = TerminalSessionManager.SessionInfo(
            executable: claudePath,
            arguments: ["--allow-dangerously-skip-permissions", "--permission-mode", "plan", "--system-prompt", systemPrompt, task.prompt],
            workingDirectory: project.path,
            environment: env
        )
        sessionManager.registerSession(
            for: task.slug,
            executable: info.executable,
            arguments: info.arguments,
            workingDirectory: info.workingDirectory,
            environment: info.environment
        )
        return info
    }

    @ViewBuilder
    private func detailView(for task: TaskItem) -> some View {
        if let session = sessionManager.session(for: task.slug) {
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
                    viewModel.completeTask(task)
                }
            )
        } else if task.taskStatus == .running, let project = task.project,
                  let reconstructed = reconstructSession(for: task, project: project) {
            TerminalContainer(
                taskSlug: task.slug,
                taskTitle: task.title,
                status: task.taskStatus,
                projectName: project.name,
                executable: reconstructed.executable,
                arguments: reconstructed.arguments,
                workingDirectory: reconstructed.workingDirectory,
                environment: reconstructed.environment,
                onProcessTerminated: { _ in
                    viewModel.completeTask(task)
                }
            )
        } else {
            VStack(spacing: 16) {
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

private enum PushState: Equatable {
    case idle
    case pushing
    case success
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
