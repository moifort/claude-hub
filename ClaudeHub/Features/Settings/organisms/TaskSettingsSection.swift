import SwiftUI

struct TaskSettingsSection: View {
    @Binding var systemPrompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Prompt")
                        .font(.headline)
                    Text("Markdown instructions injected into every Claude Code task session.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Reset to Default") {
                    systemPrompt = DefaultSystemPrompt.taskSystemPrompt
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            TextEditor(text: $systemPrompt)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: 400)
        }
    }
}

#Preview {
    @Previewable @State var prompt = DefaultSystemPrompt.taskSystemPrompt

    TaskSettingsSection(systemPrompt: $prompt)
        .padding()
        .frame(width: 600, height: 500)
}
