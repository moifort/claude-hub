# Atténuer visuellement les tâches completed dans la sidebar

## Context

Les tâches complétées utilisent actuellement un vert vif (`.green`) pour le dot et le texte de statut, ce qui attire autant l'attention que les tâches actives. Une tâche terminée n'est plus prioritaire — elle doit s'effacer visuellement pour laisser le focus sur les tâches en cours.

## Changes

### `ClaudeHub/Features/Sidebar/molecules/SidebarTaskRow.swift`

Appliquer une opacité réduite sur l'ensemble de la row quand `status == .completed` :

- Ajouter `.opacity(status == .completed ? 0.5 : 1.0)` sur le `VStack` principal (après `.padding(.vertical, 2)`)

Cela atténue **tout** d'un coup — titre, dot, texte de statut, countdown — sans toucher aux couleurs individuellement. Simple, cohérent, réversible.

### Mettre à jour la preview

Aucun changement — la preview contient déjà un cas `.completed`.

## Verification

```bash
xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build
```

## Commits

1. `style(sidebar): dim completed tasks to reduce visual prominence`
