import Foundation

enum CLIService {
    static func claudePath() -> String? {
        let custom = UserDefaults.standard.string(forKey: "claudeBinaryPath")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !custom.isEmpty, FileManager.default.isExecutableFile(atPath: custom) {
            return custom
        }

        let candidates = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
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

}

enum CLIError: LocalizedError {
    case claudeNotFound

    var errorDescription: String? {
        switch self {
        case .claudeNotFound:
            "Claude CLI not found. Make sure Claude Code is installed."
        }
    }
}
