import SwiftUI
import SwiftData

struct InlineTaskInputPage: View {
    let project: Project

    @Environment(AppModel.self) private var appModel
    @Environment(TerminalSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = InlineTaskInputViewModel()
    @State private var taskViewModel = TaskListViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "terminal")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text(project.name)
                    .font(.title2)
                    .foregroundStyle(.primary)

                Text("Enter to submit \u{2022} Shift+Enter for new line")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            TerminalPromptField(
                text: $viewModel.prompt,
                isDisabled: viewModel.isSummarizing,
                onSubmit: { submit() }
            )
            .frame(maxWidth: 600)

            if viewModel.isSummarizing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Summarizing...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.green.opacity(0.7))
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.orange)
            }

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func submit() {
        guard viewModel.canSubmit else { return }
        Task {
            await viewModel.submit(
                project: project,
                context: modelContext,
                sessionManager: sessionManager,
                taskViewModel: taskViewModel,
                appModel: appModel
            )
        }
    }
}

#Preview {
    @Previewable @State var appModel = AppModel()
    @Previewable @State var sessionManager = TerminalSessionManager()

    InlineTaskInputPage(
        project: Project(name: "my-project", path: "/tmp/my-project")
    )
    .environment(appModel)
    .environment(sessionManager)
    .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
    .frame(width: 800, height: 600)
}
