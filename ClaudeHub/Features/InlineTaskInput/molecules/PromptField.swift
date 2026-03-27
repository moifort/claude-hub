import SwiftUI

struct PromptField: View {
    @Binding var text: String
    let isDisabled: Bool
    let isLoading: Bool
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDisabled
    }

    var body: some View {
        GlassEffectContainer(spacing: Constants.glassSpacing) {
            HStack(alignment: .bottom, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .center)

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Describe what you want to build...")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                    }

                    TextEditor(text: $text)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden)
                        .focused($isFocused)
                        .disabled(isDisabled)
                        .frame(minHeight: 24, maxHeight: 120)
                        .fixedSize(horizontal: false, vertical: true)
                        .onKeyPress(.return, phases: .down) { press in
                            if press.modifiers.contains(.shift) { return .ignored }
                            if canSubmit { onSubmit() }
                            return .handled
                        }
                }

                SubmitButton(
                    isEnabled: canSubmit,
                    isLoading: isLoading,
                    action: onSubmit
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .rect(cornerRadius: Constants.cornerRadius))
        }
        .onAppear { isFocused = true }
    }
}

#Preview {
    @Previewable @State var text = ""

    PromptField(
        text: $text,
        isDisabled: false,
        isLoading: false,
        onSubmit: {}
    )
    .padding(32)
    .frame(width: 600)
}

#Preview("With text") {
    @Previewable @State var text = "Add OAuth2 authentication with Google Sign-In"

    PromptField(
        text: $text,
        isDisabled: false,
        isLoading: false,
        onSubmit: {}
    )
    .padding(32)
    .frame(width: 600)
}

#Preview("Loading") {
    @Previewable @State var text = "Add OAuth2 authentication"

    PromptField(
        text: $text,
        isDisabled: true,
        isLoading: true,
        onSubmit: {}
    )
    .padding(32)
    .frame(width: 600)
}
