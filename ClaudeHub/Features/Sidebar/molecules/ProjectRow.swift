import SwiftUI

struct ProjectRow: View {
    let name: String
    let taskCount: Int
    let hasRunningTask: Bool

    var body: some View {
        Label {
            HStack {
                Text(name)

                Spacer()

                if taskCount > 0 {
                    Text("\(taskCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: .capsule)
                }

                if hasRunningTask {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.green)
                }
            }
        } icon: {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
        }
    }
}

#Preview("With tasks") {
    List {
        ProjectRow(name: "my-project", taskCount: 3, hasRunningTask: true)
        ProjectRow(name: "another-project", taskCount: 0, hasRunningTask: false)
        ProjectRow(name: "empty-project", taskCount: 1, hasRunningTask: false)
    }
    .frame(width: 260)
}

#Preview("No tasks") {
    List {
        ProjectRow(name: "fresh-project", taskCount: 0, hasRunningTask: false)
    }
    .frame(width: 260)
}
