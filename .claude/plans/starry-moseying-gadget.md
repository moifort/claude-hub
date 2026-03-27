# Workflow ClaudeHub

## Vue d'ensemble

ClaudeHub est une app macOS native qui orchestre des sessions Claude Code CLI parallèles sur des projets git. Chaque tâche s'exécute dans un worktree git isolé avec un terminal embarqué (SwiftTerm).

---

## Workflow principal

```
┌─────────────────────────────────────────────────────────────────────┐
│                        1. AJOUT DE PROJET                          │
│                                                                     │
│  Utilisateur ──► Bouton "+" / Drag-drop dossier                    │
│       │                                                             │
│       ▼                                                             │
│  GitService.isGitRepository() ──► Validation repo git              │
│       │                                                             │
│       ▼                                                             │
│  SwiftData ──► Persiste Project(name, path)                        │
│       │                                                             │
│       ▼                                                             │
│  Sidebar ──► Affiche le projet avec ses tâches                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     2. CRÉATION DE TÂCHE                           │
│                                                                     │
│  Utilisateur ──► Cmd+N ──► Sheet modale (prompt libre)             │
│       │                                                             │
│       ▼                                                             │
│  Cmd+Return ──► NewTaskViewModel.decompose()                       │
│       │                                                             │
│       ▼                                                             │
│  CLIService.decomposeTask()                                        │
│       │  Appelle: claude --print -s <systemPrompt> <prompt>        │
│       │  Timeout: 60s                                              │
│       │                                                             │
│       ├──► Succès: JSON [{title, prompt}, ...] ──► N TaskItems     │
│       │         (sous-tâches indépendantes et parallélisables)     │
│       │                                                             │
│       └──► Échec: Fallback ──► 1 seule TaskItem avec prompt brut   │
│                                                                     │
│  Chaque TaskItem créé avec:                                        │
│    - status: .pending                                              │
│    - slug: titre-kebab-case-uuid6                                  │
│    - parentTaskTitle: titre de la tâche mère                       │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    3. LANCEMENT DE TÂCHE                           │
│                                                                     │
│  Utilisateur ──► Clic "Launch" (ou "Launch All Pending")           │
│       │                                                             │
│       ▼                                                             │
│  TaskListViewModel.launchTask()                                    │
│       │                                                             │
│       ├──► GitService.createWorktree(slug)                         │
│       │      git worktree add <path> -b task/<slug>                │
│       │      → Environnement isolé sur branche dédiée              │
│       │                                                             │
│       ├──► CLIService.buildTaskSystemPrompt()                      │
│       │      Instructions git: commit → rebase main → merge → cleanup │
│       │                                                             │
│       ├──► TerminalSessionManager.registerSession()                │
│       │      executable: claude CLI path                           │
│       │      arguments: prompt + system prompt                     │
│       │      workingDirectory: worktree path                       │
│       │                                                             │
│       └──► status → .running                                       │
│                                                                     │
│  UI: Terminal SwiftTerm embarqué affiche la session en temps réel  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   4. EXÉCUTION AUTONOME                            │
│                                                                     │
│  Claude Code CLI ──► Travaille dans le worktree                    │
│       │                                                             │
│       │  L'utilisateur peut:                                       │
│       │    • Observer la sortie terminal en temps réel              │
│       │    • Interagir si Claude pose une question (.waiting)       │
│       │                                                             │
│       │  Claude suit le workflow git injecté:                      │
│       │    1. Travaille sur branche task/<slug>                    │
│       │    2. Commit ses changements                               │
│       │    3. Checkout main + pull                                 │
│       │    4. Rebase task/<slug> sur main                          │
│       │    5. Merge fast-forward dans main                         │
│       │    6. Nettoyage du worktree                                │
│       │                                                             │
│       ▼                                                             │
│  Process exit ──► TerminalRepresentable.processTerminated()        │
│       │                                                             │
│       ▼                                                             │
│  TaskListViewModel.completeTask()                                  │
│       │  status → .completed                                       │
│       │  completedAt = now                                         │
│       └──► Démarre timer auto-archive (60s)                        │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     5. POST-COMPLETION                             │
│                                                                     │
│  Countdown 60s visible dans la UI                                  │
│       │                                                             │
│       ├──► Utilisateur clique "Keep" / "Pin"                       │
│       │      isPinned = true                                       │
│       │      Timer annulé → tâche reste visible indéfiniment       │
│       │                                                             │
│       └──► Pas d'action dans les 60s                               │
│              │                                                      │
│              ▼                                                      │
│         archiveTask()                                              │
│              │  status → .archived                                 │
│              │  archivedAt = now                                   │
│              │                                                      │
│              ├──► GitService.removeWorktree(slug)                  │
│              │      git worktree remove --force                    │
│              │      git branch -D task/<slug>                      │
│              │                                                      │
│              └──► Tâche déplacée dans section "Archives"           │
│                   (max 10 dernières, triées par date)              │
└─────────────────────────────────────────────────────────────────────┘
```

## Cycle de vie d'une tâche

```
PENDING ──► RUNNING ──► COMPLETED ──► ARCHIVED
                │              │
                ▼              ▼
             WAITING      PIN (reste
            (attente       completed
             input)       indéfiniment)
```

| État | Déclencheur | Actions UI disponibles |
|------|-------------|----------------------|
| **Pending** | Création via décomposition | Launch, Supprimer |
| **Running** | Clic Launch | Observer terminal |
| **Waiting** | Claude demande un input | Répondre dans terminal |
| **Completed** | Process exit | Pin/Keep, countdown 60s |
| **Archived** | Auto (60s) ou manuel | Consultation seule |

## Architecture des données

```
Project (SwiftData)
├── name: String
├── path: String (chemin git repo)
├── createdAt: Date
└── tasks: [TaskItem] (cascade delete)
     ├── title, prompt, slug
     ├── status: pending|running|waiting|completed|archived
     ├── isPinned: Bool
     ├── parentTaskTitle: String? (lien vers tâche mère)
     └── createdAt / completedAt / archivedAt
```

## Services clés

| Service | Rôle |
|---------|------|
| **CLIService** | Localise Claude CLI, décompose les tâches (JSON), génère les system prompts |
| **GitService** | Crée/supprime les worktrees git, valide les repos |
| **TerminalSessionManager** | Registre des sessions terminales actives par tâche |

## Interface utilisateur

```
┌──────────────────────────────────────────────────────┐
│  NavigationSplitView                                  │
│  ┌──────────┐  ┌───────────────────────────────────┐ │
│  │ Sidebar  │  │         Detail Pane                │ │
│  │          │  │                                     │ │
│  │ Projects │  │  ┌─ Terminal Header ─────────────┐ │ │
│  │  ├ Proj1 │  │  │ Title | Status | Project      │ │ │
│  │  │ ├ T1  │  │  └─────────────────────────────────┘ │ │
│  │  │ └ T2  │  │  ┌─ SwiftTerm Terminal ───────────┐ │ │
│  │  └ Proj2 │  │  │                                 │ │ │
│  │          │  │  │  $ claude ...                    │ │ │
│  │ Archives │  │  │  > Working on task...            │ │ │
│  │  └ ...   │  │  │                                 │ │ │
│  │          │  │  └─────────────────────────────────┘ │ │
│  └──────────┘  └───────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```
