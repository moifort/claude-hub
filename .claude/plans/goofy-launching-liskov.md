# Fix: Navigation vers la tâche après création

## Context

Après soumission d'un prompt, `appModel.selectedItemID` est assigné à l'ID de la nouvelle tâche, mais `ContentView.selectedTask` ne la trouve pas car `@Query` (SwiftData) ne se rafraîchit pas dans le même cycle de rendu. Résultat : `selectedTask` = nil, `selectedProject` = nil → la vue reste sur `InlineTaskInputPage` (ou affiche ContentUnavailableView).

Trois tentatives précédentes (`1b46b43`, `54ac36f`, `ec3f202`) ont échoué car elles traitaient le symptôme (timing) plutôt que la cause racine (`@Query` lookup).

## Fix

**Fichier** : `ClaudeHub/ContentView.swift` (lignes 16-19)

Ajouter un fallback `modelContext.registeredModel(for:)` dans `selectedTask`. Cette API SwiftData cherche directement dans le contexte en mémoire — le modèle y est présent immédiatement après `context.insert()` + `save()`, sans attendre le refresh de `@Query`.

Avant :
```swift
private var selectedTask: TaskItem? {
    guard let id = appModel.selectedItemID else { return nil }
    return allTasks.first { $0.persistentModelID == id }
}
```

Après :
```swift
private var selectedTask: TaskItem? {
    guard let id = appModel.selectedItemID else { return nil }
    return allTasks.first { $0.persistentModelID == id }
        ?? modelContext.registeredModel(for: id)
}
```

C'est tout. Un seul changement d'une ligne.

## Pourquoi ça marche

- `context.insert(task)` enregistre le modèle dans le `ModelContext`
- `registeredModel(for:)` le retrouve instantanément via son `PersistentIdentifier`
- Pas de suspension point → pas de reset par NavigationSplitView
- Quand `@Query` se rafraîchit au cycle suivant, le premier path (`allTasks.first`) prend le relais normalement

## Verification

1. `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
2. Lancer l'app, sélectionner un projet, entrer un prompt, appuyer sur Entrée
3. Vérifier que la vue navigue immédiatement vers le terminal de la tâche

## Commits

- `fix(navigation): resolve task from model context when @Query hasn't refreshed`
