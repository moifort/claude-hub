import SwiftUI

struct InlineDecompositionProgress: View {
    let isDecomposing: Bool
    let subtaskCount: Int?
    let errorMessage: String?

    var body: some View {
        if isDecomposing {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Analyzing project and decomposing tasks...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if let error = errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}

#Preview("Decomposing") {
    InlineDecompositionProgress(
        isDecomposing: true,
        subtaskCount: nil,
        errorMessage: nil
    )
    .padding()
    .background(.background)
}

#Preview("Error") {
    InlineDecompositionProgress(
        isDecomposing: false,
        subtaskCount: 1,
        errorMessage: "Decomposition failed — created single task"
    )
    .padding()
    .background(.background)
}
