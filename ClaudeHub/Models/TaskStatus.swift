import SwiftUI

enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case running
    case waiting
    case completed
    case archived

    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .running: "Running"
        case .waiting: "Waiting"
        case .completed: "Completed"
        case .archived: "Archived"
        }
    }

    var iconName: String {
        switch self {
        case .pending: "clock"
        case .running: "play.circle.fill"
        case .waiting: "questionmark.circle.fill"
        case .completed: "checkmark.circle.fill"
        case .archived: "archivebox.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .pending: .secondary
        case .running: .green
        case .waiting: .orange
        case .completed: .green
        case .archived: .secondary
        }
    }

    var sortPriority: Int {
        switch self {
        case .waiting: 0
        case .running: 1
        case .pending: 2
        case .completed: 3
        case .archived: 4
        }
    }
}
