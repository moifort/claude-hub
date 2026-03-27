import SwiftUI

struct DecompositionProgress: View {
    let isDecomposing: Bool
    let subtaskCount: Int?
    let errorMessage: String?

    var body: some View {
        if isDecomposing {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Decomposing task...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } else if let count = subtaskCount {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(count) subtask\(count == 1 ? "" : "s") created")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } else if let error = errorMessage {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview("Decomposing") {
    DecompositionProgress(isDecomposing: true, subtaskCount: nil, errorMessage: nil)
        .padding()
}

#Preview("Completed") {
    DecompositionProgress(isDecomposing: false, subtaskCount: 3, errorMessage: nil)
        .padding()
}

#Preview("Error") {
    DecompositionProgress(
        isDecomposing: false,
        subtaskCount: nil,
        errorMessage: "Claude CLI not found"
    )
    .padding()
}
