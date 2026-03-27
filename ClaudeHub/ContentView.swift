import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(TerminalSessionManager.self) private var sessionManager
    @Environment(TerminalStateMonitor.self) private var stateMonitor
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [TaskItem]
    @Query private var allProjects: [Project]

    @State private var viewModel = TaskListViewModel()
    @AppStorage("preferredIDE") private var preferredIDE = IDE.intellij.rawValue
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
        @Bindable var appModel = appModel

        NavigationSplitView {
            SidebarPage()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
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
        }
        .inspector(isPresented: $appModel.showGitTree) {
            if let project = currentProject {
                GitTreePanel(repoPath: project.path, projectName: project.name, refreshTrigger: appModel.gitTreeRefreshTrigger)
                    .ignoresSafeArea(edges: .top)
                    .inspectorColumnWidth(min: 250, ideal: 380, max: 600)
            }
        }
        .onAppear {
            if appModel.selectedItemID == nil, let first = allProjects.first {
                appModel.selectedItemID = first.persistentModelID
            }
            stateMonitor.start(sessionManager: sessionManager)
        }
        .onChange(of: stateMonitor.detectedStates) { _, newStates in
            syncTaskStates(newStates)
        }
        .toolbar {
            ToolbarSpacer(.flexible)

            if let task = selectedTask {
                if task.taskStatus == .pending {
                    ToolbarItem {
                        Button {
                            Task { await viewModel.launchTask(task, sessionManager: sessionManager) }
                        } label: {
                            Label("Launch", systemImage: "play.fill")
                        }
                    }
                }

                if task.taskStatus == .completed {
                    ToolbarItem {
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

                ToolbarSpacer(.fixed)
            }

            if let project = currentProject {
                ToolbarItem {
                    pushButton(repoPath: project.path)
                }

                ToolbarSpacer(.fixed)

                ToolbarItem {
                    let ide = IDE(rawValue: preferredIDE) ?? .intellij
                    Button {
                        ide.open(path: project.path)
                    } label: {
                        Label(ide.displayName, systemImage: ide.iconName)
                    }
                    .help("Open in \(ide.displayName)")
                }

                ToolbarSpacer(.fixed)
            }

            ToolbarItem {
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
        .toolbar(removing: .title)
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

    private func reconstructSession(
        for task: TaskItem,
        project: Project
    ) -> TerminalSessionManager.SessionInfo? {
        guard let claudePath = CLIService.claudePath() else { return nil }
        let customPrompt = UserDefaults.standard.string(forKey: "taskSystemPrompt")
        let systemPrompt = CLIService.buildTaskSystemPrompt(projectPath: project.path, slug: task.slug, customPrompt: customPrompt)
        let env = CLIService.enrichedEnvironment().map { "\($0.key)=\($0.value)" }
        let skipPermissions = UserDefaults.standard.object(forKey: "skipPermissions") as? Bool ?? true
        var arguments = [String]()
        if skipPermissions {
            arguments.append("--allow-dangerously-skip-permissions")
        }
        arguments.append(contentsOf: ["--permission-mode", "plan", "--system-prompt", systemPrompt, task.prompt])

        let info = TerminalSessionManager.SessionInfo(
            executable: claudePath,
            arguments: arguments,
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

    private func syncTaskStates(_ states: [String: TerminalStateMonitor.DetectedState]) {
        for task in allTasks where task.taskStatus == .running || task.taskStatus == .waiting {
            guard let detected = states[task.slug] else { continue }
            switch detected {
            case .waiting:
                if task.taskStatus != .waiting { task.taskStatus = .waiting }
            case .working:
                if task.taskStatus != .running { task.taskStatus = .running }
            case .done:
                break // handled by processTerminated
            }
        }
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
        } else if (task.taskStatus == .running || task.taskStatus == .waiting), let project = task.project,
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
    @Previewable @State var stateMonitor = TerminalStateMonitor()

    ContentView()
        .environment(appModel)
        .environment(sessionManager)
        .environment(stateMonitor)
        .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
        .frame(width: 1000, height: 700)
}
