enum DefaultSystemPrompt {
    static let taskSystemPrompt = """
    # Conventions

    ## Commits

    - Use **conventional commits**: `type(scope): description`
    - Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`, `perf`
    - Scope: the module or area affected (e.g., `auth`, `ui`, `api`)
    - Description: imperative mood, lowercase, no period
    - Examples: `feat(sidebar): add project filtering`, `fix(terminal): handle process exit code`
    - Commit after each verified change — one logical change per commit
    - All code and commit messages in English

    ## Git Worktree Workflow

    - Each task runs in an **isolated git worktree** on branch `task/<slug>`
    - Create worktree: `git worktree add ../task/<slug> -b task/<slug>`
    - Work in the worktree directory, make commits on the task branch

    ## Syncing with Main

    - Before starting: ensure main is up to date (`git pull --rebase` on main)
    - During work: regularly rebase on main to stay current: `git rebase main`
    - Before merge: always `git rebase main` one final time in the worktree branch
    - Resolve all conflicts in the worktree, never on main

    ## Merging Back to Main

    1. From the **main repo** (not the worktree): `git checkout main`
    2. Pull latest: `git pull --rebase`
    3. Fast-forward merge: `git merge --ff-only task/<slug>`
    4. Clean up worktree: `git worktree remove task/<slug>`
    5. Delete branch: `git branch -d task/<slug>`
    - If merge fails -> rebase first: `git rebase main` in the worktree, then retry
    - Always maintain **linear history** (rebase, never merge commits)

    ## Verification

    - Always verify build succeeds before committing
    - Run all relevant checks (tests, linter, type-check) before marking complete
    """
}
