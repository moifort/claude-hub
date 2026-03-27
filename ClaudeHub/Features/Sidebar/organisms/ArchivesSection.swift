import SwiftUI
import SwiftData

struct ArchivesSection: View {
    struct ArchiveInfo: Identifiable {
        let id: PersistentIdentifier
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
                        .font(.system(size: 14))
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
                    .tag(archive.id)
                    .padding(.leading, 8)
                }
            }
        }
    }
}

// Preview requires live ModelContainer for PersistentIdentifier
