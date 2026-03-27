import SwiftUI

struct TaskSettingsSection: View {
    @Binding var systemPrompt: String

    var body: some View {
        Form {
            Section {
                TextEditor(text: $systemPrompt)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.black.opacity(0.3))
                    .clipShape(.rect(cornerRadius: 8))
                    .frame(minHeight: 350)
            } header: {
                HStack {
                    Text("System Prompt")
                    Spacer()
                    Button("Reset to Default") {
                        systemPrompt = DefaultSystemPrompt.taskSystemPrompt
                    }
                }
            } footer: {
                Text("Markdown instructions injected into every Claude Code task session.")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    @Previewable @State var prompt = DefaultSystemPrompt.taskSystemPrompt

    TaskSettingsSection(systemPrompt: $prompt)
        .frame(width: 600, height: 500)
}
