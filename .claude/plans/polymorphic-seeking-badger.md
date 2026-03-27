# Fix: Decomposition error handling

## Context

La décomposition en sous-tâches échoue systématiquement. L'erreur réelle est avalée par un catch générique dans `InlineTaskInputViewModel` qui affiche toujours "Decomposition failed — created single task" sans montrer la vraie cause (CLI not found? JSON invalide? timeout?).

## Problèmes identifiés

1. **Erreur masquée** — `InlineTaskInputViewModel.submit()` catch toutes les erreurs et affiche un message générique (ligne 60). L'`error.localizedDescription` n'est jamais propagée.

2. **`waitUntilExit()` bloquant** — Appelé dans un contexte `async`, bloque un thread du pool coopératif Swift. Devrait utiliser une approche non-bloquante.

## Fichiers à modifier

| Fichier | Changement |
|---------|-----------|
| `Features/InlineTaskInput/InlineTaskInputViewModel.swift` | Afficher `error.localizedDescription` au lieu du message générique |
| `Services/CLIService.swift` | Ajouter stderr au message d'erreur de `decompositionFailed`, rendre `decomposeTask` non-bloquant |

## Changements

### 1. InlineTaskInputViewModel — propager l'erreur réelle

```swift
// Ligne 60 — remplacer :
errorMessage = "Decomposition failed — created single task"
// Par :
errorMessage = error.localizedDescription
```

### 2. CLIService — capturer stderr séparément

Actuellement stderr est capturé dans `stderrPipe` mais jamais lu. Quand le process échoue (`terminationStatus != 0`), on ne lit que stdout. Ajouter stderr au message d'erreur :

```swift
guard process.terminationStatus == 0 else {
    let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    let stderr = String(data: errData, encoding: .utf8) ?? ""
    throw CLIError.decompositionFailed(stderr.isEmpty ? output : stderr)
}
```

### 3. CLIService — non-blocking waitUntilExit

Remplacer `process.waitUntilExit()` par un `terminationHandler` wrappé dans `withCheckedContinuation` pour ne pas bloquer le thread pool async.

## Commit prévu

1. `fix(cli): propagate actual decomposition error to UI`

## Verification

1. Build : `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
2. Ouvrir l'app → entrer un prompt → lire le message d'erreur réel affiché
