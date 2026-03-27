import SwiftUI

enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case running
    case waiting
    case planReady
    case completed
    case archived

    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .running: "Running"
        case .waiting: "Waiting"
        case .planReady: "Plan Ready"
        case .completed: "Completed"
        case .archived: "Archived"
        }
    }

    var iconName: String {
        switch self {
        case .pending: "clock"
        case .running: "play.circle.fill"
        case .waiting: "questionmark.circle.fill"
        case .planReady: "doc.text.magnifyingglass"
        case .completed: "checkmark.circle.fill"
        case .archived: "archivebox.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .pending: .secondary
        case .running: .green
        case .waiting: .orange
        case .planReady: .purple
        case .completed: .green
        case .archived: .secondary
        }
    }

    var sortPriority: Int {
        switch self {
        case .planReady: 0
        case .waiting: 0
        case .running: 1
        case .pending: 2
        case .completed: 3
        case .archived: 4
        }
    }
}
