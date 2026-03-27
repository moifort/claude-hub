# Plan : Fix terminal non affiché pour les tâches running

## Context

Quand l'utilisateur sélectionne une tâche "running", il voit une icône de statut au lieu du terminal SwiftTerm avec Claude Code. Le problème : `sessionManager.session(for: task.persistentModelID)` retourne `nil` alors que la session devrait exister.

**Cause racine** : Le `PersistentIdentifier` de SwiftData peut changer entre l'insertion (`context.insert`) et le moment où le `@Query` retourne la tâche (après auto-save). La session enregistrée avec l'ID temporaire n'est pas retrouvée avec l'ID permanent.

**Cause secondaire** : Au redémarrage de l'app, les tâches restent "running" mais les sessions in-memory sont perdues.

## Approche

Ne plus dépendre du `PersistentIdentifier` pour retrouver les sessions. Utiliser le `slug` (String stable, unique par tâche) comme clé.

## Modifications

### 1. `TerminalSessionManager.swift` — Clé par slug au lieu de PersistentIdentifier

Changer la clé des dictionnaires `activeSessions` et `terminalViews` de `PersistentIdentifier` à `String` (slug).

- `activeSessions: [String: SessionInfo]`
- `terminalViews: [String: LocalProcessTerminalView]`
- Toutes les méthodes : `registerSession(for slug:)`, `session(for slug:)`, `cachedTerminalView(for slug:)`, `storeTerminalView(_:for slug:)`, `removeSession(for slug:)`

### 2. `TaskListViewModel.swift` — Passer slug au lieu de persistentModelID

- `launchTask` : `sessionManager.registerSession(for: task.slug, ...)`

### 3. `ContentView.swift` — Lookup par slug + fallback reconstruction

Dans `detailView(for:)` :
- Lookup : `sessionManager.session(for: task.slug)`
- **Fallback** : si tâche `.running` sans session, reconstruire la session depuis les données de la tâche :
  - `executable` = `CLIService.claudePath()`
  - `arguments` = reconstruit depuis `task.prompt` + `CLIService.buildTaskSystemPrompt()`
  - `workingDirectory` = `GitService.worktreePath(repoPath:slug:)`
  - `environment` = `CLIService.enrichedEnvironment()`
- Le fallback enregistre la session reconstruite puis affiche le terminal (cela redémarre Claude Code dans le worktree existant)

### 4. `TerminalRepresentable.swift` — Slug au lieu de PersistentIdentifier

- Remplacer `taskPersistentID: PersistentIdentifier` par `taskSlug: String`
- Cache lookup/store : `sessionManager.cachedTerminalView(for: taskSlug)`

### 5. `TerminalContainer.swift` — Slug au lieu de PersistentIdentifier

- Remplacer `taskPersistentID: PersistentIdentifier` par `taskSlug: String`

## Fichiers modifiés

1. `ClaudeHub/Services/TerminalSessionManager.swift` — clé String
2. `ClaudeHub/Features/TaskList/TaskListViewModel.swift` — passer slug
3. `ClaudeHub/ContentView.swift` — lookup par slug + fallback
4. `ClaudeHub/Features/Terminal/TerminalRepresentable.swift` — slug
5. `ClaudeHub/Features/Terminal/organisms/TerminalContainer.swift` — slug

## Vérification

```bash
xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build
```

Tester manuellement :
1. Soumettre une tâche → cliquer dessus → doit afficher le terminal
2. Naviguer vers un autre projet → revenir sur la tâche → terminal toujours là
3. Quitter l'app → relancer → cliquer sur une tâche restée "running" → terminal relancé

## Commits

1. `fix(terminal): use slug instead of PersistentIdentifier for session lookup`
