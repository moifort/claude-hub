import SwiftUI

struct BranchLabel: View {
    let name: String
    let kind: GitRefKind
    let isCurrent: Bool

    private var tintColor: Color {
        switch kind {
        case .head: .blue
        case .localBranch: .green
        case .remoteBranch: .orange
        case .tag: .purple
        }
    }

    private var icon: String {
        switch kind {
        case .head, .localBranch: "arrow.triangle.branch"
        case .remoteBranch: "cloud"
        case .tag: "tag"
        }
    }

    var body: some View {
        Label(name, systemImage: icon)
            .font(.caption2)
            .fontWeight(isCurrent ? .semibold : .regular)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tintColor.opacity(0.15), in: .capsule)
            .foregroundStyle(tintColor)
    }
}

#Preview {
    HStack {
        BranchLabel(name: "main", kind: .head, isCurrent: true)
        BranchLabel(name: "origin/main", kind: .remoteBranch, isCurrent: false)
        BranchLabel(name: "v1.0", kind: .tag, isCurrent: false)
        BranchLabel(name: "develop", kind: .localBranch, isCurrent: false)
    }
    .padding()
}
