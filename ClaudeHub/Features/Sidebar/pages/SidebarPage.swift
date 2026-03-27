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

    var body: some View {
        @Bindable var appModel = appModel

        List(selection: Binding(
            get: { appModel.selectedItemID },
            set: { appModel.selectedItemID = $0 ?? appModel.selectedItemID }
        )) {
            ProjectListSection(
                projects: projects.map { project in
                    .init(
                        id: project.persistentModelID,
                        name: project.name,
                        taskCount: project.activeTasks.count,
                        tasks: project.activeTasks.map { task in
                            .init(
                                id: task.persistentModelID,
                                title: task.summary ?? task.title,
                                status: task.taskStatus,
                                createdAt: task.createdAt
                            )
                        }
                    )
                },
                selectedItemID: appModel.selectedItemID,
                onDelete: deleteProject,
                onDeleteTask: deleteTask
            )

            ArchivesSection(
                archives: Array(archivedTasks.prefix(Constants.maxArchivedVisible)).map { task in
                    .init(
                        id: task.persistentModelID.hashValue.description,
                        title: task.title,
                        projectName: task.project?.name ?? "Unknown",
                        archivedAt: task.archivedAt ?? task.createdAt
                    )
                }
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
