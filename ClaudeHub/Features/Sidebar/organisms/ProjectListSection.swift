import SwiftUI
import SwiftData

struct ProjectListSection: View {
    struct TaskInfo: Identifiable {
        let id: PersistentIdentifier
        let title: String
        let status: TaskStatus
        let createdAt: Date
        let completedAt: Date?
        let isPinned: Bool
    }

    struct ProjectInfo: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let taskCount: Int
        let tasks: [TaskInfo]
    }

    let projects: [ProjectInfo]
    let selectedItemID: PersistentIdentifier?
    let onDelete: (PersistentIdentifier) -> Void
    let onDeleteTask: (PersistentIdentifier) -> Void
    let onKeepTask: (PersistentIdentifier) -> Void

    var body: some View {
        ForEach(projects) { project in
            ProjectRow(
                name: project.name,
                taskCount: project.taskCount
            )
            .tag(project.id)
            .contextMenu {
                Button("Remove Project", role: .destructive) {
                    onDelete(project.id)
                }
            }

            ForEach(project.tasks) { task in
                SidebarTaskRow(
                    title: task.title,
                    status: task.status,
                    createdAt: task.createdAt,
                    completedAt: task.completedAt,
                    isPinned: task.isPinned,
                    isSelected: task.id == selectedItemID,
                    onKeep: { onKeepTask(task.id) }
                )
                .tag(task.id)
                .padding(.leading, 4)
                .contextMenu {
                    Button("Delete Task", role: .destructive) {
                        onDeleteTask(task.id)
                    }
                }
            }
        }
    }
}

#Preview("With Projects") {
    List {
        ProjectListSection(
            projects: [],
            selectedItemID: nil,
            onDelete: { _ in },
            onDeleteTask: { _ in },
            onKeepTask: { _ in }
        )
    }
    .frame(width: 300, height: 400)
}
