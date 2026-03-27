import SwiftUI
import SwiftData

@Observable @MainActor
final class AppModel {
    var selectedItemID: PersistentIdentifier?
    var showInspector = false
    var windowSize: CGSize = .zero
}
