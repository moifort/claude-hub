# ClaudeHub

A native macOS app that orchestrates parallel Claude Code CLI sessions across your git projects.

## What is ClaudeHub?

When working with Claude Code on complex tasks, you often need to run multiple sessions in parallel — one implementing an API, another writing tests, a third refactoring the UI. But running them on the same codebase creates conflicts.

ClaudeHub solves this by giving each task its own isolated git worktree. You describe what you want, ClaudeHub splits it into independent subtasks, launches them in parallel, and monitors their progress — all from a single window.

## Key Features

- **Project management** — Add any git repository via folder picker or drag-and-drop
- **Auto task decomposition** — Describe a complex task and ClaudeHub splits it into independent, parallelizable subtasks using on-device intelligence
- **Embedded terminals** — Each task runs in its own terminal (SwiftTerm) with live output
- **Git worktree isolation** — Every task operates on a dedicated `task/<slug>` branch, preventing conflicts between parallel sessions
- **Real-time status tracking** — Tasks are monitored for status markers (`working`, `waiting`, `done`) and update automatically
- **System prompt injection** — Each Claude Code session receives a workflow prompt with git conventions, worktree lifecycle, and commit guidelines
- **Auto-archive** — Completed tasks auto-archive after a countdown (configurable), keeping the workspace clean
- **Pin tasks** — Prevent auto-archive on tasks you want to keep visible
- **Git tree inspector** — View the commit history and uncommitted changes of any project
- **IDE integration** — Open any project in your preferred editor with one click
- **One-click push** — Push completed work to origin/main directly from the app

## How It Works

```
You                      ClaudeHub                       Claude Code CLI
 |                          |                                |
 |-- Add a git project ---->|                                |
 |-- Type a task ---------->|                                |
 |                          |-- Decompose into subtasks ---->|
 |                          |<-- [{title, prompt}, ...] -----|
 |                          |                                |
 |                          |-- Create worktree per task     |
 |                          |-- Launch terminal session ---->|
 |                          |-- Inject system prompt ------->|
 |                          |                                |
 |    (autonomous work in isolated worktrees)                |
 |                          |                                |
 |                          |<-- Status: working/waiting ----|
 |                          |<-- Status: done ---------------|
 |                          |-- Merge to main, cleanup       |
 |                          |-- Auto-archive after timeout   |
```

## User Interface

```
┌──────────────────────────────────────────────────────────────┐
│  ClaudeHub                              Push  Open IDE  Git  │
├───────────────┬──────────────────────────────────┬───────────┤
│  Projects     │  Terminal                        │ Git Tree  │
│               │                                  │           │
│  my-app [3]   │  $ claude ...                    │ commits   │
│    ▶ API      │  ◆ working                       │ + changes │
│    ▶ Tests    │  Building endpoints...           │           │
│    ⏳ Refactor │  ◆ done                          │           │
│               │                                  │           │
│  other-proj   │                                  │           │
│               │                                  │           │
│  ─────────    │                                  │           │
│  Archives     │                                  │           │
├───────────────┴──────────────────────────────────┴───────────┤
│  Task input — Enter to submit, Shift+Enter for newline       │
│  [                                        ] ⚡ Auto-split    │
└──────────────────────────────────────────────────────────────┘
```

**Sidebar** — Lists your projects with task counts and status indicators. Archived tasks appear in a collapsible section at the bottom.

**Terminal panel** — Shows the live output of the selected task's Claude Code session. You can interact with it directly when the task is waiting for input.

**Git tree** — Optional inspector panel showing the commit graph and uncommitted file count for the current project.

**Task input** — Multiline input area at the bottom. Toggle auto-split to let ClaudeHub decompose your request into parallel subtasks.

## Task Lifecycle

```
pending ──[launch]──> running ──[working]──> running
                         │
                    [waiting] ──> waiting ──[user input]──> running
                         │
                      [done] ──> completed ──[countdown]──> archived
                                     │
                                  [pin] (cancels auto-archive)
```

| Status | Meaning |
|--------|---------|
| **Pending** | Task created, waiting to be launched |
| **Running** | Claude Code session is active |
| **Waiting** | Session paused, needs user input |
| **Completed** | Task finished, countdown to archive started |
| **Archived** | Moved to archives section, worktree cleaned up |

## Requirements

- **macOS 26+** (Tahoe)
- **Claude Code CLI** installed and accessible in PATH
- **Git** for worktree management
- **Xcode 26+** to build from source

## Build

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Build
xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build
```

## Tech Stack

- Swift 6.0 with strict concurrency
- SwiftUI with Liquid Glass design
- SwiftData for persistence
- SwiftTerm for embedded terminals
- FoundationModels for task decomposition
