import SwiftUI
import SwiftTerm

struct TerminalRepresentable: NSViewRepresentable {
    let taskSlug: String

    @Environment(TerminalSessionManager.self) private var sessionManager

    func makeNSView(context: Context) -> NSView {
        guard let terminal = sessionManager.cachedTerminalView(for: taskSlug) else {
            return NSView()
        }
        let wrapper = TerminalWrapperView(terminal: terminal)
        return wrapper
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Prevents SwiftTerm from receiving a zero-width frame during SwiftUI's
/// initial layout pass, which would cause text to render 1 char per line.
private final class TerminalWrapperView: NSView {
    let terminal: LocalProcessTerminalView

    init(terminal: LocalProcessTerminalView) {
        self.terminal = terminal
        super.init(frame: terminal.frame)
        terminal.autoresizingMask = [.width, .height]
        addSubview(terminal)

        for subview in terminal.subviews {
            if let scroller = subview as? NSScroller {
                scroller.scrollerStyle = .overlay
                scroller.alphaValue = 0.5
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        if bounds.width > 1, bounds.height > 1 {
            terminal.frame = bounds
        }
    }
}
