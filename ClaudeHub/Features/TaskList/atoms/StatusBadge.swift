import SwiftUI

struct StatusBadge: View {
    let status: TaskStatus

    var body: some View {
        Image(systemName: status.iconName)
            .font(.system(size: 14))
            .foregroundStyle(status.tintColor)
            .frame(width: 22, height: 22)
    }
}

#Preview {
    HStack(spacing: 16) {
        ForEach(TaskStatus.allCases, id: \.self) { status in
            VStack(spacing: 4) {
                StatusBadge(status: status)
                Text(status.displayName)
                    .font(.caption2)
            }
        }
    }
    .padding()
}
