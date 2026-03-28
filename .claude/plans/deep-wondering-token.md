# Fix : le terminal affiche toujours la première tâche

## Context

Après le refactoring "eager launch", quand on clique sur une deuxième tâche, le terminal affiche toujours la première. Cause : `NSViewRepresentable.makeNSView()` n'est appelé qu'une fois. `updateNSView()` est vide, donc le changement de `taskSlug` n'a aucun effet.

## Fix

Ajouter `.id(task.slug)` sur le `TerminalContainer` dans `ContentView.detailView()`. Cela force SwiftUI à détruire et recréer la vue NSViewRepresentable quand le slug change.

## Fichier à modifier

- `ClaudeHub/ContentView.swift` — ligne ~194 : ajouter `.id(task.slug)` sur `TerminalContainer`

## Commit

`fix(terminal): show correct terminal when switching between tasks`

## Vérification

- Build : `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
- Test manuel : lancer 2 tâches, cliquer sur chacune → le bon terminal s'affiche
