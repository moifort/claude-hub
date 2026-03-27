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
    let onDeleteAll: () -> Void
    let onRestore: (PersistentIdentifier) -> Void

    @State private var isHoveringHeader = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        if !archives.isEmpty {
            VStack(spacing: 0) {
                Divider()

                HStack(spacing: 6) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Text("Archives")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if isHoveringHeader {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Delete all archives")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onHover { isHoveringHeader = $0 }
                .confirmationDialog("Delete all archived tasks?", isPresented: $showDeleteConfirmation) {
                    Button("Delete All", role: .destructive) {
                        onDeleteAll()
                    }
                } message: {
                    Text("This will permanently delete \(archives.count) archived task(s).")
                }

                ForEach(archives) { archive in
                    ArchivedTaskRow(
                        title: archive.title,
                        projectName: archive.projectName,
                        archivedAt: archive.archivedAt,
                        onRestore: { onRestore(archive.id) }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }
            .padding(.bottom, 8)
        }
    }
}

// Preview requires live ModelContainer for PersistentIdentifier
