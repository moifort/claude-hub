# Git Tree: auto-refresh on commit + granular relative time

## Context

Two issues with the git tree panel:
1. The FS watcher on `.git/refs/heads/main` breaks after the first event because git uses atomic rename (write temp → rename over target), invalidating the file descriptor. The tree stops auto-refreshing after the first detected change.
2. The relative time display is too coarse — "now" covers everything under 10 minutes. Need second-level granularity for recent commits.

## Plan

### 1. Fix FS watcher reliability (`GitTreeViewModel.swift`)

**Problem**: `makeMonitor()` opens an FD on a file. Git's atomic ref update deletes/renames the file, invalidating the FD. Subsequent events are never received.

**Fix**: After each `refresh()`, restart the watchers so FDs always point to the current file.

```swift
func refresh() async {
    guard let path = currentRepoPath else { return }
    do {
        async let commitsTask = GitService.fetchCommitLog(repoPath: path)
        async let countTask = GitService.fetchUncommittedCount(repoPath: path)
        let commits = try await commitsTask
        graph = GitService.buildGraph(from: commits)
        uncommittedCount = (try? await countTask) ?? 0
        errorMessage = nil
    } catch {
        // Silently ignore refresh errors
    }
    // Re-create monitors — FDs may be stale after git's atomic ref update
    startWatching(repoPath: path)
}
```

### 2. Granular relative time display (`CommitRowDetail.swift`)

**New tiers for `roundedTimeAgo()`**:

| Range | Display | Examples |
|-------|---------|---------|
| < 10s | `now` | now |
| 10s–59s | `≈Xs` (round to 10s) | ≈10s, ≈30s, ≈50s |
| 1min–9min | `≈Xm` (round to 1min) | ≈1m, ≈5m, ≈9m |
| 10min–59min | `≈Xm` (round to 10min) | ≈10m, ≈30m, ≈50m |
| 1h–23h | `≈Xh` | ≈1h, ≈12h |
| 1d–6d | `≈Xd` | ≈1d, ≈5d |
| 7d+ | date | 25 Mar |

### 3. Live time update with `TimelineView` (`CommitRowDetail.swift`)

Wrap the time `Text` in a `TimelineView` so it auto-updates. Use a schedule that ticks every 5 seconds (good enough for the ≈10s rounding, avoids excessive redraws).

```swift
TimelineView(.periodic(every: 5)) { context in
    Text(roundedTimeAgo(from: date))
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .fixedSize()
}
```

## Files to modify

- `ClaudeHub/Features/GitTree/GitTreeViewModel.swift` — add `startWatching` call in `refresh()`
- `ClaudeHub/Features/GitTree/molecules/CommitRowDetail.swift` — new time tiers + `TimelineView`

## Verification

1. Build: `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
2. Manual test: open app, make a commit in watched repo, verify tree refreshes automatically
3. Verify time display: new commit shows "now", then ticks to "≈10s", "≈20s", etc.

## Commits

1. `fix(git-tree): restart FS watchers after refresh to survive atomic ref updates`
2. `feat(git-tree): granular relative time with live updates via TimelineView`
