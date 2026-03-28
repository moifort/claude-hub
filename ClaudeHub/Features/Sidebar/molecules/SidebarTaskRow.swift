import SwiftUI

struct SidebarTaskRow: View {
    let title: String
    let status: TaskStatus
    let createdAt: Date
    let completedAt: Date?
    let isPinned: Bool
    let isSelected: Bool
    let onKeep: () -> Void

    private var showCountdown: Bool {
        status == .completed && !isPinned && completedAt != nil
    }

    private func formattedCountdown(_ seconds: Int) -> String {
        if seconds < 10 { return "now" }
        if seconds < 60 {
            let rounded = (seconds / 10) * 10
            return "≈\(rounded)s"
        }
        let minutes = seconds / 60
        return "≈\(minutes)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(3)

            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(status == .completed ? .primary : status.tintColor)
                    .symbolEffect(.pulse, isActive: status == .running)

                Text(status.displayName)
                    .font(.caption2)
                    .foregroundStyle(status == .completed ? .primary : status.tintColor)

                if showCountdown, let completedAt {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let elapsed = context.date.timeIntervalSince(completedAt)
                        let remaining = Int(Constants.archiveDelay - elapsed)

                        if remaining > 0 {
                            HStack(spacing: 4) {
                                Text("·")
                                    .font(.caption2)
                                    .foregroundStyle(.primary)

                                Button(action: onKeep) {
                                    Text("Keep \(formattedCountdown(remaining))")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.12), in: .capsule)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
        .opacity(status == .completed ? 0.5 : 1.0)
    }
}

#Preview {
    List {
        SidebarTaskRow(
            title: "Implement OAuth2 authentication flow with refresh tokens",
            status: .running,
            createdAt: .now.addingTimeInterval(-3600),
            completedAt: nil,
            isPinned: false,
            isSelected: false,
            onKeep: {}
        )
        SidebarTaskRow(
            title: "Write unit tests",
            status: .pending,
            createdAt: .now.addingTimeInterval(-120),
            completedAt: nil,
            isPinned: false,
            isSelected: true,
            onKeep: {}
        )
        SidebarTaskRow(
            title: "Fix database migration for v2 schema changes",
            status: .completed,
            createdAt: .now.addingTimeInterval(-86400),
            completedAt: .now.addingTimeInterval(-30),
            isPinned: false,
            isSelected: false,
            onKeep: {}
        )
    }
    .frame(width: 260)
}
