import SwiftUI

struct SidebarTaskRow: View {
    let title: String
    let status: TaskStatus
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.iconName)
                .font(.system(size: 10))
                .foregroundStyle(status.tintColor)
                .frame(width: 14)

            Text(title)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()
        }
    }
}

#Preview {
    List {
        SidebarTaskRow(title: "Add OAuth2 auth", status: .running, isSelected: false)
        SidebarTaskRow(title: "Write unit tests", status: .pending, isSelected: true)
        SidebarTaskRow(title: "Fix migration", status: .completed, isSelected: false)
        SidebarTaskRow(title: "Waiting for input", status: .waiting, isSelected: false)
    }
    .frame(width: 260)
}
