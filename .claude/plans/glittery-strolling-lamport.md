# ClaudeHub — Implementation Plan

## Context

ClaudeHub est une application macOS native pour orchestrer des sessions Claude Code CLI en parallele sur plusieurs projets git. L'utilisateur cree une tache en langage naturel, ClaudeHub la decompose automatiquement en sous-taches independantes, chacune executee dans un terminal embarque avec son propre git worktree. Le projet est vierge (seul SPEC.md existe). L'implementation suit les guidelines Liquid Glass de `../liquid-glass-reference`.

## Architecture

### Tech Stack
- **SwiftUI** macOS 26+ (Liquid Glass)
- **SwiftData** (persistence Project + TaskItem)
- **SwiftTerm** (SPM: `https://github.com/migueldeicaza/SwiftTerm.git`) — `LocalProcessTerminalView` (NSView) via NSViewRepresentable
- **Claude Code CLI** — subprocess orchestration via `Process`

### State Management
- `@Observable @MainActor` partout, jamais `ObservableObject`
- `@Environment(AppModel.self)` pour l'etat global
- `@Bindable` pour les bindings bidirectionnels
- `@Query` SwiftData pour les listes

### Navigation (macOS)
```
NavigationSplitView {
    SidebarView()        // Projets + Archives
} detail: {
    TaskListPage()       // Taches du projet selectionne
}
.inspector(isPresented:) {
    TerminalInspectorView()  // Terminal de la tache selectionnee
}
```

### Component Architecture — Atomic Design

Tous les composants sont **purs** : ils recoivent uniquement des primitives (String, Int, Bool, Date?, Color, closures). Jamais de domain models ou @Observable classes. Le mapping domain → primitives se fait au call site. Chaque composant a un `#Preview`.

