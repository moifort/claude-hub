import SwiftUI
import SwiftData

struct SidebarPage: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @Query(
        filter: #Predicate<TaskItem> { $0.status == "archived" },
        sort: \TaskItem.archivedAt,
        order: .reverse
    ) private var archivedTasks: [TaskItem]

    private var projectInfos: [ProjectListSection.ProjectInfo] {
        projects.map { project in
            ProjectListSection.ProjectInfo(
                id: project.persistentModelID,
                name: project.name,
                taskCount: project.activeTasks.count,
                tasks: project.activeTasks
                    .sorted { $0.taskStatus.sortPriority < $1.taskStatus.sortPriority }
                    .map { task in
                        ProjectListSection.TaskInfo(
                            id: task.persistentModelID,
                            title: task.summary ?? task.title,
                            status: task.taskStatus,
                            createdAt: task.createdAt,
                            completedAt: task.completedAt,
                            isPinned: task.isPinned
                        )
                    }
            )
        }
    }

    private var archiveInfos: [ArchivesSection.ArchiveInfo] {
        Array(archivedTasks.prefix(Constants.maxArchivedVisible)).map { task in
            ArchivesSection.ArchiveInfo(
                id: task.persistentModelID,
                title: task.title,
                projectName: task.project?.name ?? "Unknown",
                archivedAt: task.archivedAt ?? task.createdAt
            )
        }
    }

    var body: some View {
        @Bindable var appModel = appModel

        List(selection: Binding(
            get: { appModel.selectedItemID },
            set: { appModel.selectedItemID = $0 ?? appModel.selectedItemID }
        )) {
            ProjectListSection(
                projects: projectInfos,
                selectedItemID: appModel.selectedItemID,
                onDelete: deleteProject,
                onDeleteTask: deleteTask,
                onKeepTask: keepTask
            )
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ArchivesSection(
                archives: archiveInfos,
                onDeleteAll: deleteAllArchives,
                onRestore: restoreArchivedTask
            )
        }
        .navigationTitle("ClaudeHub")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    pickFolder()
                } label: {
                    Label("Add Project", systemImage: "plus")
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
            return true
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a git repository"
        panel.prompt = "Add Project"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        addProject(at: url.path(percentEncoded: false))
    }

    private func addProject(at path: String) {
        guard GitService.isGitRepository(at: path) else { return }
        let name = GitService.repositoryName(at: path)

        guard !projects.contains(where: { $0.path == path }) else { return }

        let project = Project(name: name, path: path)
        modelContext.insert(project)
    }

    private func deleteTask(_ id: PersistentIdentifier) {
        let allTasks = projects.flatMap(\.tasks)
        guard let task = allTasks.first(where: { $0.persistentModelID == id }) else { return }
        modelContext.delete(task)
        if appModel.selectedItemID == id {
            appModel.selectedItemID = task.project?.persistentModelID
        }
    }

    private func deleteAllArchives() {
        for task in archivedTasks {
            modelContext.delete(task)
        }
    }

    private func restoreArchivedTask(_ id: PersistentIdentifier) {
        guard let task = archivedTasks.first(where: { $0.persistentModelID == id }) else { return }
        task.taskStatus = .completed
        task.archivedAt = nil
    }

    private func keepTask(_ id: PersistentIdentifier) {
        let allTasks = projects.flatMap(\.tasks)
        guard let task = allTasks.first(where: { $0.persistentModelID == id }) else { return }
        task.isPinned = true
    }

    private func deleteProject(_ id: PersistentIdentifier) {
        guard let project = projects.first(where: { $0.persistentModelID == id }) else { return }
        modelContext.delete(project)
        if appModel.selectedItemID == id {
            appModel.selectedItemID = nil
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url") { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                let path = url.path(percentEncoded: false)
                Task { @MainActor in
                    addProject(at: path)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var appModel = AppModel()

    NavigationSplitView {
        SidebarPage()
            .environment(appModel)
            .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
    } detail: {
        Text("Detail")
    }
    .frame(width: 800, height: 500)
}
