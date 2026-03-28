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
                    .inspectorColumnWidth(min: 250, ideal: 380, max: 600)
            }
        }
        .onAppear {
            if appModel.selectedItemID == nil, let first = allProjects.first {
                appModel.selectedItemID = first.persistentModelID
            }
            stateMonitor.start(sessionManager: sessionManager)
            viewModel.onSessionRemoved = { slug in
                stateMonitor.removeState(for: slug)
            }
        }
        .onChange(of: stateMonitor.detectedStates) { _, newStates in
            syncTaskStates(newStates)
        }
        .toolbar {
            if let task = selectedTask {
                ToolbarItemGroup(placement: .primaryAction) {
                    if task.taskStatus == .pending {
                        Button {
                            viewModel.launchTask(task, sessionManager: sessionManager)
                        } label: {
                            Label("Launch", systemImage: "play.fill")
                        }
                    }

                    if task.taskStatus == .completed {
                        Button {
                            viewModel.pinTask(task, sessionManager: sessionManager)
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
                if let project = currentProject {
                    let ide = IDE(rawValue: preferredIDE) ?? .intellij
                    Button {
                        ide.open(path: project.path)
                    } label: {
                        Label(ide.displayName, systemImage: ide.iconName)
                    }
                    .help("Open in \(ide.displayName)")
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

    private func syncTaskStates(_ states: [String: TerminalStateMonitor.DetectedState]) {
        for task in allTasks where task.taskStatus == .running || task.taskStatus == .waiting || task.taskStatus == .planReady {
            guard let detected = states[task.slug] else { continue }
            switch detected {
            case .waiting:
                if task.taskStatus != .waiting { task.taskStatus = .waiting }
            case .planReady:
                if task.taskStatus != .planReady { task.taskStatus = .planReady }
            case .working:
                if task.taskStatus != .running { task.taskStatus = .running }
            case .done:
                viewModel.completeTask(task, sessionManager: sessionManager)
            }
        }
    }

    @ViewBuilder
    private func detailView(for task: TaskItem) -> some View {
        if sessionManager.cachedTerminalView(for: task.slug) != nil {
            TerminalContainer(taskSlug: task.slug)
                .id(task.slug)
        } else if task.taskStatus == .pending {
            VStack(spacing: 16) {
                Spacer()
                ContentUnavailableView {
                    Label("Ready to Launch", systemImage: "play.circle")
                } description: {
                    Text("Launch this task to start a Claude Code session.")
                } actions: {
                    Button("Launch") {
                        viewModel.launchTask(task, sessionManager: sessionManager)
                    }
                    .buttonStyle(.glassProminent)
                }
                Spacer()
            }
        } else {
            ContentUnavailableView(
                task.taskStatus.displayName,
                systemImage: task.taskStatus.iconName,
                description: Text("This task is \(task.taskStatus.displayName.lowercased()).")
            )
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
