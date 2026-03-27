import SwiftUI

struct CountdownBadge: View {
    let remainingSeconds: Int
    let onKeep: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text("\(remainingSeconds)s")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Button("Keep", action: onKeep)
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        CountdownBadge(remainingSeconds: 45, onKeep: {})
        CountdownBadge(remainingSeconds: 5, onKeep: {})
    }
    .padding()
}
