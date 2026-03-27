import Foundation

enum CLIService {
    static func claudePath() -> String? {
        let candidates = [
            "/Applications/cmux.app/Contents/Resources/bin/claude",
            "/opt/homebrew/bin/claude",
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
        You are a task decomposition engine for a coding project. \
        You have access to the project files in the current directory. \
        Analyze the project structure, code, and the user's request.

        Split the request into independent, parallelizable subtasks. \
        Each subtask must be executable in its own isolated git worktree \
        without depending on other subtasks.

        For each subtask, provide:
        - title: a short title (max 60 chars) for display
        - summary: a 1-2 sentence description of what this subtask accomplishes
        - prompt: detailed, actionable instructions for Claude Code. \
          Include specific file paths, function names, patterns to follow, \
          and acceptance criteria. The prompt must be self-contained — \
          the executor will work in an isolated worktree with no knowledge \
          of other subtasks.

        Return ONLY a JSON array, no explanation, no markdown:
        [{"title": "...", "summary": "...", "prompt": "..."}]

        If the task cannot be meaningfully split, return a single-element array.
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claude)
        process.arguments = ["--print", "--system-prompt", systemPrompt, prompt]
        process.currentDirectoryURL = URL(fileURLWithPath: projectPath)
        process.environment = enrichedEnvironment()

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = FileHandle.nullDevice

        try process.run()

        // Read pipe data before waiting (avoids deadlock if pipe buffer fills)
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        let status: Int32 = await withCheckedContinuation { continuation in
            process.terminationHandler = { proc in
                continuation.resume(returning: proc.terminationStatus)
            }
        }

        let output = String(data: stdoutData, encoding: .utf8) ?? ""

        guard status == 0 else {
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""
            throw CLIError.decompositionFailed(stderr.isEmpty ? output : stderr)
        }

        return try parseDecomposedTasks(from: output)
    }

    static func buildTaskSystemPrompt(projectPath: String, slug: String, customPrompt: String? = nil) -> String {
        var prompt = """
        You are working on the project at \(projectPath).
        Your task branch is task/\(slug).

        WORKFLOW:
        1. Create an isolated worktree: git worktree add task/\(slug) -b task/\(slug)
        2. Work in the worktree directory. Make commits on your branch.
        3. When complete and verified:
           a. git checkout main (from the main repo)
           b. git pull --rebase
           c. git merge --ff-only task/\(slug)
           d. git worktree remove task/\(slug)
           e. git branch -d task/\(slug)
        - If the merge fails, rebase your branch first: git rebase main
        """

        if let custom = customPrompt, !custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prompt += "\n\n" + custom
        }

        return prompt
    }

    static func enrichedEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let extraPaths = [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            NSHomeDirectory() + "/.claude/bin",
        ]
        let currentPath = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = (extraPaths + [currentPath]).joined(separator: ":")
        env["TERM"] = "xterm-256color"
        return env
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
