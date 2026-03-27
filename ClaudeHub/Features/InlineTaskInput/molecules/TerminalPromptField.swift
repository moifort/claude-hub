import SwiftUI
import SwiftTerm

struct TerminalPromptField: View {
    @Binding var text: String
    let isDisabled: Bool
    let onSubmit: () -> Void

    var body: some View {
        PromptTerminalRepresentable(
            text: $text,
            isDisabled: isDisabled,
            onSubmit: onSubmit
        )
        .frame(height: 80)
        .clipShape(.rect(cornerRadius: Constants.cornerRadius))
    }
}

// MARK: - NSViewRepresentable

private struct PromptTerminalRepresentable: NSViewRepresentable {
    @Binding var text: String
    let isDisabled: Bool
    let onSubmit: () -> Void

    func makeNSView(context: Context) -> TerminalView {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 600, height: 80), font: nil)
        terminalView.terminalDelegate = context.coordinator

        configureAppearance(terminalView)
        showPrompt(terminalView)

        context.coordinator.terminalView = terminalView
        DispatchQueue.main.async {
            terminalView.window?.makeFirstResponder(terminalView)
        }

        return terminalView
    }

    func updateNSView(_ terminalView: TerminalView, context: Context) {
        let coordinator = context.coordinator

        if text.isEmpty && !coordinator.currentInput.isEmpty {
            coordinator.currentInput = ""
            resetTerminal(terminalView)
        }

        coordinator.isDisabled = isDisabled
        coordinator.onSubmit = onSubmit
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    private func configureAppearance(_ terminalView: TerminalView) {
        let bgColor = NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 0.9)
        let fgColor = NSColor(red: 0.40, green: 0.87, blue: 0.40, alpha: 1.0)

        terminalView.nativeBackgroundColor = bgColor
        terminalView.nativeForegroundColor = fgColor
        terminalView.caretColor = NSColor(red: 0.40, green: 0.87, blue: 0.40, alpha: 1.0)
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

        terminalView.wantsLayer = true
        terminalView.layer?.backgroundColor = bgColor.cgColor

        terminalView.getTerminal().setCursorStyle(.blinkBlock)
    }

    private func showPrompt(_ terminalView: TerminalView) {
        terminalView.feed(text: "\u{1b}[1;32m❯\u{1b}[0m ")
    }

    private func resetTerminal(_ terminalView: TerminalView) {
        terminalView.feed(text: "\u{1b}[2J\u{1b}[H")
        showPrompt(terminalView)
    }
}

// MARK: - Coordinator

extension PromptTerminalRepresentable {
    final class Coordinator: NSObject, TerminalViewDelegate, @unchecked Sendable {
        @Binding var text: String
        var onSubmit: () -> Void
        var isDisabled = false
        var currentInput = ""
        weak var terminalView: TerminalView?

        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            _text = text
            self.onSubmit = onSubmit
        }

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            guard !isDisabled else { return }

            let bytes = Array(data)

            if bytes == [13] {
                let input = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !input.isEmpty else { return }
                text = input
                onSubmit()
                return
            }

            if bytes == [127] {
                guard !currentInput.isEmpty else { return }
                currentInput.removeLast()
                text = currentInput
                source.feed(text: "\u{08} \u{08}")
                return
            }

            if let str = String(bytes: bytes, encoding: .utf8) {
                currentInput += str
                text = currentInput
                source.feed(byteArray: ArraySlice(bytes))
            }
        }

        func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: TerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        func scrolled(source: TerminalView, position: Double) {}
        func clipboardCopy(source: TerminalView, content: Data) {}
        func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {}
        func bell(source: TerminalView) {}
        func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {}
        func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}
    }
}

#Preview {
    @Previewable @State var text = ""

    TerminalPromptField(
        text: $text,
        isDisabled: false,
        onSubmit: {}
    )
    .padding()
    .frame(width: 600)
}
