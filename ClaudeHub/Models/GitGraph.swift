import Foundation

struct GitGraph: Sendable {
    let rows: [GitGraphRow]
}

struct GitGraphRow: Identifiable, Sendable {
    let id: String
    let commit: GitCommit
    let isFirst: Bool
    let isLast: Bool
}
