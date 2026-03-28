# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeHub is a native macOS app that orchestrates parallel Claude Code CLI sessions across git projects. Each task runs in an isolated git worktree with an embedded terminal (SwiftTerm). Tasks can be auto-decomposed into parallelizable subtasks via Claude CLI.

## Tech Stack

- **Language**: Swift 6.0 (strict concurrency)
- **UI**: SwiftUI with Liquid Glass design (macOS 26+)
- **Persistence**: SwiftData (Project, TaskItem)
- **Terminal**: SwiftTerm (LocalProcessTerminalView)
- **Build**: XcodeGen (`project.yml`) → Xcode
- **Dependencies**: SwiftTerm 1.12.0+ (only external dep)

## Build & Verify

```bash
# Generate Xcode project (after modifying project.yml)
xcodegen generate

# Build
xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build

# No tests or linter configured yet
```

Always verify build succeeds with `xcodebuild` before committing.

## Architecture

### Pattern: Feature-Based MVVM + Atomic Design

```
ClaudeHub/
├── Features/           # Feature modules (Sidebar, TaskList, NewTask, Terminal)
│   └── <Feature>/
│       ├── pages/      # Full-screen views
│       ├── organisms/  # Complex composed views
│       ├── molecules/  # Small composed views
│       ├── atoms/      # Primitive components
│       └── *ViewModel.swift
├── Models/             # SwiftData @Model entities
├── Services/           # Business logic (CLIService, GitService, TerminalSessionManager)
└── Shared/             # AppModel (global state), Constants
```

### Key Services

- **CLIService** — Locates Claude CLI binary, decomposes tasks via JSON subprocess call, builds system prompts for worktree workflow
- **GitService** — Creates/removes git worktrees for task isolation (`task/<slug>` branches)
- **TerminalSessionManager** — Registry of active terminal sessions per task (executable, args, env, cwd)

### State Management

- `AppModel` (`@Observable @MainActor`) — Global UI state (selected project/task, inspector, window size)
- ViewModels use `@Observable` (never `ObservableObject`)
- Data queries via SwiftData `@Query`

### Task Lifecycle

```
pending → running → completed → archived (auto after 60s, unless pinned)
```

### Data Flow

1. User creates task → CLIService decomposes via Claude CLI → TaskItems created in SwiftData
2. User launches task → GitService creates worktree → TerminalSessionManager registers session → SwiftTerm spawns process
3. Process exits → task marked completed → auto-archive countdown (60s, cancelable)

## Conventions

- **Atomic Design**: All SwiftUI components follow atoms → molecules → organisms → pages hierarchy
- **Pure components**: Views take primitives only, previews mandatory
- **All code in English** — French only for i18n/user-facing values
- **Liquid Glass design** — Use `.glassEffect()` modifiers, `GlassEffectContainer` for grouped elements
- **README maintenance** — Update `README.md` when adding features or changing user-facing behavior

## Reference Project

The sibling directory `../liquid-glass-reference` is a comprehensive Liquid Glass design reference. Use it as context when implementing or modifying UI:
- `guides/` — Design principles, API reference, platform differences, common pitfalls
- `code-patterns/` — Production-ready SwiftUI glass components
- `images/` — 190 reference screenshots (86 macOS-specific)

## Skills

When working on this project, use these skills:
- `/swiftui-expert-skill` — SwiftUI best practices, state management, performance, modern APIs
- `/swiftui-liquid-glass` — Liquid Glass API implementation and review
- `/liquid-glass-design` — Liquid Glass design system (blur, reflection, morphing)
- `/code-conventions` — Code style, DDD rules, functional patterns (TypeScript & SwiftUI)

## Specification

See `SPEC.md` for the full feature specification (in French).
