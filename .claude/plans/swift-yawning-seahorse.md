# Ajouter `❯` comme marker de détection `.waiting`

## Contexte
Quand Claude CLI pose une question (AskUserQuestion, choix numérotés), le terminal affiche le caractère `❯` devant les options. On veut que le `TerminalStateMonitor` détecte ce caractère comme indicateur de `.waiting` (user input needed).

## Changements

### 1. `ClaudeHub/Services/TerminalStateMonitor.swift:53`
Ajouter `❯` au default des markers waiting :
```
"◆ waiting,Chat about this,Skip interview" → "◆ waiting,Chat about this,Skip interview,❯"
```

### 2. `ClaudeHub/Features/Settings/pages/SettingsPage.swift:11`
Aligner le default `@AppStorage` avec le monitor :
```
"◆ waiting" → "◆ waiting,Chat about this,Skip interview,❯"
```

### 3. `ClaudeHub/Features/Settings/organisms/StatusMarkersSection.swift:13`
Aligner le `defaultValue` affiché dans l'UI :
```
"◆ waiting" → "◆ waiting,Chat about this,Skip interview,❯"
```

## Vérification
- Build avec `xcodebuild -scheme ClaudeHub -destination 'platform=macOS' build`
- Commit
