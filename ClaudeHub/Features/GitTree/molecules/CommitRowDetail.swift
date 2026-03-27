import SwiftUI

struct CommitRowDetail: View {
    let shortHash: String
    let subject: String
    let authorName: String
    let date: Date
    let refs: [(name: String, kind: GitRefKind, isCurrent: Bool)]

    var body: some View {
        HStack(spacing: 8) {
            CommitHash(hash: shortHash)

            if !refs.isEmpty {
                ForEach(refs, id: \.name) { ref in
                    BranchLabel(name: ref.name, kind: ref.kind, isCurrent: ref.isCurrent)
                }
            }

            Text(subject)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)

            Spacer(minLength: 4)

            Text(date, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize()
        }
    }
}

#Preview {
    CommitRowDetail(
        shortHash: "a1b2c3d",
        subject: "feat(git-tree): add commit graph visualization panel",
        authorName: "Thibaut",
        date: .now.addingTimeInterval(-3600),
        refs: [
            (name: "main", kind: .head, isCurrent: true),
            (name: "origin/main", kind: .remoteBranch, isCurrent: false),
        ]
    )
    .padding()
}
