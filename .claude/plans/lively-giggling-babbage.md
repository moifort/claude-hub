# Bouton "Créer une nouvelle tâche" dans la sidebar

## Context

Quand un projet n'a aucune tâche active, il n'y a actuellement aucun moyen de créer une tâche depuis la sidebar. Le bouton "New Task" n'apparaît que dans la toolbar quand une tâche est déjà sélectionnée (`ContentView:56-66`). L'utilisateur veut un bouton visible directement dans la liste du projet quand il est vide, qui ouvre le modal `NewTaskSheet` existant.

L'infrastructure existe déjà :
- `NewTaskSheet` — modal de saisie de prompt
- `CLIService.decomposeTask()` — décomposition via Claude CLI
- `NewTaskViewModel` — orchestration création/décomposition
- `SidebarPage` a déjà `showNewTaskSheet` et `newTaskProject` en `@State` (inutilisés)

## Plan

### Commit 1 : `feat(sidebar): add new-task button for empty projects`

**Fichiers modifiés :**

1. **`ClaudeHub/Features/Sidebar/organisms/ProjectListSection.swift`**
   - Ajouter callback `onNewTask: (PersistentIdentifier) -> Void`
   - Dans le `DisclosureGroup` content, quand `project.tasks.isEmpty`, afficher un bouton :
     ```swift
     Button {
         onNewTask(project.id)
     } label: {
         Label("Créer une nouvelle tâche", systemImage: "plus.circle")
             .font(.subheadline)
             .foregroundStyle(.secondary)
     }
     .buttonStyle(.plain)
     ```
   - Mettre à jour les `#Preview` avec le nouveau paramètre

2. **`ClaudeHub/Features/Sidebar/pages/SidebarPage.swift`**
   - Passer `onNewTask` à `ProjectListSection` :
     ```swift
     onNewTask: { projectID in
         newTaskProject = projects.first { $0.persistentModelID == projectID }
         showNewTaskSheet = true
     }
     ```
   - Ajouter `.sheet` sur la `List` pour présenter `NewTaskSheet` :
     ```swift
     .sheet(isPresented: $showNewTaskSheet) {
         if let project = newTaskProject {
             NewTaskSheet(project: project)
         }
     }
     ```

C'est tout. Le reste du pipeline (décomposition Claude CLI, création des tâches, exécution en worktrees) fonctionne déjà.

## Vérification

- Build : `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
- Vérifier visuellement : ouvrir un projet sans tâches → le bouton "Créer une nouvelle tâche" est visible dans le sous-menu du projet
- Cliquer le bouton → le modal `NewTaskSheet` s'ouvre avec le bon projet
- Saisir un prompt → la décomposition se lance et crée les sous-tâches
