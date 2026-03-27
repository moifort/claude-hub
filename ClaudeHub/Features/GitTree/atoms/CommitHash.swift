import SwiftUI

struct CommitHash: View {
    let hash: String

    var body: some View {
        Text(hash)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
    }
}

#Preview {
    CommitHash(hash: "a1b2c3d")
        .padding()
}
