import SwiftUI

struct GitTreePanel: View {
    let repoPath: String
    let projectName: String
    var refreshTrigger: Int = 0

    @State private var viewModel = GitTreeViewModel()

    var body: some View {
        content
        .task(id: repoPath) {
            await viewModel.load(repoPath: repoPath)
        }
        .onChange(of: refreshTrigger) {
            Task { await viewModel.refresh() }
        }
        .onDisappear {
            viewModel.stopWatching()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.graph == nil {
            Spacer()
            ProgressView()
                .controlSize(.small)
            Spacer()
        } else if let error = viewModel.errorMessage, viewModel.graph == nil {
            ContentUnavailableView(
                "Unable to load history",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else if let graph = viewModel.graph, !graph.rows.isEmpty {
            GitTreeList(rows: graph.rows, uncommittedCount: viewModel.uncommittedCount)
        } else {
            ContentUnavailableView(
                "No commits",
                systemImage: "clock",
                description: Text("No commits found on main.")
            )
        }
    }
}

#Preview {
    GitTreePanel(repoPath: "/tmp/fake-repo", projectName: "my-project")
        .frame(width: 400, height: 500)
}
