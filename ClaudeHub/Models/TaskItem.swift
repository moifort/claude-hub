import Foundation
import SwiftData

@Model
final class TaskItem {
    var title: String
    var prompt: String
    var status: String
    var isPinned: Bool
    var createdAt: Date
    var completedAt: Date?
    var archivedAt: Date?
    var summary: String?
    var parentTaskTitle: String?
    var slug: String

    var project: Project?

    var taskStatus: TaskStatus {
        get { TaskStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }

    init(
        title: String,
        prompt: String,
        slug: String,
        summary: String? = nil,
        parentTaskTitle: String? = nil,
        project: Project? = nil
    ) {
        self.title = title
        self.prompt = prompt
        self.slug = slug
        self.summary = summary
        self.status = TaskStatus.pending.rawValue
        self.isPinned = false
        self.createdAt = .now
        self.parentTaskTitle = parentTaskTitle
        self.project = project
    }

    static func generateSlug(from title: String) -> String {
        let base = title
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
            .prefix(50)
        let suffix = UUID().uuidString.prefix(6).lowercased()
        return "\(base)-\(suffix)"
    }
}
