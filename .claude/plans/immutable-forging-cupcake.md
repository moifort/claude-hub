# Bouton Commit : texte au lieu d'icône

## Context
Dans le GitTree, le bouton "commit all" sur la ligne des fichiers non commités utilise une icône (`arrow.up.doc`). L'utilisateur veut le remplacer par le texte "Commit" en gardant le même style visuel (orange, capsule, `.caption2`).

## Fichier à modifier
- `ClaudeHub/Features/GitTree/molecules/UncommittedRowDetail.swift` (ligne 20)

## Changement
Remplacer `Image(systemName: "arrow.up.doc")` par `Text("Commit")` — garder `.font(.caption2)`, `.foregroundStyle(.orange)`, padding et background capsule identiques.

## Vérification
- `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
