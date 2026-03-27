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
    let onAdd: () -> Void
    let onNewTask: (PersistentIdentifier) -> Void
    let onSelectTask: (PersistentIdentifier) -> Void
    let onDelete: (PersistentIdentifier) -> Void

    var body: some View {
        Section {
            if projects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "plus.rectangle.on.folder")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)

                    Text("No projects yet")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)

                    Button("Add Project", action: onAdd)
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(projects) { project in
                    DisclosureGroup {
                        if project.tasks.isEmpty {
                            Button {
                                onNewTask(project.id)
                            } label: {
                                Label("Créer une nouvelle tâche", systemImage: "plus.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(project.tasks) { task in
                                SidebarTaskRow(
                                    title: task.title,
                                    status: task.status,
                                    isSelected: task.id == selectedTaskID
                                )
                                .tag(task.id)
                                .onTapGesture { onSelectTask(task.id) }
                            }
                        }
                    } label: {
                        ProjectRow(
                            name: project.name,
                            taskCount: project.taskCount,
                            hasRunningTask: project.hasRunningTask
                        )
                    }
                    .contextMenu {
                        Button("Remove Project", role: .destructive) {
                            onDelete(project.id)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Projects")
                Spacer()
                Button(action: onAdd) {
                    Text("+")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .glassEffect(.regular, in: .capsule)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("Empty") {
    List {
        ProjectListSection(
            projects: [],
            selectedTaskID: nil,
            onAdd: {},
            onNewTask: { _ in },
            onSelectTask: { _ in },
            onDelete: { _ in }
        )
    }
    .frame(width: 300, height: 400)
}
