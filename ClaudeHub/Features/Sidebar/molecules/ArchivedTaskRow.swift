import SwiftUI

struct ArchivedTaskRow: View {
    let title: String
    let projectName: String
    let archivedAt: Date
    let onRestore: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack {
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

            Spacer()

            if isHovering {
                Button {
                    onRestore()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Restore")
            }
        }
        .onHover { isHovering = $0 }
    }
}

#Preview {
    List {
        ArchivedTaskRow(
            title: "Fix authentication flow",
            projectName: "my-project",
            archivedAt: Date.now.addingTimeInterval(-300),
            onRestore: {}
        )
        ArchivedTaskRow(
            title: "Add dark mode support",
            projectName: "another-project",
            archivedAt: Date.now.addingTimeInterval(-3600),
            onRestore: {}
        )
    }
    .frame(width: 260)
}
