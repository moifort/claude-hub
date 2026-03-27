import SwiftUI

struct ArchivedTaskRow: View {
    let title: String
    let projectName: String
    let archivedAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(projectName)
                Text("·")
                Text(archivedAt, style: .relative)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        ArchivedTaskRow(
            title: "Fix authentication flow",
            projectName: "my-project",
            archivedAt: Date.now.addingTimeInterval(-300)
        )
        ArchivedTaskRow(
            title: "Add dark mode support",
            projectName: "another-project",
            archivedAt: Date.now.addingTimeInterval(-3600)
        )
    }
    .frame(width: 260)
}
