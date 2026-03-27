import SwiftUI

struct TerminalPromptField: View {
    @Binding var text: String
    let isDisabled: Bool
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(">")
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(.green)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Describe what you want to build...")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }

                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.green)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .disabled(isDisabled)
                    .frame(minHeight: 24)
                    .onKeyPress(.return, phases: .down) { press in
                        if press.modifiers.contains(.shift) {
                            return .ignored
                        }
                        onSubmit()
                        return .handled
                    }
            }
        }
        .padding(16)
        .background(.black.opacity(0.85))
        .clipShape(.rect(cornerRadius: 12))
        .onAppear { isFocused = true }
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
