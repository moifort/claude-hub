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
