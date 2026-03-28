# Plan: Commit All Remaining Files

## Context
Multiple features and changes have accumulated uncommitted in the working tree. The user wants all remaining files committed in organized, logical commits following conventional commit conventions.

## Changes to Commit

### Commit 1: `chore(plans): add session plan files`
- All 26 untracked `.claude/plans/*.md` files
- 2 modified `.claude/plans/*.md` files (distributed-splashing-lynx, polymorphic-seeking-badger)

### Commit 2: `style(tasks): update status icons, colors and display names`
- `ClaudeHub/Models/TaskStatus.swift` — new icons (hourglass, bell, checkmark.seal, etc.), "Waiting" → "User Input", orange → blue

### Commit 3: `feat(sidebar): add auto-archive countdown timer with keep button`
- `ClaudeHub/Features/Sidebar/molecules/SidebarTaskRow.swift` — countdown timer UI, isPinned/completedAt props, "Keep" button
- `ClaudeHub/Features/Sidebar/organisms/ProjectListSection.swift` — pass new params to SidebarTaskRow
- `ClaudeHub/Shared/Constants.swift` — archiveDelay 60s → 300s

### Commit 4: `feat(tasks): add foundation split toggle for task decomposition`
- `ClaudeHub/Features/InlineTaskInput/InlineTaskInputViewModel.swift` — useFoundationSplit parameter

### Commit 5: `chore(project): add UncommittedRowDetail to build`
- `ClaudeHub.xcodeproj/project.pbxproj` — new file reference

### Skip: `.claude/worktrees/`
- Active worktree tracking directory — should NOT be committed (ephemeral)

## Verification
- Run `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build` after all commits to verify build succeeds
- Run `git log --oneline -5` to verify commit history

## Files
- `.claude/plans/*.md` (28 files)
- `ClaudeHub/Models/TaskStatus.swift`
- `ClaudeHub/Features/Sidebar/molecules/SidebarTaskRow.swift`
- `ClaudeHub/Features/Sidebar/organisms/ProjectListSection.swift`
- `ClaudeHub/Shared/Constants.swift`
- `ClaudeHub/Features/InlineTaskInput/InlineTaskInputViewModel.swift`
- `ClaudeHub.xcodeproj/project.pbxproj`
