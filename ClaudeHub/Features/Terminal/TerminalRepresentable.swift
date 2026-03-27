import SwiftUI
import SwiftTerm

struct TerminalRepresentable: NSViewRepresentable {
    let taskSlug: String

    @Environment(TerminalSessionManager.self) private var sessionManager

    func makeNSView(context: Context) -> NSView {
        guard let terminal = sessionManager.cachedTerminalView(for: taskSlug) else {
            return NSView()
        }
        return terminal
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
