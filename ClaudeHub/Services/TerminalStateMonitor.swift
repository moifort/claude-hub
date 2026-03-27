import Foundation
import SwiftTerm

@Observable @MainActor
final class TerminalStateMonitor {
    private(set) var detectedStates: [String: DetectedState] = [:]

    private var timer: Timer?
    private weak var sessionManager: TerminalSessionManager?

    enum DetectedState: Sendable {
        case working
        case waiting
        case done
    }

    func start(sessionManager: TerminalSessionManager) {
        self.sessionManager = sessionManager
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scanAllSessions()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func removeState(for slug: String) {
        detectedStates[slug] = nil
    }

    private func scanAllSessions() {
        guard let sessionManager else { return }
        for slug in sessionManager.activeSessions.keys {
            guard let terminalView = sessionManager.cachedTerminalView(for: slug) else { continue }
            let state = scanBuffer(terminalView)
            if let state {
                detectedStates[slug] = state
            }
        }
    }

    private static let markerWorking = "◆ working"
    private static let markerWaiting = "◆ waiting"
    private static let markerDone = "◆ done"

    private func scanBuffer(_ terminalView: LocalProcessTerminalView) -> DetectedState? {
        let terminal = terminalView.getTerminal()
        let rows = terminal.rows
        let linesToScan = min(30, rows)

        var lastMarkerState: DetectedState?

        for row in (rows - linesToScan)..<rows {
            guard let line = terminal.getLine(row: row) else { continue }
            let text = line.translateToString(trimRight: true)
            if text.contains(Self.markerDone) {
                lastMarkerState = .done
            } else if text.contains(Self.markerWaiting) {
                lastMarkerState = .waiting
            } else if text.contains(Self.markerWorking) {
                lastMarkerState = .working
            }
        }

        return lastMarkerState
    }
}
