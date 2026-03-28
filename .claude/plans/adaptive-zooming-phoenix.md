# Détection d'activité terminal par instabilité du buffer + priorité par confiance

## Context

Le monitoring actuel repose sur des marqueurs textuels explicites (`◆ working`, `◆ waiting`, `◆ done`) avec une logique "last match wins" qui ne respecte pas le niveau de confiance des états. De plus, `❯` est utilisé comme marqueur de waiting alors que la détection par instabilité du buffer serait plus fiable.

Claude Code CLI affiche nativement un spinner quand il travaille — un signal indépendant du system prompt qu'on peut exploiter via la comparaison du buffer entre polls.

## Changements

### 1. Priorité par confiance dans la détection de marqueurs

Remplacer "last match wins" par un système de priorité :

```
.working > .planReady > .done > .waiting
```

Si le buffer contient à la fois `◆ working` et un marqueur waiting, `.working` gagne toujours.

**Implémentation** : assigner un poids numérique à chaque `DetectedState`, scanner toutes les lignes, garder le match avec le poids le plus élevé.

```swift
extension DetectedState {
    var priority: Int {
        switch self {
        case .working: 4
        case .planReady: 3
        case .done: 2
        case .waiting: 1
        }
    }
}
```

Dans `scanBuffer`, remplacer :
```swift
// Avant : last match wins
lastMarkerState = state
```
par :
```swift
// Après : highest priority wins
if state.priority > (bestMarkerState?.priority ?? 0) {
    bestMarkerState = state
}
```

### 2. Supprimer `❯` des marqueurs waiting par défaut

Dans `loadPatterns()`, changer le défaut de `markersWaiting` :
```swift
// Avant
"◆ waiting,Chat about this,Skip interview,❯"
// Après
"◆ waiting,Chat about this,Skip interview"
```

### 3. Détection par instabilité du buffer (fallback)

Nouvelles propriétés :
```swift
private var previousSnapshots: [String: String] = [:]
private var stablePolls: [String: Int] = [:]
private let stableThreshold = 3  // 3 polls stables (6s) → waiting
```

Logique dans `scanBuffer` après la recherche de marqueurs :
1. Capturer le texte des 30 dernières lignes en snapshot
2. **Si marqueur trouvé** → retourner le meilleur par priorité, reset compteurs
3. **Si aucun marqueur** → comparer snapshot avec le précédent :
   - Différent → `.working`, reset compteur
   - Identique → incrémenter compteur
     - Compteur ≥ 3 → `.waiting`
     - Sinon → `nil`

Cleanup dans `removeState` : nettoyer `previousSnapshots[slug]` et `stablePolls[slug]`.

## Fichier modifié

- `ClaudeHub/Services/TerminalStateMonitor.swift` — priorité, instabilité, suppression `❯`

## Comportement attendu

| Situation | Marqueur | Instabilité | État final |
|---|---|---|---|
| Claude écrit du code | `◆ working` | Instable | `.working` (marqueur) |
| Spinner tourne, pas de marqueur | — | Instable | `.working` (instabilité) |
| Prompt affiché, rien ne bouge | — | Stable 6s+ | `.waiting` (instabilité) |
| `◆ waiting` + `◆ working` dans buffer | Les deux | — | `.working` (priorité) |
| `◆ done` affiché | `◆ done` | Stable | `.done` (marqueur) |

## Commits prévus

1. `feat(monitor): add confidence-based priority and buffer instability detection`

## Vérification

- Build : `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
- Test manuel :
  - Lancer une task → spinner détecté comme working sans marqueur explicite
  - Prompt idle 6s+ → détecté comme waiting
  - Marqueurs explicites prennent toujours le dessus
  - Si working + waiting dans le buffer → working gagne
