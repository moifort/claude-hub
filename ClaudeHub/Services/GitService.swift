import Foundation

enum GitService {
    static func isGitRepository(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: (path as NSString).appendingPathComponent(".git"))
    }

    static func repositoryName(at path: String) -> String {
        (path as NSString).lastPathComponent
    }

    static func createWorktree(repoPath: String, slug: String) async throws -> String {
        let worktreePath = (repoPath as NSString).appendingPathComponent("task/\(slug)")
        let branchName = "task/\(slug)"
        try await runGit(in: repoPath, args: ["worktree", "add", worktreePath, "-b", branchName])
        return worktreePath
    }

    static func removeWorktree(repoPath: String, slug: String) async throws {
        let worktreePath = (repoPath as NSString).appendingPathComponent("task/\(slug)")
        let branchName = "task/\(slug)"
        try await runGit(in: repoPath, args: ["worktree", "remove", worktreePath, "--force"])
        _ = try? await runGit(in: repoPath, args: ["branch", "-D", branchName])
    }

    static func worktreePath(repoPath: String, slug: String) -> String {
        (repoPath as NSString).appendingPathComponent("task/\(slug)")
    }

    // MARK: - Push

    static func pushMain(repoPath: String) async throws {
        try await runGit(in: repoPath, args: ["push", "origin", "main"])
    }

    // MARK: - Commit Log

    static func fetchCommitLog(repoPath: String, maxCount: Int = 200) async throws -> [GitCommit] {
        let output = try await runGit(in: repoPath, args: [
            "log", "main", "--first-parent", "--topo-order",
            "--format=%H%x00%P%x00%an%x00%aI%x00%s%x00%D",
            "--max-count=\(maxCount)",
        ])
        return parseCommitLog(output)
    }

    static func buildGraph(from commits: [GitCommit]) -> GitGraph {
        let rows = commits.enumerated().map { index, commit in
            GitGraphRow(
                id: commit.id,
                commit: commit,
                isFirst: index == 0,
                isLast: index == commits.count - 1
            )
        }
        return GitGraph(rows: rows)
    }

    private static func parseCommitLog(_ output: String) -> [GitCommit] {
        let separator = Character("\0")
        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> GitCommit? in
                let fields = line.split(separator: separator, omittingEmptySubsequences: false)
                guard fields.count >= 6 else { return nil }

                let hash = String(fields[0])
                let parents = fields[1].isEmpty
                    ? []
                    : fields[1].split(separator: " ").map(String.init)
                let author = String(fields[2])
                let date = ISO8601DateFormatter().date(from: String(fields[3])) ?? .now
                let subject = String(fields[4])
                let refs = parseRefs(String(fields[5]))

                return GitCommit(
                    id: hash,
                    parentIDs: parents,
                    authorName: author,
                    date: date,
                    subject: subject,
                    refs: refs
                )
            }
    }

    private static func parseRefs(_ raw: String) -> [GitRef] {
        guard !raw.isEmpty else { return [] }
        return raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap { ref -> GitRef? in
                if ref.hasPrefix("HEAD -> ") {
                    let name = String(ref.dropFirst("HEAD -> ".count))
                    return GitRef(name: name, kind: .head, isCurrent: true)
                } else if ref == "HEAD" {
                    return GitRef(name: "HEAD", kind: .head, isCurrent: true)
                } else if ref.hasPrefix("tag: ") {
                    let name = String(ref.dropFirst("tag: ".count))
                    return GitRef(name: name, kind: .tag, isCurrent: false)
                } else if ref.hasPrefix("origin/") {
                    return GitRef(name: ref, kind: .remoteBranch, isCurrent: false)
                } else {
                    return GitRef(name: ref, kind: .localBranch, isCurrent: false)
                }
            }
    }

    @discardableResult
    private static func runGit(in directory: String, args: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", directory] + args
        process.environment = ProcessInfo.processInfo.environment

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw GitError.commandFailed(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return output
    }
}

enum GitError: LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message): message
        }
    }
}
