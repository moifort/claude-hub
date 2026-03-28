# Fix: Section Archives dans la sidebar

## Context

La section "Archives" dans la sidebar gauche a besoin de 3 améliorations :
1. La corbeille pour tout supprimer (visible au hover, comme Finder)
2. Un bouton "Restore" au hover sur chaque tâche archivée
3. Les tâches archivées ne doivent pas être indentées

La section ne doit **PAS** être collapsible — elle reste toujours visible.

## Ce qui change, fichier par fichier

---

### `ArchivesSection.swift` (3 changements)

**Avant :**
```swift
CollapsibleSidebarRow(isExpanded: $isExpanded) {
    HStack(spacing: 6) {
        Image(systemName: "archivebox")
        Text("Archives")
    }
} content: {
    ForEach(archives) { archive in
        ArchivedTaskRow(title:..., projectName:..., archivedAt:...)
            .tag(archive.id)
            .padding(.leading, 8)   // ← indentation
    }
}
```

**Après :**
```swift
// Plus de CollapsibleSidebarRow — section toujours visible
Section {
    ForEach(archives) { archive in
        ArchivedTaskRow(title:..., projectName:..., archivedAt:..., onRestore: { onRestore(archive.id) })
            .tag(archive.id)
            // Plus de .padding(.leading, 8)
    }
} header: {
    HStack(spacing: 6) {
        Image(systemName: "archivebox")
        Text("Archives")
        Spacer()
        // Corbeille visible uniquement au hover (comme Finder)
        if isHoveringHeader {
            Button { showDeleteConfirmation = true } label: {
                Image(systemName: "trash").font(.caption)
            }
            .buttonStyle(.plain)
        }
    }
    .onHover { isHoveringHeader = $0 }
    .confirmationDialog("Delete all archived tasks?", isPresented: $showDeleteConfirmation) {
        Button("Delete All", role: .destructive) { onDeleteAll() }
    }
}
```

Nouveaux paramètres ajoutés :
- `let onDeleteAll: () -> Void` — appelé quand l'utilisateur confirme la suppression
- `let onRestore: (PersistentIdentifier) -> Void` — appelé avec l'ID de la tâche à restaurer

---

### `ArchivedTaskRow.swift` (1 changement)

**Avant :** affiche juste le titre + metadata, pas d'action

**Après :** ajoute un bouton "Restore" visible au hover

```swift
struct ArchivedTaskRow: View {
    let title: String
    let projectName: String
    let archivedAt: Date
    let onRestore: () -> Void          // ← nouveau

    @State private var isHovering = false  // ← nouveau

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)...
                HStack(spacing: 4) { Text(projectName)... }
            }
            Spacer()
            if isHovering {                 // ← nouveau
                Button { onRestore() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Restore")
            }
        }
        .onHover { isHovering = $0 }       // ← nouveau
    }
}
```

---

### `SidebarPage.swift` (1 changement)

Passer les deux callbacks à `ArchivesSection` :

```swift
ArchivesSection(
    archives: ...,     // ← inchangé
    onDeleteAll: {
        for task in archivedTasks { modelContext.delete(task) }
    },
    onRestore: { id in
        guard let task = archivedTasks.first(where: { $0.persistentModelID == id }) else { return }
        task.taskStatus = .completed
        task.archivedAt = nil
    }
)
```

`onRestore` remet la tâche en statut `.completed` et efface `archivedAt` → elle réapparaît dans la liste active de son projet.

---

## Fichiers modifiés

| Fichier | Changement |
|---------|------------|
| `Features/Sidebar/organisms/ArchivesSection.swift` | Remplacer CollapsibleSidebarRow par Section, ajouter corbeille au hover + confirmationDialog, supprimer indentation, ajouter callbacks |
| `Features/Sidebar/molecules/ArchivedTaskRow.swift` | Ajouter bouton Restore au hover |
| `Features/Sidebar/pages/SidebarPage.swift` | Passer onDeleteAll et onRestore |

## Commit prévu

1. `feat(sidebar): add delete-all and restore to archives section`

## Vérification

1. `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
2. Test : hover sur le header "Archives" → icône corbeille apparaît → clic → confirmation → supprime toutes les archives
3. Test : hover sur une tâche archivée → bouton restore apparaît → clic → la tâche revient dans le projet en statut "Completed"
4. Test : les tâches archivées ne sont plus indentées par rapport aux tâches normales
