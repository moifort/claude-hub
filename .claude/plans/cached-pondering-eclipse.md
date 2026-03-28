# Plan: Uncommitted files row in Git Tree

## Context

Le git tree (inspector panel) affiche actuellement uniquement l'historique des commits. L'utilisateur veut voir les fichiers non commités en premier, tout en haut de la liste, avec un style distinctif — comme dans SourceTree/Tower qui affichent une entrée "Uncommitted changes" au sommet du graphe.

## Approche

### 1. GitService — ajouter `fetchStatus`

**Fichier**: `ClaudeHub/Services/GitService.swift`

Ajouter une méthode qui exécute `git status --porcelain` et retourne le nombre de fichiers modifiés :

```swift
static func fetchUncommittedCount(repoPath: String) async throws -> Int
```

Parse la sortie de `git status --porcelain` — chaque ligne non vide = 1 fichier modifié.

### 2. GitTreeViewModel — charger le status

**Fichier**: `ClaudeHub/Features/GitTree/GitTreeViewModel.swift`

- Ajouter `private(set) var uncommittedCount: Int = 0`
- Dans `load()` et `refresh()`, appeler `GitService.fetchUncommittedCount` en parallèle du commit log
- Le file watcher surveille déjà `.git/refs/heads/main` — ajouter aussi la surveillance de `.git/index` (le fichier qui change quand on stage/unstage des fichiers)

### 3. UncommittedRowDetail — nouvelle molecule

**Fichier**: `ClaudeHub/Features/GitTree/molecules/UncommittedRowDetail.swift`

Composant pur qui affiche le texte "n uncommitted files" avec un style distinctif :
- Couleur orange/amber au lieu du bleu des commits
- Texte en italique ou style différent du subject de commit
- Pas de badges local/remote
- Pas de date

### 4. GitTreeList — insérer la row en haut

**Fichier**: `ClaudeHub/Features/GitTree/organisms/GitTreeList.swift`

- Accepter `uncommittedCount: Int` en paramètre
- Si > 0, afficher une row spéciale en premier avec :
  - `GraphRowSegment` avec couleur orange (et `isFirst: true`)
  - `UncommittedRowDetail(count:)`
- Le premier commit réel aura `isFirst: false` (la ligne du graphe se connecte à la row uncommitted)

### 5. GitTreePanel — passer le count

**Fichier**: `ClaudeHub/Features/GitTree/pages/GitTreePanel.swift`

Passer `viewModel.uncommittedCount` à `GitTreeList`.

## Fichiers à modifier/créer

| Fichier | Action |
|---------|--------|
| `Services/GitService.swift` | Ajouter `fetchUncommittedCount` |
| `Features/GitTree/GitTreeViewModel.swift` | Ajouter `uncommittedCount`, charger en parallèle |
| `Features/GitTree/molecules/UncommittedRowDetail.swift` | **Créer** — molecule pour la row uncommitted |
| `Features/GitTree/organisms/GitTreeList.swift` | Accepter et afficher uncommittedCount |
| `Features/GitTree/pages/GitTreePanel.swift` | Passer uncommittedCount |

## Style distinctif

- **Couleur node/ligne** : `.orange` au lieu de `.blue`
- **Texte** : "n uncommitted file(s)" en italique, `.secondary` foreground
- **Node du graphe** : même style mais orange
- La ligne du graphe connecte la row uncommitted au premier commit

## Verification

1. `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
2. Vérifier visuellement : modifier un fichier dans un projet → la row orange apparaît en haut du git tree
3. Commiter → la row disparaît, le commit apparaît normalement
4. Previews : les previews de `GitTreeList` et `UncommittedRowDetail` affichent correctement

## Commits

1. `feat(git-tree): add uncommitted files row at top of commit graph`
