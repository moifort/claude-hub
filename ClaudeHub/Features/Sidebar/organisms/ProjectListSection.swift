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

    var body: some View {
        ForEach(projects) { project in
            Button { onSelectProject(project.id) } label: {
                ProjectRow(
                    name: project.name,
                    taskCount: project.taskCount,
                    hasRunningTask: project.hasRunningTask
                )
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Remove Project", role: .destructive) {
                    onDelete(project.id)
                }
            }

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
