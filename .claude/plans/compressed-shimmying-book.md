# Fix: Guard task status against regression after completion/archive

## Context

`completeTask()` has no guard — it can be called multiple times from two independent paths:
1. **TerminalStateMonitor** detects "◆ done" → `syncTaskStates()` → `completeTask()`
2. **processTerminated** callback fires when the process exits → `completeTask()`

This causes two bugs:
- **Double completion**: Both paths fire → `completedAt` reset, auto-archive timer restarted, sidebar countdown resets
- **Archive regression**: `archiveTask()` → `removeSession()` → `terminate()` → `processTerminated` dispatched async via `Task { @MainActor }` → `completeTask()` reverts `.archived` back to `.completed`

## Changes

### 1. Guard in `completeTask()` — `TaskListViewModel.swift` (line 39)

```swift
// Before:
func completeTask(_ task: TaskItem, sessionManager: TerminalSessionManager) {
    task.taskStatus = .completed
    ...
}

// After:
func completeTask(_ task: TaskItem, sessionManager: TerminalSessionManager) {
    guard task.taskStatus == .running || task.taskStatus == .waiting || task.taskStatus == .planReady else { return }
    task.taskStatus = .completed
    ...
}
```

Only active states (`.running`, `.waiting`, `.planReady`) can transition to `.completed`. Already-completed or archived tasks are skipped.

### 2. Clean up stale states — `TerminalStateMonitor.swift` (line 57)

```swift
// Before:
guard let terminalView = sessionManager.cachedTerminalView(for: slug),
      terminalView.process.running else { continue }

// After:
guard let terminalView = sessionManager.cachedTerminalView(for: slug),
      terminalView.process.running else {
    removeState(for: slug)
    continue
}
```

When a process exits, clean up `detectedStates`/`previousSnapshots`/`stablePolls` instead of leaving stale entries.

## Verification

```bash
xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build
```

## Commits

- `fix(status): guard completeTask against status regression`
