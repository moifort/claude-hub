import SwiftUI

struct GitTreePanel: View {
    let repoPath: String
    let projectName: String

    @State private var viewModel = GitTreeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            content
        }
        .task(id: repoPath) {
            await viewModel.load(repoPath: repoPath)
        }
        .onDisappear {
            viewModel.stopWatching()
        }
    }

    private var header: some View {
        HStack {
            Label("Git History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
            GitTreeList(rows: graph.rows)
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
