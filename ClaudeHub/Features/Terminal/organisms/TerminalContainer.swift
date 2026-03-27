import SwiftUI

struct TerminalContainer: View {
    let taskID: String
    let taskTitle: String
    let status: TaskStatus
    let projectName: String
    let executable: String
    let arguments: [String]
    let workingDirectory: String
    let environment: [String]?
    let onProcessTerminated: @MainActor @Sendable (Int32?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            TerminalHeader(
                taskTitle: taskTitle,
                status: status,
                projectName: projectName
            )

            Divider()

            TerminalRepresentable(
                taskID: taskID,
                executable: executable,
                arguments: arguments,
                workingDirectory: workingDirectory,
                environment: environment,
                onProcessTerminated: onProcessTerminated
            )
        }
    }
}

#Preview {
    TerminalContainer(
        taskID: "preview",
        taskTitle: "Add authentication",
        status: .running,
        projectName: "my-project",
        executable: "/bin/bash",
        arguments: ["-c", "echo 'Hello from ClaudeHub terminal'; sleep 2; echo 'Done'"],
        workingDirectory: NSHomeDirectory(),
        environment: nil,
        onProcessTerminated: { code in print("Exit: \(String(describing: code))") }
    )
    .frame(width: 500, height: 400)
}
