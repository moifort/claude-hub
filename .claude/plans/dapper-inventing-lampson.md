# Sidebar Finder-like: supprimer les sections, chevron on hover

## Context

La sidebar utilise actuellement des `Section("Projects")` et `Section("Archives")` comme en-têtes de groupe. L'utilisateur veut supprimer ces titres de section et afficher directement chaque nom de projet (ex: "Pshook") comme item collapsible de premier niveau. "Archives" doit être au même niveau que les projets, avec la même apparence et interaction. Le comportement cible est celui du Finder macOS : un chevron apparaît aligné à droite au survol pour collapser/expandre.

## Approach

Remplacer `DisclosureGroup` + `Section` par un composant custom `CollapsibleSidebarRow` qui gère manuellement l'état d'expansion et affiche un chevron à droite uniquement au hover. Raison : `DisclosureGroupStyle` place le chevron à gauche et ne supporte pas facilement le hover-only sur macOS.

## Files to modify/create

| File | Action |
|------|--------|
| `molecules/CollapsibleSidebarRow.swift` | **CREATE** — row collapsible generique avec chevron hover a droite |
| `organisms/ProjectListSection.swift` | **MODIFY** — supprimer `Section`, supprimer `onAdd`/"+", remplacer `DisclosureGroup` par `CollapsibleSidebarRow` |
| `organisms/ArchivesSection.swift` | **MODIFY** — supprimer `Section`, utiliser `CollapsibleSidebarRow` |
| `pages/SidebarPage.swift` | **MODIFY** — retirer `onAdd` du call site `ProjectListSection` |
| `molecules/ProjectRow.swift` | **NO CHANGE** |

## Implementation

### Step 1 — Create `CollapsibleSidebarRow` molecule

`ClaudeHub/Features/Sidebar/molecules/CollapsibleSidebarRow.swift`

Composant generique avec :
- `@Binding var isExpanded: Bool`
- `@State private var isHovering = false`
- `@ViewBuilder label` + `@ViewBuilder content`
- Header = `Button` (`.buttonStyle(.plain)`) + `.onHover` pour toggle `isHovering`
- Layout header : `HStack(spacing: 4) { label(); chevron }` — le chevron est un `Image(systemName: "chevron.right")` avec `.rotationEffect(.degrees(isExpanded ? 90 : 0))` et `.opacity(isHovering ? 1 : 0)`, anime en `.easeInOut(duration: 0.15)`
- Children : `if isExpanded { content() }`
- Le toggle utilise `withAnimation(.easeInOut(duration: 0.2))`

Le chevron est inline dans ce composant (pas besoin d'un atom separe pour un seul usage).

### Step 2 — Refactor `ProjectListSection`

- Supprimer le wrapper `Section { } header: { }` entierement
- Supprimer le parametre `onAdd` et le bouton "+" (deja dans la toolbar)
- Ajouter `@State private var expandedProjects: Set<PersistentIdentifier>` (defaut: tous expanded)
- Remplacer `DisclosureGroup` par `CollapsibleSidebarRow(isExpanded: binding(for: project.id))`
- Helper `expandedBinding(for:)` qui cree un `Binding<Bool>` vers le Set
- `.onAppear` initialise le Set avec tous les project IDs
- `.onChange(of: projects)` auto-expand les nouveaux projets
- Garder l'empty state, le context menu, le `onNewTask` button pour projets vides
- Ajouter `.padding(.leading, 8)` sur les children (tasks) pour l'indentation

### Step 3 — Refactor `ArchivesSection`

- Supprimer le wrapper `Section("Archives")`
- Ajouter `@State private var isExpanded = true`
- Utiliser `CollapsibleSidebarRow(isExpanded: $isExpanded)` avec label = `HStack { Image(systemName: "archivebox").foregroundStyle(.secondary); Text("Archives") }`
- Garder le `if !archives.isEmpty` guard
- Ajouter `.padding(.leading, 8)` sur les children (archived tasks) pour l'indentation

### Step 4 — Update `SidebarPage`

- Retirer le parametre `onAdd: pickFolder` du call site `ProjectListSection`
- Le reste ne change pas

## Commits

1. `feat(sidebar): replace sections with Finder-like collapsible rows` — tous les changements ci-dessus

## Verification

- `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build` doit passer
- Verifier visuellement : chaque projet apparait comme item de premier niveau, "Archives" aussi
- Hover sur un projet/archives : chevron apparait a droite, disparait quand la souris quitte
- Click sur le chevron ou la row : collapse/expand avec animation
- Les tasks restent selectionnables et indentees
- Le bouton "+" dans la toolbar fonctionne toujours
- Context menu "Remove Project" fonctionne toujours
