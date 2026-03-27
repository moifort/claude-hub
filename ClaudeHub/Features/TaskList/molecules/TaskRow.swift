import SwiftUI

struct TaskRow: View {
    let title: String
    let status: TaskStatus
    let isPinned: Bool
    let remainingSeconds: Int?
    let onPin: () -> Void
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                StatusBadge(status: status)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .lineLimit(1)
                }

                Spacer()

                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if let remaining = remainingSeconds, status == .completed, !isPinned {
                    CountdownBadge(remainingSeconds: remaining, onKeep: onPin)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.smooth, value: status)
        .contextMenu {
            if status == .completed {
                Button {
                    onPin()
                } label: {
                    Label(
                        isPinned ? "Unpin" : "Pin",
                        systemImage: isPinned ? "pin.slash" : "pin"
                    )
                }
            }
        }
    }
}

#Preview {
    List {
        TaskRow(
            title: "Add OAuth2 authentication",
            status: .running,
            isPinned: false,
            remainingSeconds: nil,
            onPin: {},
            onSelect: {}
        )
        TaskRow(
            title: "Implement login flow",
            status: .waiting,
            isPinned: false,
            remainingSeconds: nil,
            onPin: {},
            onSelect: {}
        )
        TaskRow(
            title: "Write unit tests",
            status: .pending,
            isPinned: false,
            remainingSeconds: nil,
            onPin: {},
            onSelect: {}
        )
        TaskRow(
            title: "Fix database migration",
            status: .completed,
            isPinned: false,
            remainingSeconds: 42,
            onPin: {},
            onSelect: {}
        )
        TaskRow(
            title: "Refactor API layer",
            status: .completed,
            isPinned: true,
            remainingSeconds: nil,
            onPin: {},
            onSelect: {}
        )
    }
    .frame(width: 400, height: 350)
}
