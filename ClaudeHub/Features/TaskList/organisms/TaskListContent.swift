import SwiftUI
import SwiftData

struct TaskListContent: View {
    struct TaskInfo: Identifiable {
        let id: PersistentIdentifier
        let title: String
        let status: TaskStatus
        let isPinned: Bool
        let completedAt: Date?
    }

    let tasks: [TaskInfo]
    let selectedTaskID: PersistentIdentifier?
    let onSelect: (PersistentIdentifier) -> Void
    let onPin: (PersistentIdentifier) -> Void
    let onLaunch: (PersistentIdentifier) -> Void

    private var groupedTasks: [(String, [TaskInfo])] {
        let order: [TaskStatus] = [.running, .waiting, .pending, .completed]
        return order.compactMap { status in
            let matching = tasks.filter { $0.status == status }
            guard !matching.isEmpty else { return nil }
            return (status.displayName, matching)
        }
    }

    private var hasCountdown: Bool {
        tasks.contains { $0.status == .completed && !$0.isPinned && $0.completedAt != nil }
    }

    var body: some View {
        if tasks.isEmpty {
            ContentUnavailableView(
                "No Tasks",
                systemImage: "checklist",
                description: Text("Create a task to start working.")
            )
        } else {
            TimelineView(.periodic(from: .now, by: hasCountdown ? 1 : 60)) { timeline in
                let _ = timeline.date // Force re-evaluation every tick
                List(selection: Binding(
                    get: { selectedTaskID },
                    set: { if let id = $0 { onSelect(id) } }
                )) {
                    ForEach(groupedTasks, id: \.0) { sectionTitle, sectionTasks in
                        Section(sectionTitle) {
                            ForEach(sectionTasks) { task in
                                TaskRow(
                                    title: task.title,
                                    status: task.status,
                                    isPinned: task.isPinned,
                                    remainingSeconds: remainingSeconds(for: task),
                                    onPin: { onPin(task.id) },
                                    onSelect: { onSelect(task.id) }
                                )
                                .tag(task.id)
                                .contextMenu {
                                    if task.status == .pending {
                                        Button("Launch") { onLaunch(task.id) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func remainingSeconds(for task: TaskInfo) -> Int? {
        guard task.status == .completed, !task.isPinned, let completedAt = task.completedAt else {
            return nil
        }
        let elapsed = Date.now.timeIntervalSince(completedAt)
        let remaining = Int(Constants.archiveDelay - elapsed)
        return remaining > 0 ? remaining : nil
    }
}

#Preview("With tasks") {
    TaskListContent(
        tasks: [],
        selectedTaskID: nil,
        onSelect: { _ in },
        onPin: { _ in },
        onLaunch: { _ in }
    )
    .frame(width: 500, height: 400)
    .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
}

#Preview("Empty") {
    TaskListContent(
        tasks: [],
        selectedTaskID: nil,
        onSelect: { _ in },
        onPin: { _ in },
        onLaunch: { _ in }
    )
    .frame(width: 500, height: 400)
}
