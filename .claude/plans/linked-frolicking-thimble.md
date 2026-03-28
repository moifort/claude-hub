# Countdown d'archivage dans la sidebar

## Context

Quand une tâche passe en `completed`, un auto-archivage se déclenche après 5 minutes (300s). Actuellement, le countdown n'est visible que dans le TaskList (panneau principal). L'utilisateur veut voir le temps restant + un bouton "Keep" directement dans la ligne de la sidebar (SidebarTaskRow), sur la même ligne que le status.

## Approach

Propager `completedAt`, `isPinned`, et une action `onKeep` à travers la chaîne : `SidebarPage` → `ProjectListSection` → `SidebarTaskRow`. Afficher un countdown inline quand le status est `.completed` et la tâche n'est pas pinnée.

## Files to modify

### 1. `ClaudeHub/Features/Sidebar/organisms/ProjectListSection.swift`
- Ajouter `completedAt: Date?` et `isPinned: Bool` à `TaskInfo`
- Ajouter une closure `onKeep: (PersistentIdentifier) -> Void` aux props de `ProjectListSection`
- Passer les nouvelles props à `SidebarTaskRow`

### 2. `ClaudeHub/Features/Sidebar/molecules/SidebarTaskRow.swift`
- Ajouter les props : `completedAt: Date?`, `isPinned: Bool`, `onKeep: () -> Void`
- Quand `status == .completed && !isPinned && remainingSeconds > 0` : afficher sur la ligne du status un texte `"Xs"` + bouton "Keep" (réutiliser le style compact de `CountdownBadge`)
- Utiliser `TimelineView(.periodic(from: .now, by: 1))` pour rafraîchir chaque seconde
- Calcul : `remaining = Constants.archiveDelay - Date.now.timeIntervalSince(completedAt)`

### 3. `ClaudeHub/Features/Sidebar/pages/SidebarPage.swift`
- Passer `completedAt: task.completedAt` et `isPinned: task.isPinned` dans le mapping `TaskInfo`
- Ajouter `onKeep` qui appelle `TaskListViewModel.pinTask()` sur la tâche correspondante

## Verification

- Build : `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
- Vérifier visuellement : tâche completed → countdown visible dans la sidebar
- Cliquer "Keep" → countdown disparaît, tâche pinnée
