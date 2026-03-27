import SwiftUI

struct GlassStatusChip: View {
    let label: String
    let icon: String
    let tintColor: Color

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption)
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassEffect(.regular.tint(tintColor), in: .capsule)
    }
}

#Preview {
    HStack(spacing: 12) {
        GlassStatusChip(label: "Running", icon: "play.circle.fill", tintColor: .blue)
        GlassStatusChip(label: "Waiting", icon: "questionmark.circle.fill", tintColor: .orange)
        GlassStatusChip(label: "Completed", icon: "checkmark.circle.fill", tintColor: .green)
        GlassStatusChip(label: "Pending", icon: "clock", tintColor: .secondary)
    }
    .padding()
}
