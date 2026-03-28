# Décomposition on-device via FoundationModels

## Contexte

ClaudeHub crée actuellement une seule tâche par prompt, avec une summarisation on-device (~1s) pour le titre. L'ancienne décomposition CLI (`claude --print`, ~20s) a été supprimée. L'objectif est de ramener la décomposition en utilisant le même `LanguageModelSession` on-device avec des structs `@Generable` pour du structured output rapide.

## Décisions

- **Heuristique auto** : le modèle on-device décide lui-même si le prompt mérite d'être décomposé (`shouldDecompose: Bool`)
- **Toggle** : un switch "Auto-decompose" à côté du champ input, persisté via `@AppStorage`, activé par défaut
- **@Generable** : structured output typé, pas de parsing JSON
- **Auto-launch** : les sous-tâches sont créées et lancées immédiatement en parallèle
- **Fallback** : si la décomposition échoue → fallback vers `SummarizationService` (comportement actuel)

## Fichiers à modifier

| Fichier | Action |
|---------|--------|
| `ClaudeHub/Services/DecompositionService.swift` | **CRÉER** |
| `ClaudeHub/Features/InlineTaskInput/InlineTaskInputViewModel.swift` | **MODIFIER** |
| `ClaudeHub/Features/InlineTaskInput/pages/InlineTaskInputPage.swift` | **MODIFIER** |

Aucun changement nécessaire sur : `TaskItem.swift` (a déjà `parentTaskTitle` et `summary`), `CLIService.swift`, `TaskListViewModel.swift`, `project.yml` (FoundationModels déjà linké).

## Implémentation

### Commit 1 : `feat(decomposition): add on-device DecompositionService with @Generable structs`

**Créer `ClaudeHub/Services/DecompositionService.swift`**

Structs `@Generable` :
- `SubtaskDescriptor` : `title` (max 60 chars), `summary` (1 phrase), `prompt` (instructions détaillées self-contained)
- `DecompositionResult` : `shouldDecompose: Bool`, `subtasks: [SubtaskDescriptor]` (1-6 éléments)

Service :
- `DecompositionService.decompose(prompt:) async -> DecompositionResult`
- System prompt concis (~3 lignes) : "Tu es un planificateur de tâches pour un projet de code. Décide si la tâche doit être scindée en sous-tâches indépendantes et parallélisables dans des worktrees git isolés. Mets shouldDecompose à false pour les tâches simples. Chaque prompt de sous-tâche doit être autonome."
- Fallback : appelle `SummarizationService.summarize` et wrap dans un `DecompositionResult` à 1 élément

### Commit 2 : `feat(decomposition): integrate decomposition in task submission flow`

**Modifier `InlineTaskInputViewModel.swift`**

- Remplacer `isSummarizing: Bool` par `isProcessing: Bool` + `activeMode: ProcessingMode` (enum `.summarizing` | `.decomposing`)
- Ajouter computed `statusMessage: String?` → "Decomposing..." ou "Summarizing..."
- Ajouter computed `canSubmit` mis à jour pour utiliser `isProcessing`
- Paramètre `decompositionEnabled: Bool` sur `submit()`
- Brancher la logique :
  - Si `decompositionEnabled` → `DecompositionService.decompose(prompt:)` → créer N `TaskItem` avec `parentTaskTitle` (prefix 80 chars du prompt original) et `summary`
  - Sinon → `SummarizationService.summarize(prompt:)` → créer 1 `TaskItem` (comportement actuel)
- Lancer toutes les tâches créées via `taskViewModel.launchTask()` en boucle
- Sélectionner la première tâche dans `appModel.selectedItemID`

### Commit 3 : `feat(decomposition): add auto-decompose toggle to input UI`

**Modifier `InlineTaskInputPage.swift`**

- Ajouter `@AppStorage("decompositionEnabled") private var decompositionEnabled = true`
- Ajouter un toggle sous le `TerminalPromptField`, style terminal (monospaced, caption, `.secondary`) :
  ```
  HStack {
      Spacer()
      Toggle(isOn: $decompositionEnabled) {
          Label("Auto-decompose", systemImage: "arrow.triangle.branch")
              .font(.system(.caption, design: .monospaced))
      }
      .toggleStyle(.switch)
      .controlSize(.mini)
      .foregroundStyle(.secondary)
  }
  .frame(maxWidth: 600)
  ```
- Remplacer `viewModel.isSummarizing` par `viewModel.isProcessing` et `viewModel.statusMessage`
- Passer `decompositionEnabled` à `viewModel.submit()`

## Vérification

```bash
xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build
```

Test manuel :
1. Toggle ON → entrer un prompt complexe multi-tâche → vérifier que plusieurs `TaskItem` sont créés et lancés
2. Toggle ON → entrer un prompt simple → vérifier qu'une seule tâche est créée (le modèle met `shouldDecompose: false`)
3. Toggle OFF → comportement identique à l'actuel (summarisation → 1 tâche)
