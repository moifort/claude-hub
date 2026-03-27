import SwiftUI
import SwiftData

struct ProjectListSection: View {
    struct ProjectInfo: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let taskCount: Int
        let hasRunningTask: Bool
    }

    let projects: [ProjectInfo]
    let onAdd: () -> Void
    let onDelete: (PersistentIdentifier) -> Void

    var body: some View {
        Section {
            if projects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
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
                    NavigationLink(value: project.id) {
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
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Empty") {
    @Previewable @State var selection: PersistentIdentifier?

    NavigationSplitView {
        List(selection: $selection) {
            ProjectListSection(
                projects: [],
                onAdd: {},
                onDelete: { _ in }
            )
        }
    } detail: {
        Text("Detail")
    }
    .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
    .frame(width: 600, height: 400)
}

#Preview("With projects") {
    @Previewable @State var selection: PersistentIdentifier?

    NavigationSplitView {
        List(selection: $selection) {
            ProjectListSection(
                projects: [],
                onAdd: {},
                onDelete: { _ in }
            )
        }
    } detail: {
        Text("Detail")
    }
    .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
    .frame(width: 600, height: 400)
}
