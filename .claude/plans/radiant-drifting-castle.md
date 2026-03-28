# Confirmation de fermeture avec sessions actives

## Context

Quand l'utilisateur quitte ClaudeHub (Cmd+Q), toutes les sessions terminales en cours sont perdues. Il faut afficher un dialogue de confirmation pour prévenir l'utilisateur, uniquement s'il y a des sessions actives. Les états des tâches (SwiftData) sont déjà préservés — seules les sessions terminales live sont perdues.

## Approche

Modifier uniquement `ClaudeHubApp.swift` avec l'approche 100% SwiftUI :
- `.commands { CommandGroup(replacing: .appTermination) }` pour intercepter Cmd+Q
- `.alert()` pour le dialogue de confirmation natif macOS
- Pas de `NSApplicationDelegate`, pas de nouveau fichier

## Fichier modifié

- `ClaudeHub/ClaudeHubApp.swift`

## Implémentation

### 1. Ajouter un état pour le dialogue

```swift
@State private var showQuitConfirmation = false
```

### 2. Remplacer la commande Quit par défaut

Ajouter `.commands` sur le `WindowGroup` :

```swift
.commands {
    CommandGroup(replacing: .appTermination) {
        Button("Quit ClaudeHub") {
            if sessionManager.activeSessions.isEmpty {
                NSApplication.shared.terminate(nil)
            } else {
                showQuitConfirmation = true
            }
        }
        .keyboardShortcut("q")
    }
}
```

Si aucune session active → quitte directement. Sinon → affiche la confirmation.

### 3. Ajouter l'alert de confirmation

Attacher `.alert()` sur le `ContentView()` dans le `WindowGroup` :

```swift
.alert("Quit ClaudeHub?", isPresented: $showQuitConfirmation) {
    Button("Quit", role: .destructive) {
        NSApplication.shared.terminate(nil)
    }
    Button("Cancel", role: .cancel) {}
} message: {
    let count = sessionManager.activeSessions.count
    Text("\(count) terminal \(count == 1 ? "session is" : "sessions are") still running. Task states are saved, but live terminal sessions will be lost.")
}
```

## Ce qui ne change PAS

- Aucun nouveau fichier
- `TerminalSessionManager`, `AppModel`, `ContentView` — inchangés
- Persistance SwiftData — inchangée
- `TerminalStateMonitor` — nettoyé naturellement à la terminaison du process

## Vérification

1. `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
2. Test manuel : lancer une tâche, Cmd+Q → dialogue affiché avec le nombre de sessions
3. Test manuel : aucune tâche active, Cmd+Q → quitte immédiatement sans dialogue

## Commits

- `feat(app): add quit confirmation when terminal sessions are active`
