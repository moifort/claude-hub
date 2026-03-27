import SwiftUI
import SwiftTerm

struct TerminalRepresentable: NSViewRepresentable {
    let taskID: String
    let executable: String
    let arguments: [String]
    let workingDirectory: String
    let environment: [String]?
    let onProcessTerminated: @MainActor @Sendable (Int32?) -> Void

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminal = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        terminal.processDelegate = context.coordinator
        terminal.startProcess(
            executable: executable,
            args: arguments,
            environment: environment,
            currentDirectory: workingDirectory
        )
        return terminal
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        // Terminal view is managed by the process lifecycle
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onProcessTerminated: onProcessTerminated)
    }

    final class Coordinator: NSObject, LocalProcessTerminalViewDelegate, @unchecked Sendable {
        let onProcessTerminated: @MainActor @Sendable (Int32?) -> Void

        init(onProcessTerminated: @MainActor @Sendable @escaping (Int32?) -> Void) {
            self.onProcessTerminated = onProcessTerminated
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            let callback = onProcessTerminated
            Task { @MainActor in
                callback(exitCode)
            }
        }
    }
}
