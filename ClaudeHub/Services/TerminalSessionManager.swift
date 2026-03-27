import Foundation
import SwiftData

@Observable @MainActor
final class TerminalSessionManager {
    struct SessionInfo {
        let executable: String
        let arguments: [String]
        let workingDirectory: String
        let environment: [String]?
    }

    private(set) var activeSessions: [PersistentIdentifier: SessionInfo] = [:]

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

    func removeSession(for taskID: PersistentIdentifier) {
        activeSessions[taskID] = nil
    }

    func removeAll() {
        activeSessions.removeAll()
    }
}
