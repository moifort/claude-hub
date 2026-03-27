import SwiftUI
import SwiftData

struct ProjectListSection: View {
    struct TaskInfo: Identifiable {
        let id: PersistentIdentifier
        let title: String
        let status: TaskStatus
    }

    struct ProjectInfo: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let taskCount: Int
        let hasRunningTask: Bool
        let tasks: [TaskInfo]
    }

    let projects: [ProjectInfo]
    let selectedTaskID: PersistentIdentifier?
    let onSelectProject: (PersistentIdentifier) -> Void
    let onSelectTask: (PersistentIdentifier) -> Void
    let onDelete: (PersistentIdentifier) -> Void

    @State private var expandedProjects: Set<PersistentIdentifier> = []
    @State private var initialized = false

    var body: some View {
        ForEach(projects) { project in
            CollapsibleSidebarRow(isExpanded: expandedBinding(for: project.id)) {
                ProjectRow(
                    name: project.name,
                    taskCount: project.taskCount,
                    hasRunningTask: project.hasRunningTask
                )
            } content: {
                ForEach(project.tasks) { task in
                    SidebarTaskRow(
                        title: task.title,
                        status: task.status,
                        isSelected: task.id == selectedTaskID
                    )
                    .tag(task.id)
                    .onTapGesture { onSelectTask(task.id) }
                    .padding(.leading, 8)
                }
            }
            .contextMenu {
                Button("Remove Project", role: .destructive) {
                    onDelete(project.id)
                }
            }
        }
        .onAppear {
            guard !initialized else { return }
            expandedProjects = Set(projects.map(\.id))
            initialized = true
        }
        .onChange(of: projects.map(\.id)) { _, newIDs in
            for id in newIDs where !expandedProjects.contains(id) {
                expandedProjects.insert(id)
            }
        }
    }

    private func expandedBinding(for id: PersistentIdentifier) -> Binding<Bool> {
        Binding(
            get: { expandedProjects.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedProjects.insert(id)
                } else {
                    expandedProjects.remove(id)
                }
                onSelectProject(id)
            }
        )
    }
}

#Preview("With Projects") {
    List {
        ProjectListSection(
            projects: [],
            selectedTaskID: nil,
            onSelectProject: { _ in },
            onSelectTask: { _ in },
            onDelete: { _ in }
        )
    }
    .frame(width: 300, height: 400)
}
