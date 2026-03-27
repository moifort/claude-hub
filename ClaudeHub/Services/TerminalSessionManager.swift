import Foundation
import SwiftData
import SwiftTerm

@Observable @MainActor
final class TerminalSessionManager {
    struct SessionInfo {
        let executable: String
        let arguments: [String]
        let workingDirectory: String
        let environment: [String]?
    }

    private(set) var activeSessions: [PersistentIdentifier: SessionInfo] = [:]
    private var terminalViews: [PersistentIdentifier: LocalProcessTerminalView] = [:]

    func registerSession(
        for taskID: PersistentIdentifier,
        executable: String,
        arguments: [String],
        workingDirectory: String,
        environment: [String]?
    ) {
        activeSessions[taskID] = SessionInfo(
            executable: executable,
            arguments: arguments,
            workingDirectory: workingDirectory,
            environment: environment
        )
    }

    func session(for taskID: PersistentIdentifier) -> SessionInfo? {
        activeSessions[taskID]
    }

    func cachedTerminalView(for taskID: PersistentIdentifier) -> LocalProcessTerminalView? {
        terminalViews[taskID]
    }

    func storeTerminalView(_ view: LocalProcessTerminalView, for taskID: PersistentIdentifier) {
        terminalViews[taskID] = view
    }

    func removeSession(for taskID: PersistentIdentifier) {
        activeSessions[taskID] = nil
        terminalViews[taskID] = nil
    }

    func removeAll() {
        activeSessions.removeAll()
        terminalViews.removeAll()
    }
}
