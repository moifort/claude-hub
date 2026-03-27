import Foundation
import SwiftUI

@Observable @MainActor
final class GitTreeViewModel {
    private(set) var graph: GitGraph?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private var currentRepoPath: String?
    private var fileMonitor: (any DispatchSourceFileSystemObject)?
    private var fileDescriptor: Int32 = -1

    func load(repoPath: String) async {
        guard repoPath != currentRepoPath || graph == nil else { return }
        currentRepoPath = repoPath
        isLoading = true
        errorMessage = nil

        do {
            let commits = try await GitService.fetchCommitLog(repoPath: repoPath)
            graph = GitService.buildGraph(from: commits)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        startWatching(repoPath: repoPath)
    }

    func refresh() async {
        guard let path = currentRepoPath else { return }
        isLoading = true
        errorMessage = nil

        do {
            let commits = try await GitService.fetchCommitLog(repoPath: path)
            graph = GitService.buildGraph(from: commits)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func stopWatching() {
        fileMonitor?.cancel()
        fileMonitor = nil
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func startWatching(repoPath: String) {
        stopWatching()

        let refPath = (repoPath as NSString).appendingPathComponent(".git/refs/heads/main")
        let fd = open(refPath, O_EVTONLY)
        guard fd >= 0 else { return }

        fileDescriptor = fd
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.refresh()
            }
        }
        source.setCancelHandler { [fd] in
            close(fd)
        }
        source.resume()
        fileMonitor = source
    }

}
