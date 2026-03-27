import SwiftUI

struct SidebarTaskRow: View {
    let title: String
    let status: TaskStatus
    let createdAt: Date
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(status.tintColor)
                .symbolEffect(.pulse, isActive: status == .running)
                .frame(width: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(3)

                Text(createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
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
