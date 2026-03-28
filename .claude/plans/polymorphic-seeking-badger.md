# Remove "New Task" button from task toolbar

## Context

Quand une task est sélectionnée, un bouton "+" (New Task) apparaît en haut à droite de la toolbar. Il ne sert à rien et encombre l'interface.

## Fichier à modifier

`ClaudeHub/ContentView.swift` — lignes 85-92

## Changement

Supprimer le bloc `if let project = task.project { ... }` qui affiche le bouton "New Task" avec l'icône "plus" dans le `ToolbarItemGroup`.

## Commit prévu

`fix(toolbar): remove useless "New Task" button from task toolbar`

## Verification

`xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
