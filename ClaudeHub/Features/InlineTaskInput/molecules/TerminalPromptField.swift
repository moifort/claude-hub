import SwiftUI

struct TerminalPromptField: View {
    @Binding var text: String
    let isDisabled: Bool
    let onSubmit: () -> Void

    @State private var contentHeight: CGFloat = 20

    @MainActor private static let monoFont = NSFont.monospacedSystemFont(ofSize: 14, weight: NSFont.Weight.regular)
    @MainActor private static let promptFont = NSFont.monospacedSystemFont(ofSize: 14, weight: NSFont.Weight.medium)
    private static let green = NSColor(red: 0.40, green: 0.85, blue: 0.45, alpha: 1)
    private static let minHeight: CGFloat = 20
    private static let maxHeight: CGFloat = 160

    private var clampedHeight: CGFloat {
        min(max(contentHeight, Self.minHeight), Self.maxHeight)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("❯")
                .font(Font(Self.promptFont))
                .foregroundStyle(Color(Self.green))

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Describe what you want to build...")
                        .font(Font(Self.monoFont))
                        .foregroundStyle(.white.opacity(0.2))
                }

                PromptTextView(
                    text: $text,
                    contentHeight: $contentHeight,
                    font: Self.monoFont,
                    textColor: Self.green,
                    isDisabled: isDisabled,
                    onSubmit: onSubmit
                )
                .frame(height: clampedHeight)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.black.opacity(0.85))
        .clipShape(.rect(cornerRadius: Constants.cornerRadius))
        .animation(.snappy(duration: 0.15), value: clampedHeight)
    }
}

// MARK: - NSViewRepresentable

private struct PromptTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var contentHeight: CGFloat
    let font: NSFont
    let textColor: NSColor
    let isDisabled: Bool
    let onSubmit: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let textView = scrollView.documentView as! NSTextView
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        textView.insertionPointColor = textColor
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.delegate = context.coordinator

        context.coordinator.textView = textView

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.onSubmit = onSubmit

        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
            context.coordinator.updateHeight()
        }
        textView.isEditable = !isDisabled
        textView.isSelectable = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, contentHeight: $contentHeight, onSubmit: onSubmit)
    }
}

// MARK: - Coordinator

extension PromptTextView {
    final class Coordinator: NSObject, NSTextViewDelegate, @unchecked Sendable {
        var text: Binding<String>
        var contentHeight: Binding<CGFloat>
        var onSubmit: () -> Void
        weak var textView: NSTextView?

        init(text: Binding<String>, contentHeight: Binding<CGFloat>, onSubmit: @escaping () -> Void) {
            self.text = text
            self.contentHeight = contentHeight
            self.onSubmit = onSubmit
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            updateHeight()
        }

        func textView(_ textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) {
                let shiftHeld = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
                if shiftHeld {
                    return false
                }
                onSubmit()
                return true
            }
            return false
        }

        func updateHeight() {
            guard let textView, let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }
            layoutManager.ensureLayout(for: textContainer)
            let height = layoutManager.usedRect(for: textContainer).height
            let newHeight = max(height, 20)
            if abs(contentHeight.wrappedValue - newHeight) > 0.5 {
                contentHeight.wrappedValue = newHeight
            }
        }
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

#Preview("With text") {
    @Previewable @State var text = "Build a REST API that handles\nauthentication and user management"

    TerminalPromptField(
        text: $text,
        isDisabled: false,
        onSubmit: {}
    )
    .padding()
    .frame(width: 600)
}
