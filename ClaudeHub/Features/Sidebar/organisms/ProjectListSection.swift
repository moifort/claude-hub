import SwiftUI
import SwiftData

struct ProjectListSection: View {
    struct TaskInfo: Identifiable {
        let id: PersistentIdentifier
        let title: String
        let summary: String?
        let status: TaskStatus
        let createdAt: Date
    }

    struct ProjectInfo: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let taskCount: Int
        let hasRunningTask: Bool
        let tasks: [TaskInfo]
    }

    let projects: [ProjectInfo]
    let selectedItemID: PersistentIdentifier?
    let onDelete: (PersistentIdentifier) -> Void
    let onDeleteTask: (PersistentIdentifier) -> Void

    var body: some View {
        ForEach(projects) { project in
            ProjectRow(
                name: project.name,
                taskCount: project.taskCount,
                hasRunningTask: project.hasRunningTask
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
                    summary: task.summary,
                    status: task.status,
                    createdAt: task.createdAt,
                    isSelected: task.id == selectedItemID
                )
                .tag(task.id)
                .padding(.leading, 8)
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
            onDeleteTask: { _ in }
        )
    }
    .frame(width: 300, height: 400)
}
