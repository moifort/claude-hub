import SwiftUI

struct TerminalContainer: View {
    let taskSlug: String
    let taskTitle: String
    let status: TaskStatus
    let projectName: String
    let executable: String
    let arguments: [String]
    let workingDirectory: String
    let environment: [String]?
    let onProcessTerminated: @MainActor @Sendable (Int32?) -> Void

    var body: some View {
        TerminalRepresentable(
            taskSlug: taskSlug,
            executable: executable,
            arguments: arguments,
            workingDirectory: workingDirectory,
            environment: environment,
            onProcessTerminated: onProcessTerminated
        )
    }
}

// Preview requires a live ModelContainer for PersistentIdentifier
