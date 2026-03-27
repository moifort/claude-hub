# Plan: Settings Screen with System Prompt Editor

## Context

ClaudeHub n'a actuellement aucun écran de paramétrage. Le system prompt des tasks est hard-codé dans `CLIService.buildTaskSystemPrompt()`. L'utilisateur veut pouvoir personnaliser le system prompt injecté dans chaque session Claude Code, avec un contenu Markdown par défaut reprenant ses conventions (commits, worktrees, workflow git).

## Architecture

### Approche : `Settings` scene native macOS + `@AppStorage`

- Utiliser la scene `Settings { }` de SwiftUI (ouvre via Cmd+, automatiquement)
- Stocker le system prompt dans `@AppStorage("taskSystemPrompt")` (UserDefaults)
- Pré-remplir avec un contenu Markdown par défaut au premier lancement
- Injecter le contenu custom dans `CLIService.buildTaskSystemPrompt()`

### Fichiers à créer

1. **`ClaudeHub/Features/Settings/pages/SettingsPage.swift`** — Vue principale Settings avec onglet "Tasks"
2. **`ClaudeHub/Features/Settings/organisms/TaskSettingsSection.swift`** — Section "System Prompt" avec TextEditor Markdown
3. **`ClaudeHub/Shared/DefaultSystemPrompt.swift`** — Contenu Markdown par défaut (conventions git, commits, worktrees)

### Fichiers à modifier

4. **`ClaudeHub/ClaudeHubApp.swift`** — Ajouter la scene `Settings { SettingsPage() }`
5. **`ClaudeHub/Services/CLIService.swift`** — `buildTaskSystemPrompt()` intègre le prompt custom
6. **`ClaudeHub/Features/TaskList/TaskListViewModel.swift`** — Passer le custom prompt au lancement
7. **`ClaudeHub/ContentView.swift`** — Passer le custom prompt à la reconstruction de session

## Détail de l'implémentation

### 1. `DefaultSystemPrompt.swift` — Contenu Markdown par défaut

```swift
enum DefaultSystemPrompt {
    static let taskSystemPrompt: String = """
    # Conventions

    ## Commits

    - Use **conventional commits**: `type(scope): description`
    - Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`, `perf`
    - Scope: the module or area affected (e.g., `auth`, `ui`, `api`)
    - Description: imperative mood, lowercase, no period
    - Examples: `feat(sidebar): add project filtering`, `fix(terminal): handle process exit code`
    - Commit after each verified change — one logical change per commit
    - All code and commit messages in English

    ## Git Worktree Workflow

    - Each task runs in an **isolated git worktree** on branch `task/<slug>`
    - Create: `git worktree add ../task/<slug> -b task/<slug>`
    - Work in the worktree directory, make commits on the task branch

    ## Syncing with Main

    - Before starting: ensure main is up to date (`git pull --rebase` on main)
    - During work: regularly rebase on main to stay current: `git rebase main`
    - Before merge: always `git rebase main` one final time in the worktree branch
    - Resolve all conflicts in the worktree, never on main

    ## Merging Back to Main

    1. From the **main repo** (not the worktree): `git checkout main`
    2. Pull latest: `git pull --rebase`
    3. Fast-forward merge: `git merge --ff-only task/<slug>`
    4. Clean up worktree: `git worktree remove task/<slug>`
    5. Delete branch: `git branch -d task/<slug>`
    - If merge fails → rebase first: `git rebase main` in the worktree, then retry
    - Always maintain **linear history** (rebase, never merge commits)

    ## Verification

    - Always verify build succeeds before committing
    - Run all relevant checks (tests, linter, type-check) before marking complete
    """
}
```

### 2. `SettingsPage.swift` — Vue Settings

- TabView avec un onglet "Tasks" (icône `terminal`)
- Prêt pour d'autres onglets futurs (General, etc.)
- Utilise `@AppStorage("taskSystemPrompt")` initialisé avec `DefaultSystemPrompt.taskSystemPrompt`

### 3. `TaskSettingsSection.swift` — Éditeur System Prompt

- Label "System Prompt" avec description
- `TextEditor` monospace, fond sombre, style terminal
- Bouton "Reset to Default" pour restaurer le contenu par défaut
- Hauteur min ~400pt pour un confort d'édition

### 4. `ClaudeHubApp.swift` — Ajouter Settings scene

```swift
Settings {
    SettingsPage()
}
```

### 5. `CLIService.swift` — Intégrer le custom prompt

Modifier `buildTaskSystemPrompt()` pour accepter un paramètre `customPrompt: String` optionnel et l'ajouter après le workflow technique :

```swift
static func buildTaskSystemPrompt(projectPath: String, slug: String, customPrompt: String? = nil) -> String {
    var prompt = """
    You are working on the project at \(projectPath).
    Your task branch is task/\(slug).
    ...workflow...
    """
    if let custom = customPrompt, !custom.isEmpty {
        prompt += "\n\n" + custom
    }
    return prompt
}
```

### 6. `TaskListViewModel.swift` + `ContentView.swift`

- Lire `UserDefaults.standard.string(forKey: "taskSystemPrompt")` au moment du `launchTask()` et le passer à `buildTaskSystemPrompt()`
- Idem dans `reconstructSession()` de ContentView

## Commits prévus

1. `feat(settings): add default system prompt content` — DefaultSystemPrompt.swift
2. `feat(settings): add Settings page with system prompt editor` — SettingsPage + TaskSettingsSection
3. `feat(settings): wire Settings scene in app entry point` — ClaudeHubApp.swift
4. `feat(task): inject custom system prompt into CLI sessions` — CLIService + TaskListViewModel + ContentView

## Vérification

1. Build: `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
2. Ouvrir l'app → Cmd+, → vérifier que Settings s'ouvre avec l'onglet Tasks
3. Vérifier que le TextEditor affiche le Markdown par défaut
4. Modifier le prompt → lancer une task → vérifier dans le terminal que le custom prompt est injecté
5. Reset to Default → vérifier que le contenu original revient
