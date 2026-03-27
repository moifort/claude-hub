import SwiftUI

enum SyncPosition: Sendable {
    case local
    case remote
}

struct SyncBadge: View {
    let position: SyncPosition

    private var icon: String {
        switch position {
        case .local: "laptopcomputer"
        case .remote: "cloud.fill"
        }
    }

    private var tintColor: Color {
        switch position {
        case .local: .blue
        case .remote: .green
        }
    }

    var body: some View {
        Image(systemName: icon)
            .font(.caption2)
            .foregroundStyle(tintColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(tintColor.opacity(0.12), in: .capsule)
    }
}

#Preview {
    HStack {
        SyncBadge(position: .local)
        SyncBadge(position: .remote)
    }
    .padding()
}
