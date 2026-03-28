# Supprimer la tâche quand on quitte Claude Code (Ctrl+C × 2)

## Context

Quand l'utilisateur quitte manuellement une session Claude Code (Ctrl+C × 2), la tâche reste dans la liste en état `completed` puis s'auto-archive. L'utilisateur veut qu'un quit manuel (exit code != 0) supprime définitivement la tâche de SwiftData. La complétion normale (exit code 0) garde le comportement actuel (completed → auto-archive).

## Approche

Utiliser l'exit code du processus (actuellement ignoré avec `_`) pour distinguer :
- **Exit code 0** → `completeTask` (comportement actuel)
- **Exit code != 0 ou nil** → supprimer la tâche de SwiftData + cleanup session

## Fichiers à modifier

### 1. `ClaudeHub/Features/TaskList/TaskListViewModel.swift`
- Ajouter propriétés `modelContext: ModelContext?` et `appModel: AppModel?`
- Ajouter méthode `deleteTerminatedTask(_ task:, sessionManager:)` qui :
  - Guard `task.modelContext != nil` (anti double-suppression)
  - `sessionManager.removeSession(for: task.slug)`
  - `onSessionRemoved?(task.slug)`
  - Met à jour la sélection si la tâche supprimée était sélectionnée
  - `modelContext?.delete(task)`
- Dans `launchTask`, changer le callback `onProcessTerminated` :
  ```swift
  onProcessTerminated: { [weak self] exitCode in
      if exitCode == 0 {
          self?.completeTask(task, sessionManager: sessionManager)
      } else {
          self?.deleteTerminatedTask(task, sessionManager: sessionManager)
      }
  }
  ```

### 2. `ClaudeHub/ContentView.swift`
- Dans `.onAppear`, ajouter :
  ```swift
  viewModel.modelContext = modelContext
  viewModel.appModel = appModel
  ```

### 3. `ClaudeHub/Features/InlineTaskInput/pages/InlineTaskInputPage.swift`
- Ajouter `@Environment(AppModel.self) private var appModel`
- Ajouter `.onAppear` pour câbler :
  ```swift
  taskViewModel.modelContext = modelContext
  taskViewModel.appModel = appModel
  ```

### 4. `ClaudeHub/Features/TaskList/pages/TaskListPage.swift`
- Ajouter `.onAppear` pour câbler :
  ```swift
  viewModel.modelContext = modelContext
  viewModel.appModel = appModel
  ```

## Commits

1. `feat(tasks): delete task on manual quit (ctrl-c) instead of archiving`

## Verification

```bash
xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build
```

Test manuel :
1. Lancer une tâche → running
2. Laisser Claude finir normalement → tâche passe en completed, auto-archive fonctionne ✓
3. Lancer une tâche → running → Ctrl+C × 2 → tâche disparaît de la liste ✓
4. Vérifier que la sélection revient au projet après suppression ✓
