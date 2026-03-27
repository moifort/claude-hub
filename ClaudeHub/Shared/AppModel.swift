import SwiftUI
import SwiftData

@Observable @MainActor
final class AppModel {
    var selectedItemID: PersistentIdentifier?
    var showInspector = false
    var showGitTree = true
    var gitTreeRefreshTrigger = 0
    var windowSize: CGSize = .zero
}
