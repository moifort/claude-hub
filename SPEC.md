# ClaudeHub

Application macOS native pour orchestrer des sessions Claude Code en parallèle sur plusieurs projets git.

## Concept

ClaudeHub est un gestionnaire de tâches visuelles qui lance et supervise des instances Claude Code CLI dans des terminaux embarqués. Chaque tâche s'exécute dans son propre git worktree, permettant le travail parallèle sur un même projet sans conflits.

## Fonctionnalités

### Gestion de projets

- Ajouter un projet git via sélecteur de dossier ou drag-and-drop
- Validation automatique que le dossier est un dépôt git
- Persistance des projets via SwiftData
- Suppression en cascade (projet + toutes ses tâches)

### Création de tâches

- Saisie multilignes dans une sheet modale (Cmd+Return pour envoyer)
- Décomposition automatique : Claude analyse la requête et la découpe en sous-tâches parallélisables et indépendantes
- Chaque sous-tâche reçoit un titre et un prompt détaillé
- Fallback en tâche unique si la décomposition échoue

### Exécution des tâches

- Chaque tâche lance une session Claude Code CLI dans un terminal embarqué (SwiftTerm)
- System prompt injecté automatiquement avec le workflow git :
  - Création d'un worktree dédié (`task/<slug>`)
  - Travail isolé du main, synchronisation régulière via rebase
  - Merge fast-forward dans main une fois terminé
  - Nettoyage automatique du worktree
- Suivi du statut en temps réel :
  - **Pending** : en attente de lancement
  - **Running** : session Claude active
  - **Waiting** : en attente d'une réponse utilisateur
  - **Completed** : tâche terminée
  - **Archived** : archivée (auto-archivage après 60s, annulable)


### Archivage

- Auto-archivage des tâches complétées après 60 secondes
- Countdown visible avec bouton "Garder" pour annuler et épingler la tâche
- Les tâches épinglées ne sont jamais auto-archivées
- Section Archives globale dans la sidebar (dernières 10 tâches, triées par date)


## Flux de données

```
Utilisateur          ClaudeHub                    Claude CLI
    |                    |                            |
    |-- Ajoute projet -->|                            |
    |-- Crée tâche ----->|                            |
    |                    |-- Décompose (JSON) en utlisant Claude CLI ------->|
    |                    |<-- [{title, prompt}] ------|
    |                    |                            |
    |-- Sélectionne ---->|                            |
    |                    |-- Lance terminal --------->|
    |                    |-- Injecte system prompt -->|
    |                    |<-- Statut (running) -------|
    |                    |                            |
    |   (travail autonome dans worktree)              |
    |                    |                            |
    |                    |<-- Exit code --------------|
    |                    |-- Statut (completed) ----->|
    |                    |-- Auto-archive (60s) ----->|
```
