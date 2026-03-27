import SwiftUI
import SwiftData

struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let project: Project

    @State private var viewModel = NewTaskViewModel()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("New Task")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }

            Text("Describe what you want to accomplish in **\(project.name)**. The task will be automatically decomposed into parallel subtasks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TaskPromptEditor(
                text: $viewModel.prompt,
                placeholder: "Add authentication with OAuth2, implement the login flow, and add unit tests...",
                isDisabled: viewModel.isDecomposing,
                onSubmit: { submit() }
            )

            DecompositionProgress(
                isDecomposing: viewModel.isDecomposing,
                subtaskCount: viewModel.subtaskCount,
                errorMessage: viewModel.errorMessage
            )

            HStack {
                Spacer()

                if viewModel.subtaskCount != nil {
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Submit") { submit() }
                        .keyboardShortcut(.return, modifiers: .command)
                        .disabled(!viewModel.canSubmit)
                }
            }
        }
        .padding(20)
        .frame(width: 500, height: 350)
    }

    private func submit() {
        guard viewModel.canSubmit else { return }
        Task {
            await viewModel.decompose(for: project, in: modelContext)
        }
    }
}

#Preview {
    @Previewable @State var project = Project(name: "my-project", path: "/tmp/my-project")

    NewTaskSheet(project: project)
        .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
}
