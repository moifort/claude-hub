import SwiftUI

struct TaskPromptEditor: View {
    @Binding var text: String
    let placeholder: String
    let isDisabled: Bool
    let onSubmit: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .disabled(isDisabled)
                .frame(minHeight: 120)

            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 8))
        .onSubmit(onSubmit)
    }
}

#Preview {
    @Previewable @State var text = ""

    TaskPromptEditor(
        text: $text,
        placeholder: "Describe what you want to accomplish...",
        isDisabled: false,
        onSubmit: {}
    )
    .padding()
    .frame(width: 500, height: 200)
}

#Preview("With text") {
    @Previewable @State var text = "Add authentication with OAuth2 and implement the login flow"

    TaskPromptEditor(
        text: $text,
        placeholder: "Describe what you want to accomplish...",
        isDisabled: false,
        onSubmit: {}
    )
    .padding()
    .frame(width: 500, height: 200)
}

#Preview("Disabled") {
    @Previewable @State var text = "Processing..."

    TaskPromptEditor(
        text: $text,
        placeholder: "Describe what you want to accomplish...",
        isDisabled: true,
        onSubmit: {}
    )
    .padding()
    .frame(width: 500, height: 200)
}
