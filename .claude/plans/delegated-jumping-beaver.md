# Fix: Permission denied on ralph-loop stop-hook.sh

## Context
Le hook `stop-hook.sh` du plugin ralph-loop n'a pas le flag d'exécution, ce qui cause une erreur "Permission denied" à chaque fin de session Claude Code.

## Fix
```bash
chmod +x /Users/thibaut/.claude/plugins/marketplaces/claude-plugins-official/plugins/ralph-loop/hooks/stop-hook.sh
```

## Vérification
Confirmer que le fichier a bien les permissions `-rwxr-xr-x`.
