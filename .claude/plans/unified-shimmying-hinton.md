# UI : Maximiser la place du titre dans les task rows de la sidebar

## Contexte

Le titre de la tâche dans la sidebar ne prend pas assez de place. L'espace est gaspillé par le spacing, le frame du cercle de status, et l'indentation.

## Changements

**Fichier** : `ClaudeHub/Features/Sidebar/molecules/SidebarTaskRow.swift`

- Réduire le spacing du HStack : `10` → `6`
- Réduire le frame du cercle : `width: 12` → `width: 8`
- Retirer le `Spacer()` (inutile, le VStack est déjà en `.leading`)

**Fichier** : `ClaudeHub/Features/Sidebar/organisms/ProjectListSection.swift:45`

- Réduire le padding d'indentation : `.padding(.leading, 8)` → `.padding(.leading, 4)`

## Commits

1. `fix(sidebar): maximize task title space in sidebar rows`

## Vérification

- Build : `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
- Visuel : vérifier que le titre prend le max de largeur tout en restant esthétique
