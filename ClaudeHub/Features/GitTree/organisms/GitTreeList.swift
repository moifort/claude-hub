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
                            isHead: row.commit.isHead,
                            isFirst: row.isFirst,
                            isLast: row.isLast,
                            color: color
                        )

                        CommitRowDetail(
                            shortHash: row.commit.shortHash,
                            subject: row.commit.subject,
                            authorName: row.commit.authorName,
                            date: row.commit.date,
                            refs: row.commit.refs.map { ($0.name, $0.kind, $0.isCurrent) }
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
                refs: []
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
                date: .now.addingTimeInterval(-7200),
                subject: "fix: resolve sidebar crash on empty project",
                refs: [GitRef(name: "v1.0", kind: .tag, isCurrent: false)]
            ),
            isFirst: false,
            isLast: true
        ),
    ]

    GitTreeList(rows: sampleRows)
        .frame(width: 400, height: 300)
}
