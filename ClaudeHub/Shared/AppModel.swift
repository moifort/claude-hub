import SwiftUI
import SwiftData

@Observable @MainActor
final class AppModel {
    var selectedItemID: PersistentIdentifier?
    var showInspector = false
    var showGitTree: Bool
    var gitTreeRefreshTrigger = 0
    var windowSize: CGSize = .zero

    init() {
        showGitTree = UserDefaults.standard.object(forKey: "gitPanelOpenByDefault") as? Bool ?? true
    }
}
