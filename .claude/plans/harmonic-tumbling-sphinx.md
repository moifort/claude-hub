# Plan: Remonter le prompt input vers le haut

## Context
La page de saisie du prompt (`InlineTaskInputPage`) centre verticalement le contenu avec deux `Spacer()` égaux. Le contenu apparaît pile au milieu, alors qu'un positionnement légèrement au-dessus du centre est plus naturel visuellement.

## Approach
Remplacer le `Spacer()` du haut (ligne 16) par un spacer avec une hauteur max limitée, pour que le spacer du bas prenne plus de place et pousse le contenu vers le haut.

```swift
// Avant
Spacer()           // haut — partage 50/50
// ... contenu ...
Spacer()           // bas — partage 50/50

// Après
Spacer().frame(maxHeight: 200)  // haut — limité
// ... contenu ...
Spacer()                         // bas — prend le reste
```

Cela décale le contenu d'environ 100px vers le haut sur un écran standard, tout en restant responsive.

## File
- `ClaudeHub/Features/InlineTaskInput/pages/InlineTaskInputPage.swift` — ligne 16

## Commit
- `style(prompt): shift input content upward for better visual balance`

## Verification
- `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
