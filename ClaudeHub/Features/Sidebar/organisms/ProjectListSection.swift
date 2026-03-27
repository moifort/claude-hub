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
    let onDelete: (PersistentIdentifier) -> Void

    var body: some View {
        Section("Projects") {
            if projects.isEmpty {
                Text("No projects yet")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
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
        }
    }
}

#Preview {
    @Previewable @State var selection: PersistentIdentifier?

    NavigationSplitView {
        List(selection: $selection) {
            ProjectListSection(
                projects: [],
                onDelete: { _ in }
            )
        }
    } detail: {
        Text("Detail")
    }
    .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
    .frame(width: 600, height: 400)
}
