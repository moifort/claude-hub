# Fix: Project row click on entire line

## Context

Le clic sur la ligne du projet dans la sidebar est actuellement separe en deux zones : le label (selectionne le projet) et le chevron (toggle expand/collapse). L'utilisateur veut que **toute la ligne** selectionne le projet et affiche l'inline input.

## Changement

**Fichier** : `ClaudeHub/Features/Sidebar/molecules/CollapsibleSidebarRow.swift`

Revenir a un seul `Button` pour toute la ligne (label + chevron), qui :
1. Appelle `onTap?()` (selection du projet)
2. Auto-expand si collapse (ne collapse pas si deja expanded)

```swift
Button {
    onTap?()
    withAnimation(.easeInOut(duration: 0.2)) {
        if !isExpanded { isExpanded = true }
    }
} label: {
    HStack(spacing: 4) {
        label()
        Image(systemName: "chevron.right")
            ...
    }
}
```

Le chevron reste visuel (indicateur d'etat) mais n'est plus un bouton separe.

## Commit

`fix(sidebar): make entire project row clickable for selection`

## Verification

`xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
