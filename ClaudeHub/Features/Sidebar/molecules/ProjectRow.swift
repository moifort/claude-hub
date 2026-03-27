import SwiftUI

struct ProjectRow: View {
    let name: String
    let taskCount: Int

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Text(name)

            Spacer()

            if taskCount > 0 {
                Text("\(taskCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .glassEffect(.regular, in: .capsule)
            }
        }
    }
}

#Preview("With tasks") {
    List {
        ProjectRow(name: "my-project", taskCount: 3)
        ProjectRow(name: "another-project", taskCount: 0)
        ProjectRow(name: "empty-project", taskCount: 1)
    }
    .frame(width: 260)
}

#Preview("No tasks") {
    List {
        ProjectRow(name: "fresh-project", taskCount: 0)
    }
    .frame(width: 260)
}
