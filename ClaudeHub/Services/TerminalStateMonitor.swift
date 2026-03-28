import Foundation
import SwiftTerm

@Observable @MainActor
final class TerminalStateMonitor {
    private(set) var detectedStates: [String: DetectedState] = [:]

    private var timer: Timer?
    private weak var sessionManager: TerminalSessionManager?
    private var previousSnapshots: [String: String] = [:]
    private var stablePolls: [String: Int] = [:]
    private let stableThreshold = 3

    enum DetectedState: Sendable {
        case working
        case waiting
        case planReady
        case done

        var priority: Int {
            switch self {
            case .working: 4
            case .planReady: 3
            case .done: 2
            case .waiting: 1
            }
        }
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
        previousSnapshots[slug] = nil
        stablePolls[slug] = nil
    }

    private func scanAllSessions() {
        guard let sessionManager else { return }
        for slug in sessionManager.activeSessions.keys {
            guard let terminalView = sessionManager.cachedTerminalView(for: slug) else { continue }
            let state = scanBuffer(terminalView, slug: slug)
            if let state {
                detectedStates[slug] = state
            }
        }
    }

    // MARK: - Configurable Patterns

    private func loadPatterns() -> [(keyword: String, state: DetectedState)] {
        let defaults = UserDefaults.standard
        let working = defaults.string(forKey: "markersWorking") ?? "◆ working"
        let waiting = defaults.string(forKey: "markersWaiting") ?? "◆ waiting,Chat about this,Skip interview"
        let planReady = defaults.string(forKey: "markersPlanReady") ?? "Ready to code?,bypass permissions,manually approve edits"
        let done = defaults.string(forKey: "markersDone") ?? "◆ done"

        var result: [(String, DetectedState)] = []
        for kw in planReady.split(separator: ",") { result.append((kw.trimmingCharacters(in: .whitespaces), .planReady)) }
        for kw in done.split(separator: ",") { result.append((kw.trimmingCharacters(in: .whitespaces), .done)) }
        for kw in waiting.split(separator: ",") { result.append((kw.trimmingCharacters(in: .whitespaces), .waiting)) }
        for kw in working.split(separator: ",") { result.append((kw.trimmingCharacters(in: .whitespaces), .working)) }
        return result
    }

    // MARK: - Buffer Scanning

    private func scanBuffer(_ terminalView: LocalProcessTerminalView, slug: String) -> DetectedState? {
        let terminal = terminalView.getTerminal()
        let rows = terminal.rows
        let linesToScan = min(30, rows)
        let patterns = loadPatterns()

        // 1. Keyword detection — highest priority wins
        var bufferLines: [String] = []
        var bestMarkerState: DetectedState?
        for row in (rows - linesToScan)..<rows {
            guard let line = terminal.getLine(row: row) else { continue }
            let text = line.translateToString(trimRight: true)
            bufferLines.append(text)
            for (keyword, state) in patterns where text.contains(keyword) {
                if state.priority > (bestMarkerState?.priority ?? 0) {
                    bestMarkerState = state
                }
                break
            }
        }

        if let bestMarkerState {
            previousSnapshots[slug] = nil
            stablePolls[slug] = 0
            return bestMarkerState
        }

        // 2. Instability fallback — compare buffer snapshots between polls
        let currentSnapshot = bufferLines.joined(separator: "\n")
        defer { previousSnapshots[slug] = currentSnapshot }

        guard let previousSnapshot = previousSnapshots[slug] else {
            return nil
        }

        if currentSnapshot != previousSnapshot {
            stablePolls[slug] = 0
            return .working
        }

        let count = (stablePolls[slug] ?? 0) + 1
        stablePolls[slug] = count
        return count >= stableThreshold ? .waiting : nil
    }
}
