# Fix: claude not found in PATH

## Context

L'app macOS GUI a un PATH minimal (`/usr/bin:/bin:/usr/sbin:/sbin`). Le wrapper cmux à `/Applications/cmux.app/.../claude` exécute `find_real_claude()` qui cherche le vrai binaire claude dans `$PATH` — il ne trouve pas `/opt/homebrew/bin/claude`.

## Fix

Modifier `CLIService.swift` :
1. Ajouter `/opt/homebrew/bin/claude` dans les candidats de `claudePath()`
2. Créer une méthode `enrichedEnvironment()` qui augmente PATH avec les répertoires courants
3. Utiliser cet environnement enrichi dans `decomposeTask()` (et il est déjà utilisé par `launchTask` via `ProcessInfo.processInfo.environment`)

## Fichier

`ClaudeHub/Services/CLIService.swift`

## Commits

- `fix(cli): add /opt/homebrew/bin to PATH for GUI app environment`

## Vérification

Lancer l'app, soumettre un prompt → la décomposition doit fonctionner sans erreur PATH.
