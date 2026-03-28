import Foundation
import SwiftTerm

@Observable @MainActor
final class TerminalSessionManager {
    struct SessionInfo {
        let executable: String
        let arguments: [String]
        let workingDirectory: String
        let environment: [String]?
    }

    private(set) var activeSessions: [String: SessionInfo] = [:]
    private var terminalViews: [String: LocalProcessTerminalView] = [:]
    private var delegates: [String: SessionDelegate] = [:]

    func launchSession(
        for slug: String,
        executable: String,
        arguments: [String],
        workingDirectory: String,
        environment: [String]?,
        initialSize: CGSize = CGSize(width: 600, height: 400),
        onProcessTerminated: @MainActor @Sendable @escaping (Int32?) -> Void
    ) {
        guard activeSessions[slug] == nil else { return }

        activeSessions[slug] = SessionInfo(
            executable: executable,
            arguments: arguments,
            workingDirectory: workingDirectory,
            environment: environment
        )

        let terminal = LocalProcessTerminalView(frame: NSRect(origin: .zero, size: initialSize))
        let delegate = SessionDelegate(onProcessTerminated: onProcessTerminated)
        terminal.processDelegate = delegate
        terminal.startProcess(
            executable: executable,
            args: arguments,
            environment: environment,
            currentDirectory: workingDirectory
        )

        delegates[slug] = delegate
        terminalViews[slug] = terminal
    }

    func session(for slug: String) -> SessionInfo? {
        activeSessions[slug]
    }

    func cachedTerminalView(for slug: String) -> LocalProcessTerminalView? {
        terminalViews[slug]
    }

    var hasRunningSessions: Bool {
        terminalViews.values.contains { $0.process.running }
    }

    func removeSession(for slug: String) {
        terminalViews[slug]?.terminate()
        activeSessions[slug] = nil
        terminalViews[slug] = nil
        delegates[slug] = nil
    }

    func removeAll() {
        for view in terminalViews.values {
            view.terminate()
        }
        activeSessions.removeAll()
        terminalViews.removeAll()
        delegates.removeAll()
    }
}

final class SessionDelegate: NSObject, LocalProcessTerminalViewDelegate, @unchecked Sendable {
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
