import SwiftUI

struct TerminalHeader: View {
    let taskTitle: String
    let status: TaskStatus
    let projectName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "terminal.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(taskTitle)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(projectName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GlassStatusChip(
                label: status.displayName,
                icon: status.iconName,
                tintColor: status.tintColor
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 0) {
        TerminalHeader(taskTitle: "Add OAuth2 authentication", status: .running, projectName: "my-project")
        Divider()
        TerminalHeader(taskTitle: "Write unit tests", status: .completed, projectName: "my-project")
        Divider()
        TerminalHeader(taskTitle: "Fix login bug", status: .waiting, projectName: "another-app")
    }
    .frame(width: 400)
}
