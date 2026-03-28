# Bouton "Commit All" sur la ligne des fichiers non commités du GitTree

## Context

L'utilisateur veut un bouton sur la ligne des fichiers non commités dans le panneau GitTree (inspector) qui crée et lance une tâche Claude avec le prompt "commit all remaining files". Le bouton doit avoir le même style que les `SyncBadge` (capsule teintée avec icône).

## Approche

Passer une closure `onCommitAll` à travers la chaîne de vues : `ContentView` → `GitTreePanel` → `GitTreeList` → `UncommittedRowDetail`. Dans `ContentView`, la closure crée un `TaskItem` et le lance.

## Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `ClaudeHub/Features/GitTree/molecules/UncommittedRowDetail.swift` | Ajouter un bouton style `SyncBadge` (capsule orange, icône `arrow.up.doc`) |
| `ClaudeHub/Features/GitTree/organisms/GitTreeList.swift` | Propager la closure `onCommitAll` vers `UncommittedRowDetail` |
| `ClaudeHub/Features/GitTree/pages/GitTreePanel.swift` | Propager la closure `onCommitAll` vers `GitTreeList` |
| `ClaudeHub/ContentView.swift` | Fournir la closure qui crée + lance la tâche "commit all remaining files" |

## Détail des changements

### 1. `UncommittedRowDetail.swift`

Ajouter une prop `onCommitAll: () -> Void` et un `Button` style capsule (comme `SyncBadge`) :

```swift
struct UncommittedRowDetail: View {
    let count: Int
    var onCommitAll: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            Text(...)
            Spacer(minLength: 4)
            if let onCommitAll {
                Button(action: onCommitAll) {
                    Image(systemName: "arrow.up.doc")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12), in: .capsule)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

### 2. `GitTreeList.swift`

Ajouter `var onCommitAll: (() -> Void)? = nil` et le passer à `UncommittedRowDetail`.

### 3. `GitTreePanel.swift`

Ajouter `var onCommitAll: (() -> Void)? = nil` et le passer à `GitTreeList`.

### 4. `ContentView.swift`

Dans l'inspector, passer la closure à `GitTreePanel` :

```swift
GitTreePanel(repoPath: project.path, projectName: project.name, refreshTrigger: appModel.gitTreeRefreshTrigger, onCommitAll: {
    createCommitTask(for: project)
})
```

Ajouter la méthode `createCommitTask(for:)` qui :
- Crée un `TaskItem` avec title/prompt "commit all remaining files"
- L'insère dans le `modelContext`
- Le lance via `viewModel.launchTask()`

## Commits prévus

1. `feat(git-tree): add commit-all button on uncommitted files row`

## Vérification

- Build avec `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
- Vérifier visuellement que le bouton apparaît sur la ligne des fichiers non commités
- Vérifier que cliquer sur le bouton crée et lance une tâche
