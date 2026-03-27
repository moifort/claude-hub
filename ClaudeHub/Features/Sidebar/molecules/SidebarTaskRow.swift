import SwiftUI

struct SidebarTaskRow: View {
    let title: String
    let status: TaskStatus
    let createdAt: Date
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(3)

            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(status.tintColor)
                    .symbolEffect(.pulse, isActive: status == .running)

                Text(status.displayName)
                    .font(.caption2)
                    .foregroundStyle(status.tintColor)
            }

            HStack(spacing: 4) {
                Text("·")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text(createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    List {
        SidebarTaskRow(
            title: "Implement OAuth2 authentication flow with refresh tokens",
            status: .running,
            createdAt: .now.addingTimeInterval(-3600),
            isSelected: false
        )
        SidebarTaskRow(
            title: "Write unit tests",
            status: .pending,
            createdAt: .now.addingTimeInterval(-120),
            isSelected: true
        )
        SidebarTaskRow(
            title: "Fix database migration for v2 schema changes",
            status: .completed,
            createdAt: .now.addingTimeInterval(-86400),
            isSelected: false
        )
    }
    .frame(width: 260)
}
