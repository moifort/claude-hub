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

    func registerSession(
        for slug: String,
        executable: String,
        arguments: [String],
        workingDirectory: String,
        environment: [String]?
    ) {
        activeSessions[slug] = SessionInfo(
            executable: executable,
            arguments: arguments,
            workingDirectory: workingDirectory,
            environment: environment
        )
    }

    func session(for slug: String) -> SessionInfo? {
        activeSessions[slug]
    }

    func cachedTerminalView(for slug: String) -> LocalProcessTerminalView? {
        terminalViews[slug]
    }

    func storeTerminalView(_ view: LocalProcessTerminalView, for slug: String) {
        terminalViews[slug] = view
    }

    func removeSession(for slug: String) {
        activeSessions[slug] = nil
        terminalViews[slug] = nil
    }

    func removeAll() {
        activeSessions.removeAll()
        terminalViews.removeAll()
    }
}
