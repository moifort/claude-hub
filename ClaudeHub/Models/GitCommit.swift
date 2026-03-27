import Foundation

struct GitCommit: Identifiable, Sendable {
    let id: String
    let parentIDs: [String]
    let authorName: String
    let date: Date
    let subject: String
    let refs: [GitRef]

    var isMerge: Bool { parentIDs.count > 1 }
    var isLocalHead: Bool { refs.contains { $0.kind == .head } }
    var isRemoteHead: Bool { refs.contains { $0.kind == .remoteBranch } }
}

struct GitRef: Sendable {
    let name: String
    let kind: GitRefKind
    let isCurrent: Bool
}

enum GitRefKind: Sendable {
    case localBranch
    case remoteBranch
    case tag
    case head
}
