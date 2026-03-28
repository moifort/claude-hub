# Uniformiser la couleur des tâches completed dans la sidebar

## Context

Quand une tâche est `completed`, la ligne dans la sidebar utilise encore des couleurs distinctes pour le status (vert) et le bouton "Keep" (bleu). L'utilisateur souhaite que tout soit de la même couleur que le titre — aucune couleur spéciale sur le dot, le texte du status, ni le bouton.

## Fichier à modifier

- `ClaudeHub/Features/Sidebar/molecules/SidebarTaskRow.swift`

## Changements

Dans `SidebarTaskRow.swift`, pour les éléments suivants, utiliser `.primary` au lieu de leur couleur actuelle quand `status == .completed` :

1. **Status dot** (ligne 26) : `foregroundStyle(status.tintColor)` → `foregroundStyle(status == .completed ? .primary : status.tintColor)`
2. **Status text** (ligne 31) : idem
3. **Countdown separator "·"** (ligne 42) : `.foregroundStyle(.tertiary)` → `.foregroundStyle(.primary)` (déjà atténué par l'opacity 0.5)
4. **Countdown seconds** (ligne 46) : `.foregroundStyle(.secondary)` → `.foregroundStyle(.primary)`
5. **Bouton "Keep"** (ligne 51) : `.foregroundStyle(.blue)` → `.foregroundStyle(.primary)`

Note : l'opacity 0.5 appliquée à toute la ligne (ligne 67) suffit à atténuer visuellement — pas besoin de couleurs secondaires en plus.

## Vérification

```bash
xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build
```

## Commits

1. `style(sidebar): use uniform color for completed task rows`
