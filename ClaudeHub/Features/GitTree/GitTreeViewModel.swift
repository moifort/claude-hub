import Foundation
import SwiftUI

@Observable @MainActor
final class GitTreeViewModel {
    private(set) var graph: GitGraph?
    private(set) var uncommittedCount: Int = 0
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private var currentRepoPath: String?
    private var refMonitor: (any DispatchSourceFileSystemObject)?
    private var indexMonitor: (any DispatchSourceFileSystemObject)?
    private var refFD: Int32 = -1
    private var indexFD: Int32 = -1
    private var debounceTask: Task<Void, Never>?

    func load(repoPath: String) async {
        guard repoPath != currentRepoPath || graph == nil else { return }
        currentRepoPath = repoPath
        isLoading = true
        errorMessage = nil

        do {
            async let commitsTask = GitService.fetchCommitLog(repoPath: repoPath)
            async let countTask = GitService.fetchUncommittedCount(repoPath: repoPath)
            let commits = try await commitsTask
            graph = GitService.buildGraph(from: commits)
            uncommittedCount = (try? await countTask) ?? 0
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        startWatching(repoPath: repoPath)
    }

    func refresh() async {
        guard let path = currentRepoPath else { return }
        // Silent refresh — no isLoading change to avoid view reconstruction
        do {
            async let commitsTask = GitService.fetchCommitLog(repoPath: path)
            async let countTask = GitService.fetchUncommittedCount(repoPath: path)
            let commits = try await commitsTask
            graph = GitService.buildGraph(from: commits)
            uncommittedCount = (try? await countTask) ?? 0
            errorMessage = nil
        } catch {
            // Silently ignore refresh errors — keep showing last known graph
        }
    }

    func stopWatching() {
        refMonitor?.cancel()
        refMonitor = nil
        indexMonitor?.cancel()
        indexMonitor = nil
        if refFD >= 0 { close(refFD); refFD = -1 }
        if indexFD >= 0 { close(indexFD); indexFD = -1 }
    }

    private func startWatching(repoPath: String) {
        stopWatching()

        refMonitor = makeMonitor(
            path: (repoPath as NSString).appendingPathComponent(".git/refs/heads/main"),
            fd: &refFD
        )
        indexMonitor = makeMonitor(
            path: (repoPath as NSString).appendingPathComponent(".git/index"),
            fd: &indexFD
        )
    }

    private func makeMonitor(path: String, fd: inout Int32) -> (any DispatchSourceFileSystemObject)? {
        let openedFD = open(path, O_EVTONLY)
        guard openedFD >= 0 else { return nil }
        fd = openedFD

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: openedFD,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            self.debounceTask?.cancel()
            self.debounceTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await self.refresh()
            }
        }
        source.setCancelHandler { [openedFD] in
            close(openedFD)
        }
        source.resume()
        return source
    }

}
