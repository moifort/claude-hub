import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var path: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.project)
    var tasks: [TaskItem]

    var activeTasks: [TaskItem] {
        tasks.filter { $0.taskStatus != .archived }
    }

    var runningTaskCount: Int {
        tasks.filter { $0.taskStatus == .running }.count
    }

    init(name: String, path: String) {
        self.name = name
        self.path = path
        self.createdAt = .now
        self.tasks = []
    }
}
