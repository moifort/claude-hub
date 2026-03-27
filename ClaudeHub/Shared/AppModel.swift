import SwiftUI
import SwiftData

@Observable @MainActor
final class AppModel {
    var selectedItemID: PersistentIdentifier?
    var showInspector = false
    var showGitTree = true
    var gitTreeWidth: CGFloat = 380
    var gitTreeRefreshTrigger = 0
    var windowSize: CGSize = .zero
}
