# Fix crash EV_VANISHED libdispatch — Lifecycle terminal sessions

## Context

L'app crash avec `BUG IN CLIENT OF LIBDISPATCH: Unexpected EV_VANISHED (do not destroy random mach ports or file descriptors)` au lancement d'une session terminal. Le crash est causé par des `LocalProcessTerminalView` (SwiftTerm) dont les dispatch sources internes (DispatchIO sur le PTY fd) ne sont pas proprement nettoyées avant la déallocation.

### Root cause

1. **`LocalProcess.terminate()`** ferme proprement le DispatchIO → cleanup handler ferme les FDs → pas de EV_VANISHED
2. **`LocalProcess.deinit`** ne fait PAS appel à `terminate()` — il annule seulement `childMonitor`
3. **`TerminalSessionManager.removeSession()`** met les refs à `nil` SANS appeler `terminate()` d'abord → la vue est déallouée → DispatchIO encore actif → FD libéré → **EV_VANISHED crash**
4. **`removeSession()` n'est jamais appelé** — les sessions s'accumulent indéfiniment
5. **`removeAll()` a le même bug** (pas de `terminate()` avant clear)

## Plan

### Commit 1 : fix(terminal): call terminate() before deallocating terminal views

**Fichier : `ClaudeHub/Services/TerminalSessionManager.swift`**

- `removeSession(for:)` : appeler `terminalViews[slug]?.terminate()` AVANT de nil les dictionnaires
- `removeAll()` : itérer `terminalViews.values` et appeler `terminate()` AVANT `removeAll()`
- Ajouter une computed property `hasRunningSessions: Bool` qui vérifie `terminalViews.values.contains { $0.process.running }`

### Commit 2 : fix(terminal): clean up sessions on archive and app quit

**Fichier : `ClaudeHub/Features/TaskList/TaskListViewModel.swift`**

Ajouter le paramètre `sessionManager: TerminalSessionManager` aux méthodes qui en ont besoin (pattern déjà utilisé par `launchTask`) :
- `completeTask(_:sessionManager:)` — passe le sessionManager à `startAutoArchive`
- `archiveTask(_:sessionManager:)` — appelle `sessionManager.removeSession(for: task.slug)` + `stateMonitor.removeState(for:)` via un closure optionnel
- `pinTask(_:sessionManager:)` — passe le sessionManager à `startAutoArchive`
- `startAutoArchive(for:sessionManager:)` — passe le sessionManager à `archiveTask`
- `onProcessTerminated` callback dans `launchTask` : passer `sessionManager` à `completeTask`

> Note : plutôt que de threader aussi le `stateMonitor`, ajouter un closure optionnel `onSessionRemoved: ((String) -> Void)?` sur `TaskListViewModel` que `ContentView` peut setter pour nettoyer le monitor state.

**Fichiers call sites à mettre à jour :**
- `ContentView.swift` l.81 : `viewModel.pinTask(task, sessionManager: sessionManager)`
- `ContentView.swift` l.176 : `viewModel.completeTask(task, sessionManager: sessionManager)`
- `TaskListPage.swift` l.36 : `viewModel.pinTask(task, sessionManager: sessionManager)`

**Fichier : `ClaudeHub/ClaudeHubApp.swift`**

- Ajouter `.onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification))` pour appeler `stateMonitor.stop()` puis `sessionManager.removeAll()`
- Mettre à jour le quit dialog : utiliser `sessionManager.hasRunningSessions` au lieu de `activeSessions.isEmpty`

### Commit 3 : fix(monitor): auto-stop timer when no running sessions

**Fichier : `ClaudeHub/Services/TerminalStateMonitor.swift`**

- Dans `scanAllSessions()` : ne scanner que les sessions dont le process est `running` (via `sessionManager.activeSessions.keys` filtré par `cachedTerminalView(for:)?.process.running == true`)
- Si aucune session running trouvée, appeler `stop()` pour arrêter le timer

**Fichier : `ContentView.swift`**

- Ajouter `.onChange(of: sessionManager.activeSessions.count)` pour relancer `stateMonitor.start(sessionManager:)` quand des sessions passent de 0 à >0

## Fichiers modifiés

| Fichier | Changements |
|---------|-------------|
| `ClaudeHub/Services/TerminalSessionManager.swift` | `terminate()` dans removeSession/removeAll, `hasRunningSessions` |
| `ClaudeHub/Features/TaskList/TaskListViewModel.swift` | sessionManager param sur complete/archive/pin/startAutoArchive |
| `ClaudeHub/ContentView.swift` | call sites + onChange monitor restart + onSessionRemoved |
| `ClaudeHub/Features/TaskList/pages/TaskListPage.swift` | call site pinTask |
| `ClaudeHub/ClaudeHubApp.swift` | willTerminate cleanup + hasRunningSessions guard |
| `ClaudeHub/Services/TerminalStateMonitor.swift` | auto-stop quand idle |

## Vérification

```bash
xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build
```

Puis test manuel :
1. Lancer une session → ne crash plus
2. Laisser une session se compléter → auto-archive nettoie la session
3. Quitter l'app avec sessions actives → pas de crash
4. Lancer/compléter/archiver plusieurs sessions → pas de leak mémoire
