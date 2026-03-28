# Plan : Settings General — Claude CLI Configuration

## Context

Le flag `--allow-dangerously-skip-permissions` est actuellement hardcodé dans 2 endroits du code. Le chemin du binaire Claude est résolu dynamiquement sans possibilité d'override. On ajoute un onglet "General" dans les Settings pour exposer ces deux réglages.

## Fichiers à modifier

1. **`ClaudeHub/Features/Settings/pages/SettingsPage.swift`** — Ajouter l'onglet "General"
2. **`ClaudeHub/Features/Settings/organisms/GeneralSettingsSection.swift`** *(nouveau)* — Section avec toggle + champ chemin
3. **`ClaudeHub/Services/CLIService.swift`** — `claudePath()` utilise le chemin custom s'il existe
4. **`ClaudeHub/Features/TaskList/TaskListViewModel.swift`** — Conditionner `--allow-dangerously-skip-permissions` sur le setting
5. **`ClaudeHub/ContentView.swift`** — Idem, conditionner le flag

## Implémentation

### 1. Créer `GeneralSettingsSection.swift`

Nouveau fichier `Features/Settings/organisms/GeneralSettingsSection.swift` :

- **Toggle** `skipPermissions` (`@Binding<Bool>`) — "Skip Permissions" avec description expliquant le flag `--allow-dangerously-skip-permissions`. Activé par défaut.
- **TextField** `claudeBinaryPath` (`@Binding<String>`) — Champ éditable pour le chemin du binaire. Placeholder : chemin auto-détecté. Bouton "Auto-detect" pour réinitialiser.
- **Indicateur de validité** — Petit indicateur (icône checkmark/xmark) à côté du champ pour signaler si le binaire existe au chemin spécifié.
- Style cohérent avec `TaskSettingsSection` (headline + caption, `.monospaced` pour le champ path).

### 2. Modifier `SettingsPage.swift`

- Ajouter `@AppStorage("skipPermissions") private var skipPermissions = true`
- Ajouter `@AppStorage("claudeBinaryPath") private var claudeBinaryPath = ""` (vide = auto-detect)
- Ajouter un onglet "General" (icône `gear`) **avant** l'onglet "Tasks"
- Passer les bindings à `GeneralSettingsSection`

### 3. Modifier `CLIService.claudePath()`

- Lire `UserDefaults.standard.string(forKey: "claudeBinaryPath")`
- Si non-vide et le fichier est exécutable → retourner ce chemin
- Sinon, fallback sur la logique actuelle (candidates + `which`)

### 4. Conditionner le flag dans `TaskListViewModel` et `ContentView`

- Lire `UserDefaults.standard.bool(forKey: "skipPermissions")` (default `true` via `register(defaults:)`)
- Si activé : inclure `"--allow-dangerously-skip-permissions"` dans les arguments
- Si désactivé : omettre le flag

Attention : `UserDefaults.bool(forKey:)` retourne `false` si la clé n'existe pas. Il faut soit utiliser `register(defaults:)` dans l'App init, soit vérifier avec `object(forKey:)`. L'approche la plus simple : enregistrer le default dans `ClaudeHubApp.init`.

### 5. Enregistrer les defaults

Dans `ClaudeHubApp.swift` (ou au lancement), ajouter :
```swift
UserDefaults.standard.register(defaults: ["skipPermissions": true])
```

## Commits prévus

1. `feat(settings): add General tab with Claude CLI configuration`
   — Crée `GeneralSettingsSection`, modifie `SettingsPage`, `CLIService`, `TaskListViewModel`, `ContentView`, `ClaudeHubApp`

## Vérification

- Build : `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
- Vérifier visuellement : ouvrir Settings → onglet General visible avec toggle et champ path
- Toggle OFF → relancer une tâche → vérifier que le flag n'est pas dans les arguments
- Champ path custom → vérifier que `CLIService.claudePath()` retourne le custom
