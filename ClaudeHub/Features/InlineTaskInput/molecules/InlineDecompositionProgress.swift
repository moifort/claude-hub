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
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.green.opacity(0.7))
            }
        } else if let error = errorMessage {
            Text(error)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.orange)
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
    .background(.black)
}

#Preview("Error") {
    InlineDecompositionProgress(
        isDecomposing: false,
        subtaskCount: 1,
        errorMessage: "Decomposition failed — created single task"
    )
    .padding()
    .background(.black)
}
