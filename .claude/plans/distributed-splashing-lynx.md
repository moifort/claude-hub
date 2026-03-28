# Ajouter task/ et .idea/ au .gitignore

## Context
Le `git add -A` a embarqué des répertoires de worktrees (`task/`) et de l'IDE JetBrains (`.idea/`).

## Plan
1. Ajouter `task/` et `.idea/` au `.gitignore`
2. `git rm -r --cached task/ .idea/` pour arrêter le tracking
3. Commit

## Vérification
`git status` ne doit plus montrer task/ ni .idea/
