import SwiftUI
import SwiftData

@Observable @MainActor
final class AppModel {
    var selectedProjectID: PersistentIdentifier?
    var selectedTaskID: PersistentIdentifier?
    var showInspector = false
    var windowSize: CGSize = .zero

    var hasTaskSelection: Bool { selectedTaskID != nil }
}
