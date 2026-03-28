# Rendre la scrollbar du terminal plus fine et transparente

## Context

SwiftTerm utilise un `NSScroller` avec le style `.legacy` (épais, toujours visible, opaque). Ce style est hardcodé dans `MacTerminalView.swift` (ligne 502) comme `let scrollerStyle: NSScroller.Style = .legacy`. La propriété `scroller` est privée, mais le NSScroller est ajouté comme subview du terminal, donc accessible via la hiérarchie de vues.

## Approche

Après la création du `LocalProcessTerminalView`, trouver le `NSScroller` dans ses subviews et le passer en style `.overlay` (fin, semi-transparent, auto-hide comme dans les apps natives macOS).

## Fichier à modifier

`ClaudeHub/Features/Terminal/TerminalRepresentable.swift`

## Changement

Dans `TerminalWrapperView.init`, après `addSubview(terminal)`, parcourir les subviews du terminal pour trouver le `NSScroller` et :
1. Changer son `scrollerStyle` en `.overlay` (fin + auto-hide natif macOS)
2. Réduire son `alphaValue` à ~0.5 pour plus de discrétion

```swift
// Dans TerminalWrapperView.init, après addSubview(terminal):
for subview in terminal.subviews {
    if let scroller = subview as? NSScroller {
        scroller.scrollerStyle = .overlay
        scroller.alphaValue = 0.5
    }
}
```

Le style `.overlay` donne automatiquement une scrollbar fine qui apparaît au scroll et disparaît après, comme dans Safari/Finder. L'alpha réduit la rend encore plus discrète.

## Vérification

- `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`

## Commits

1. `fix(terminal): use overlay scroller style for thinner, transparent scrollbar`