- **atoms/** — elements UI atomiques, sans logique (badge, chip, bouton style)
- **molecules/** — composition de 2-3 atoms (task row, terminal header)
- **organisms/** — sections autonomes composees de molecules (task list, sidebar sections)
- **pages/** — vues pleine page, seules a acceder `@Environment`/`@Query`/ViewModels

## File Structure

```
ClaudeHub/
  ClaudeHubApp.swift
  ContentView.swift

  Models/
    Project.swift              // @Model: name, path, createdAt, tasks relationship
    TaskItem.swift             // @Model: title, prompt, status (String), isPinned, timestamps
    TaskStatus.swift           // enum: pending, running, waiting, completed, archived
    DecomposedTask.swift       // Codable struct {title, prompt} for JSON parsing

  Features/
    Sidebar/
      pages/
        SidebarPage.swift          // Page: @Query projects, @Environment, coordination
      organisms/
        ProjectListSection.swift   // Section "Projects" iterating ProjectRow
        ArchivesSection.swift      // Section "Archives" iterating ArchivedTaskRow
      molecules/
        ProjectRow.swift           // Pure: name: String, taskCount: Int, hasRunningTask: Bool
        ArchivedTaskRow.swift      // Pure: title: String, projectName: String, archivedAt: Date

    TaskList/
      pages/
        TaskListPage.swift         // Page: @Query tasks, @Environment, presents sheet
      organisms/
        TaskListContent.swift      // Grouped task list (running/waiting/pending/completed)
      molecules/
        TaskRow.swift              // Pure: title, status, isPinned, remainingSeconds?, onPin, onSelect
        CountdownBadge.swift       // Pure: remainingSeconds: Int, onKeep: () -> Void
      atoms/
        StatusBadge.swift          // Pure: status: TaskStatus (value type)
        GlassStatusChip.swift      // Pure: label: String, icon: String, tintColor: Color
      TaskListViewModel.swift      // Task lifecycle, auto-archive timers

    NewTask/
      pages/
        NewTaskSheet.swift         // Page: modal sheet, TextEditor, decomposition coordination
      molecules/
        TaskPromptEditor.swift     // Pure: text: Binding<String>, placeholder: String, onSubmit
        DecompositionProgress.swift // Pure: isDecomposing: Bool, subtaskCount: Int?
      NewTaskViewModel.swift       // Decomposition call + fallback

    Terminal/
      pages/
        TerminalInspectorPage.swift  // Page: inspector panel, @Environment for selected task
      organisms/
        TerminalContainer.swift      // Wraps TerminalRepresentable with lifecycle management
      molecules/
        TerminalHeader.swift         // Pure: taskTitle: String, status: TaskStatus, projectName: String
      TerminalRepresentable.swift    // NSViewRepresentable for LocalProcessTerminalView

  Services/
    CLIService.swift               // Claude binary resolution, decomposition, system prompt
    GitService.swift               // git validation, worktree CRUD, rebase, merge
    TerminalSessionManager.swift   // Active terminal sessions tracking (@Observable)

  Shared/
    AppModel.swift                 // Global state: selectedProjectID, selectedTaskID, showInspector
    Constants.swift                // Design constants: spacing, radii, delays
```

## Phases d'implementation

### Phase 1 — Scaffold + Data Layer
Creer le projet Xcode, les modeles SwiftData, l'AppModel et le ContentView avec NavigationSplitView vide.

**Fichiers**: `ClaudeHubApp.swift`, `ContentView.swift`, `AppModel.swift`, `Constants.swift`, `Project.swift`, `TaskItem.swift`, `TaskStatus.swift`, `DecomposedTask.swift`

**Details cles**:
- `Project`: `@Model` avec `name: String`, `path: String`, `createdAt: Date`, `@Relationship(deleteRule: .cascade) var tasks: [TaskItem]`
- `TaskItem`: `@Model` avec `title`, `prompt`, `status: String` (raw value pour predicats SwiftData), `isPinned: Bool`, `createdAt`, `completedAt?`, `archivedAt?`, `parentTaskTitle?`
- `TaskStatus`: enum avec `displayName`, `iconName`, `tintColor`
- `Constants`: `glassSpacing = 16`, `cornerRadius = 12`, `archiveDelay: TimeInterval = 60`, `maxArchivedVisible = 10`
- App window: `frame(minWidth: 900, minHeight: 600)`
- Sandbox desactive (`com.apple.security.app-sandbox = NO` requis par SwiftTerm forkpty)

**Commit**: `feat(scaffold): create Xcode project with SwiftData models and app shell`

### Phase 2 — Sidebar + Project Management
Sidebar avec liste de projets, ajout via NSOpenPanel ou drag-and-drop, validation git, suppression.

**Fichiers**: `Sidebar/pages/SidebarPage.swift`, `Sidebar/organisms/ProjectListSection.swift`, `Sidebar/organisms/ArchivesSection.swift`, `Sidebar/molecules/ProjectRow.swift`, `Sidebar/molecules/ArchivedTaskRow.swift`, `Services/GitService.swift`

**Details cles**:
- `GitService.isGitRepository(at:)` — verifie `.git` via `FileManager` ou `git rev-parse`
- `GitService.repositoryName(at:)` — basename du path
- `SidebarPage` (page): seule vue avec `@Environment(AppModel.self)`, `@Environment(\.modelContext)`, `@Query var projects`
- `ProjectListSection` (organism): recoit `projects: [(id, name, taskCount, hasRunning)]`, `onDelete`, `onSelect`
- `ArchivesSection` (organism): recoit `archives: [(id, title, projectName, archivedAt)]`
- `ProjectRow` (molecule, pur): `name: String`, `taskCount: Int`, `hasRunningTask: Bool` + `#Preview`
- `ArchivedTaskRow` (molecule, pur): `title: String`, `projectName: String`, `archivedAt: Date` + `#Preview`
- NSOpenPanel pour selection de dossier, `.onDrop(of: [.fileURL])` pour drag-and-drop
- Context menu: "Remove Project" avec `modelContext.delete(project)`
- Empty state: `ContentUnavailableView("No Projects", systemImage: "folder.badge.plus")`

**Commit**: `feat(sidebar): project management with folder picker, drag-drop, and git validation`

### Phase 3 — Task Creation + Decomposition
Sheet modale pour saisie, appel Claude CLI pour decomposition en sous-taches JSON.

**Fichiers**: `NewTask/pages/NewTaskSheet.swift`, `NewTask/molecules/TaskPromptEditor.swift`, `NewTask/molecules/DecompositionProgress.swift`, `NewTask/NewTaskViewModel.swift`, `Services/CLIService.swift`

**Details cles**:
- `NewTaskSheet` (page): coordonne le flow, `@Environment`, presente le VM
- `TaskPromptEditor` (molecule, pur): `text: Binding<String>`, `placeholder: String`, `isDisabled: Bool`, `onSubmit: () -> Void` + `#Preview`
- `DecompositionProgress` (molecule, pur): `isDecomposing: Bool`, `subtaskCount: Int?` + `#Preview`
- `NewTaskSheet`: `TextEditor` via `TaskPromptEditor`, bouton Submit avec `.keyboardShortcut(.return, modifiers: .command)`, ProgressView via `DecompositionProgress`
- `CLIService.claudePath()` — cherche dans `/usr/local/bin/claude`, `~/.claude/bin/claude`, puis `which claude`
- `CLIService.decomposeTask(prompt:projectPath:)`:
  - Lance `claude --print -s "..."` avec system prompt demandant un JSON `[{"title":"...","prompt":"..."}]`
  - Parse stdout, extrait le JSON (scan pour `[` ... `]`)
  - Timeout 30s, fallback en tache unique si echec
- `CLIService.buildTaskSystemPrompt(projectPath:slug:)`:
  ```
  You are working in an isolated git worktree at <path>/task/<slug>.
  Your branch is task/<slug>.
  Work independently. Do NOT modify main directly.
  When done: git checkout main && git rebase main && git merge --ff-only task/<slug>
  Clean up: git worktree remove task/<slug> && git branch -d task/<slug>
  ```
- Slug generation: lowercase, hyphens, alphanum only, truncate 50 chars, append 6-char UUID

**Commit**: `feat(tasks): task creation sheet with Claude CLI decomposition`

### Phase 4 — Task List + Status Display
Liste des taches dans le detail pane, badges de statut, groupement par statut.

**Fichiers**: `TaskList/pages/TaskListPage.swift`, `TaskList/organisms/TaskListContent.swift`, `TaskList/molecules/TaskRow.swift`, `TaskList/molecules/CountdownBadge.swift`, `TaskList/atoms/StatusBadge.swift`, `TaskList/atoms/GlassStatusChip.swift`, `TaskList/TaskListViewModel.swift`

**Details cles**:
- `TaskListPage` (page): `@Query` filtre par projet, `@Environment`, toolbar "New Task" (Cmd+N), coordonne selection
- `TaskListContent` (organism): recoit `tasks: [(id, title, status, isPinned, remainingSeconds?)]`, closures `onSelect`/`onPin`/`onLaunch`
- `TaskRow` (molecule, pur): `title: String`, `status: TaskStatus`, `isPinned: Bool`, `remainingSeconds: Int?`, `onPin: () -> Void`, `onSelect: () -> Void` + `#Preview`
- `CountdownBadge` (molecule, pur): `remainingSeconds: Int`, `onKeep: () -> Void` — `TimelineView(.periodic(from: .now, by: 1))` + `#Preview`
- `StatusBadge` (atom, pur): `status: TaskStatus` — `.glassEffect(.regular.tint(status.tintColor), in: .capsule)` + `#Preview`
- `GlassStatusChip` (atom, pur): `label: String`, `icon: String`, `tintColor: Color` — glass capsule + `#Preview`
- Groupement: Running → Waiting → Pending → Completed (pas Archived)
- Selection de tache → `appModel.selectedTaskID`, ouvre inspector

**Commit**: `feat(tasks): task list with status badges, countdown, and glass design`

### Phase 5 — Terminal Integration
Wrapper NSViewRepresentable pour SwiftTerm, inspector panel avec terminal embarque.

**Fichiers**: `Terminal/pages/TerminalInspectorPage.swift`, `Terminal/organisms/TerminalContainer.swift`, `Terminal/molecules/TerminalHeader.swift`, `Terminal/TerminalRepresentable.swift`, `Services/TerminalSessionManager.swift`

**Details cles**:
- `TerminalRepresentable: NSViewRepresentable` (pas un composant pur — bridge AppKit):
  - `makeNSView`: cree `LocalProcessTerminalView(frame:)`, set `processDelegate` sur Coordinator
  - `updateNSView`: si taskID change, termine ancien process, lance nouveau
  - `Coordinator` implemente `LocalProcessTerminalViewDelegate`:
    - `processTerminated(source:exitCode:)` → statut `.completed`
    - `sizeChanged` → redimensionne le pty
- `TerminalSessionManager`: `@Observable @MainActor`, stocke `[PersistentIdentifier: LocalProcessTerminalView]`
- `TerminalInspectorPage` (page): `@Environment` pour selected task, coordonne affichage ou `ContentUnavailableView`
- `TerminalContainer` (organism): recoit les parametres de session, gere le lifecycle
- `TerminalHeader` (molecule, pur): `taskTitle: String`, `status: TaskStatus`, `projectName: String` — glass toolbar + `#Preview`
- Process launch: `startProcess(executable: claudePath, args: ["--system-prompt", systemPrompt, prompt], currentDirectory: worktreePath)`

**Commit**: `feat(terminal): embedded SwiftTerm terminal in inspector panel`

### Phase 6 — Task Execution Pipeline
Connecte tout: lancement d'une tache → creation worktree → demarrage terminal → monitoring statut.

**Modifications**: `TaskListViewModel.swift`, `GitService.swift` (worktree CRUD), `TerminalRepresentable.swift`

**Details cles**:
- `GitService.createWorktree(repoPath:slug:)` — `git worktree add task/<slug> -b task/<slug>`
- `GitService.removeWorktree(repoPath:slug:)` — `git worktree remove task/<slug>`
- `TaskListViewModel.launchTask(_:)`:
  1. Cree le worktree via GitService
  2. Set status `.running`
  3. Build system prompt via CLIService
  4. Signal TerminalSessionManager pour creer/demarrer session
- Detection de statut:
  - **Running**: quand le process demarre
  - **Waiting**: detection via output terminal (pattern "?" ou titre OSC "waiting")
  - **Completed**: callback `processTerminated` (exit code 0)
- Lancement automatique de toutes les sous-taches en parallele apres decomposition

**Commit**: `feat(pipeline): end-to-end task execution with git worktrees`

### Phase 7 — Auto-Archive System
Countdown 60s sur taches completees, pin, section archives.

**Modifications**: `TaskListViewModel.swift`, `CountdownBadge.swift`, `ArchivesSection` dans `SidebarView.swift`

**Details cles**:
- A la transition vers `.completed`: `completedAt = Date()`, lance `Task.sleep(for: .seconds(60))`
- Verifie `isPinned` avant archivage — si pin, annule le timer
- `pinTask()`: set `isPinned = true`, cancel timer
- Archives dans la sidebar: derniers 10, tries par `archivedAt` desc
- Cleanup du worktree et de la branche a l'archivage

**Commit**: `feat(archive): auto-archive with 60s countdown and pin support`

### Phase 8 — Polish + Liquid Glass
Application des effets glass partout, raccourcis clavier, empty states.

**Modifications**: tous les fichiers de vue

**Details cles**:
- Sidebar: glass automatique via NavigationSplitView
- TaskRow: status badges avec `.glassEffect(.regular.tint(), in: .capsule)`
- NewTaskSheet: submit `.buttonStyle(.glassProminent)`
- TerminalHeader: `.glassEffect(.regular, in: .rect(cornerRadius: Constants.cornerRadius))`
- Grouper les glass elements dans `GlassEffectContainer(spacing: Constants.glassSpacing)`
- Ordre des modifiers: font → foregroundStyle → padding → `.glassEffect()` (LAST)
- Raccourcis: `Cmd+N` (new task), `Cmd+Return` (submit), `Cmd+I` (toggle inspector)
- Empty states avec `ContentUnavailableView` partout
- Animations: `.animation(.smooth, value:)` sur les transitions de statut

**Commit**: `feat(polish): liquid glass design, keyboard shortcuts, and empty states`

## Verification

1. **Build**: `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build` apres chaque phase
2. **Test fonctionnel**:
   - Ajouter un projet git via le folder picker → apparait dans la sidebar
   - Drag-and-drop un dossier non-git → rejet avec erreur
   - Creer une tache → decomposition en sous-taches visible
   - Lancer une tache → terminal embarque s'ouvre dans l'inspector
   - Tache terminee → countdown 60s visible, bouton "Keep" fonctionne
   - Auto-archive → tache passe dans la section Archives de la sidebar
3. **Liquid Glass**: verifier visuellement que les glass effects s'affichent correctement sur macOS 26

## Risques et mitigations

| Risque | Mitigation |
|--------|-----------|
| SwiftTerm `forkpty` requiert no-sandbox | Desactiver sandbox, garder Hardened Runtime |
| Claude CLI path variable | Check multiple locations + fallback configurable |
| `@Query` SwiftData filtres dynamiques limites | Status stocke comme String, filtrage additionnel en VM |
| Memoire avec N terminaux actifs | Limiter a 5 taches running simultanées, queue les pending |
| Cleanup processes a la fermeture | `TerminalSessionManager.terminateAll()` dans `applicationWillTerminate` |
