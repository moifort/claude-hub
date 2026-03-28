# Simplifier l'affichage des tâches dans la sidebar

## Context

Actuellement, `SidebarTaskRow` affiche un titre + un sous-titre (summary) + une date. L'utilisateur veut simplifier : afficher uniquement le summary comme titre unique, et aligner l'icône de statut en haut.

## Fichiers à modifier

1. **`ClaudeHub/Features/Sidebar/molecules/SidebarTaskRow.swift`**
2. **`ClaudeHub/Features/Sidebar/organisms/ProjectListSection.swift`**
3. **`ClaudeHub/Features/Sidebar/pages/SidebarPage.swift`**

## Changements

### 1. `SidebarTaskRow.swift`
- Supprimer le paramètre `summary`
- Changer `HStack(alignment: .center)` → `HStack(alignment: .top)` pour remonter l'icône
- Supprimer le `Text(summary ?? title)` (le sous-titre)
- Garder le titre (qui recevra désormais le summary) et la date relative
- Permettre 2 lignes pour le titre (puisque le summary peut être plus long)

### 2. `ProjectListSection.swift`
- Supprimer le champ `summary` de `TaskInfo`
- Ne plus passer `summary` à `SidebarTaskRow`

### 3. `SidebarPage.swift`
- Passer `task.summary ?? task.title` comme `title` au lieu de passer title et summary séparément

## Commits

1. `refactor(sidebar): simplify task row to show summary as single title`

## Vérification

- `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
