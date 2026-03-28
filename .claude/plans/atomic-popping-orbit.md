# Changement des icônes de statuts

## Context
Les icônes actuelles des statuts de tâches manquent de personnalité. L'utilisateur veut une cloche pleine pour `waiting` (user input) et de nouvelles icônes plus expressives pour les autres statuts, sauf `running` qui reste inchangé.

## Fichier à modifier
- `ClaudeHub/Models/TaskStatus.swift` — propriété `iconName`

## Changements

| Status | Avant | Après | Raison |
|---|---|---|---|
| `pending` | `clock` | `hourglass` | Plus évocateur d'une attente passive |
| `running` | `play.circle.fill` | **inchangé** | — |
| `waiting` | `questionmark.circle.fill` | `bell.fill` | Demande utilisateur — cloche = notification/action requise |
| `planReady` | `doc.text.magnifyingglass` | `list.clipboard.fill` | Plan/checklist prêt à valider |
| `completed` | `checkmark.circle.fill` | `checkmark.seal.fill` | Sceau de validation, plus distinctif |
| `archived` | `archivebox.fill` | `tray.full.fill` | Bac rempli, plus léger visuellement |

## Vérification
```bash
xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build
```

## Commit
- `style(status): update task status icons for better clarity`
