import SwiftUI

struct ArchivesSection: View {
    struct ArchiveInfo: Identifiable {
        let id: String
        let title: String
        let projectName: String
        let archivedAt: Date
    }

    let archives: [ArchiveInfo]

    @State private var isExpanded = true

    var body: some View {
        if !archives.isEmpty {
            CollapsibleSidebarRow(isExpanded: $isExpanded) {
                HStack(spacing: 6) {
                    Image(systemName: "archivebox")
                        .foregroundStyle(.secondary)
                    Text("Archives")
                }
            } content: {
                ForEach(archives) { archive in
                    ArchivedTaskRow(
                        title: archive.title,
                        projectName: archive.projectName,
                        archivedAt: archive.archivedAt
                    )
                    .padding(.leading, 8)
                }
            }
        }
    }
}

#Preview {
    List {
        ArchivesSection(archives: [
            .init(id: "1", title: "Fix login bug", projectName: "my-app", archivedAt: .now.addingTimeInterval(-120)),
            .init(id: "2", title: "Add tests", projectName: "lib", archivedAt: .now.addingTimeInterval(-3600)),
        ])
    }
    .frame(width: 260)
}
