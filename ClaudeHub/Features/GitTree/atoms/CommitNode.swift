import SwiftUI

struct CommitNode: View {
    let isMerge: Bool
    let isHead: Bool
    let color: Color

    private var radius: CGFloat { isMerge ? 5 : 4 }

    var body: some View {
        Circle()
            .fill(color)
            .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1.5))
            .frame(width: radius * 2, height: radius * 2)
            .shadow(color: isHead ? color.opacity(0.6) : .clear, radius: isHead ? 4 : 0)
    }
}

#Preview("Normal") {
    CommitNode(isMerge: false, isHead: false, color: .blue)
        .padding()
}

#Preview("Merge") {
    CommitNode(isMerge: true, isHead: false, color: .blue)
        .padding()
}

#Preview("HEAD") {
    CommitNode(isMerge: false, isHead: true, color: .blue)
        .padding()
}
