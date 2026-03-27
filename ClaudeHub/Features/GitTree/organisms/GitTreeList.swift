import SwiftUI

struct GitTreeList: View {
    let rows: [GitGraphRow]
    let color: Color = .blue

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(rows) { row in
                    HStack(spacing: 0) {
                        GraphRowSegment(
                            isMerge: row.commit.isMerge,
                            isHead: row.commit.isLocalHead,
                            isFirst: row.isFirst,
                            isLast: row.isLast,
                            color: color
                        )

                        CommitRowDetail(
                            subject: row.commit.subject,
                            date: row.commit.date,
                            isLocalHead: row.commit.isLocalHead,
                            isRemoteHead: row.commit.isRemoteHead
                        )
                        .padding(.trailing, 12)
                    }
                    .frame(height: GraphRowSegment.rowHeight)
                }
            }
        }
    }
}

#Preview {
    let sampleRows = [
        GitGraphRow(
            id: "aaa",
            commit: GitCommit(
                id: "aaa111222333",
                parentIDs: ["bbb"],
                authorName: "Thibaut",
                date: .now.addingTimeInterval(-60),
                subject: "feat: add git tree panel",
                refs: [GitRef(name: "main", kind: .head, isCurrent: true)]
            ),
            isFirst: true,
            isLast: false
        ),
        GitGraphRow(
            id: "bbb",
            commit: GitCommit(
                id: "bbb222333444",
                parentIDs: ["ccc", "ddd"],
                authorName: "Thibaut",
                date: .now.addingTimeInterval(-3600),
                subject: "Merge branch 'feature/auth' into main",
                refs: [GitRef(name: "origin/main", kind: .remoteBranch, isCurrent: false)]
            ),
            isFirst: false,
            isLast: false
        ),
        GitGraphRow(
            id: "ccc",
            commit: GitCommit(
                id: "ccc333444555",
                parentIDs: ["ddd"],
                authorName: "Thibaut",
                date: .now.addingTimeInterval(-90000),
                subject: "fix: resolve sidebar crash on empty project",
                refs: []
            ),
            isFirst: false,
            isLast: true
        ),
    ]

    GitTreeList(rows: sampleRows)
        .frame(width: 400, height: 300)
}
