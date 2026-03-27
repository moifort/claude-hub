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
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)

                Text(project.name)
                    .font(.title3)
                    .foregroundStyle(.primary)

                Text("Enter to submit \u{2022} Shift+Enter for new line")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            PromptField(
                text: $viewModel.prompt,
                isDisabled: viewModel.isDecomposing,
                isLoading: viewModel.isDecomposing,
                onSubmit: { submit() }
            )
            .frame(maxWidth: 600)

            InlineDecompositionProgress(
                isDecomposing: viewModel.isDecomposing,
                subtaskCount: viewModel.subtaskCount,
                errorMessage: viewModel.errorMessage
            )

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
