# Plan: Generate functional README.md + update CLAUDE.md

## Context

ClaudeHub lacks a user-facing README.md that explains what the app does from a functional perspective. The SPEC.md exists but is a technical specification in French. A README.md is needed to give newcomers a clear understanding of the app's purpose, features, and workflows. Additionally, CLAUDE.md should be updated to enforce keeping README.md in sync with feature/behavior changes.

## Changes

### 1. Create `README.md` — functional overview

**Content structure:**
- **Header** with app name and one-line description
- **What is ClaudeHub?** — problem statement and value proposition
- **Key Features** — bullet list of main capabilities
- **How It Works** — visual workflow (text diagram) showing the task lifecycle
- **User Interface** — description of the main window layout (sidebar, terminal, input)
- **Task Lifecycle** — status flow from pending → archived
- **Requirements** — macOS 26+, Claude Code CLI, git
- **Build** — quick build instructions (xcodegen + xcodebuild)

**Tone:** Functional/user-facing, not deeply technical. Written in English (project convention).

### 2. Update `CLAUDE.md` — add README maintenance rule

Add a rule in the Conventions section:
> **README maintenance** — Update `README.md` when adding features or changing user-facing behavior

**Files to modify:**
- `/Users/thibaut/Code/claude-hub/README.md` (create)
- `/Users/thibaut/Code/claude-hub/CLAUDE.md` (edit Conventions section)

## Commits

1. `docs(readme): add functional overview of the application`
2. `docs(claude): add readme maintenance rule to conventions`

## Verification

- `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build` (ensure no regressions — docs only change, but verify anyway)
- Visual review of README.md rendering
