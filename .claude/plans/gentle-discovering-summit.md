# Stay on prompt page after task creation

## Context

When the user submits a task via the prompt, the app navigates to the task's terminal view. The user wants to stay on the prompt page to submit multiple tasks in sequence. The prompt should be cleared and a confirmation shown instead.

## Files to modify

1. `ClaudeHub/Features/InlineTaskInput/InlineTaskInputViewModel.swift`
2. `ClaudeHub/Features/InlineTaskInput/pages/InlineTaskInputPage.swift`

## Changes

### 1. InlineTaskInputViewModel — Remove navigation, add confirmation state

- Add `private(set) var lastCreatedTaskTitle: String?` property
- In `submit()`: remove `appModel.selectedItemID = task.persistentModelID` (line 47)
- In `submit()`: set `lastCreatedTaskTitle = title` after save
- Remove `appModel` parameter from `submit()` since it's no longer needed
- Add method to clear confirmation (called when user starts typing again)

### 2. InlineTaskInputPage — Show confirmation feedback

- Display confirmation message below the prompt area (where errors/summarizing already appear), e.g.:
  - `"✓ Task created: <title>"` in terminal-green monospaced style, consistent with existing status text
- Clear the confirmation when the user starts typing (via `.onChange(of: viewModel.prompt)`)
- Remove `appModel` from the `submit()` call

## Commits

1. `fix(prompt): stay on prompt page after task creation with confirmation`

## Verification

- Build: `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
