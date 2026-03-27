import Foundation

enum CLIService {
    static func claudePath() -> String? {
        let candidates = [
            "/Applications/cmux.app/Contents/Resources/bin/claude",
            "/usr/local/bin/claude",
            NSHomeDirectory() + "/.claude/bin/claude",
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // Fallback: which claude
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["claude"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let path, !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) {
            return path
        }

        return nil
    }

    static func decomposeTask(prompt: String, projectPath: String) async throws -> [DecomposedTask] {
        guard let claude = claudePath() else {
            throw CLIError.claudeNotFound
        }

        let systemPrompt = """
        You are a task decomposition engine. Analyze the user's request and split it into \
        independent, parallelizable subtasks. Each subtask must be executable in its own \
        isolated git worktree without depending on other subtasks.

        Return ONLY a JSON array, no explanation, no markdown:
        [{"title": "short title", "prompt": "detailed instructions for Claude Code"}]

        If the task cannot be meaningfully split, return a single-element array.
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claude)
        process.arguments = ["--print", "-s", systemPrompt, prompt]
        process.currentDirectoryURL = URL(fileURLWithPath: projectPath)
        process.environment = ProcessInfo.processInfo.environment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = FileHandle.nullDevice

        try process.run()

        // Timeout after 60 seconds
        let timeoutTask = Task {
            try await Task.sleep(for: .seconds(60))
            if process.isRunning { process.terminate() }
        }

        process.waitUntilExit()
        timeoutTask.cancel()

        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw CLIError.decompositionFailed(output)
        }

        return try parseDecomposedTasks(from: output)
    }

    static func buildTaskSystemPrompt(projectPath: String, slug: String) -> String {
        let worktreePath = GitService.worktreePath(repoPath: projectPath, slug: slug)

        return """
        You are working in an isolated git worktree at \(worktreePath).
        Your branch is task/\(slug).

        RULES:
        - Work independently in this worktree. Do NOT modify the main branch directly.
        - Make commits as you work on your branch task/\(slug).
        - When your work is complete and verified:
          1. git checkout main
          2. git pull --rebase
          3. git merge --ff-only task/\(slug)
          4. git worktree remove \(worktreePath)
          5. git branch -d task/\(slug)
        - If the merge fails, rebase your branch first: git rebase main
        """
    }

    private static func parseDecomposedTasks(from output: String) throws -> [DecomposedTask] {
        // Find JSON array in output (may have text before/after)
        guard let startIndex = output.firstIndex(of: "["),
              let endIndex = output.lastIndex(of: "]") else {
            throw CLIError.invalidJSON(output)
        }

        let jsonString = String(output[startIndex...endIndex])
        let data = Data(jsonString.utf8)

        do {
            return try JSONDecoder().decode([DecomposedTask].self, from: data)
        } catch {
            throw CLIError.invalidJSON(jsonString)
        }
    }
}

enum CLIError: LocalizedError {
    case claudeNotFound
    case decompositionFailed(String)
    case invalidJSON(String)

    var errorDescription: String? {
        switch self {
        case .claudeNotFound:
            "Claude CLI not found. Make sure Claude Code is installed."
        case .decompositionFailed(let output):
            "Task decomposition failed: \(output)"
        case .invalidJSON(let raw):
            "Failed to parse decomposition result: \(raw.prefix(200))"
        }
    }
}
